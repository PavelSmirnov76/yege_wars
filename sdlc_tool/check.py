"""Проверка дерева конвейера: команда `check`.

Ошибки 1–13 и предупреждения — раздел «Проверки `check`» README скрипта,
сравнение с базой — раздел «База: что новое». Сообщение — строка
`ОШИБКА путь[:строка]: текст`; порядок — по пути, строке, тексту.

Как прочитаны места, где спецификация допускает разное:

- Сверх перечня README проверяются прямые следствия закона: у похороненного
  артефакта есть шапка по формату, у живого её нет (9); отметку устаревания
  требования базы нельзя снять или изменить (13).
- Импорт `@~/…` и `@/…` в `CLAUDE.md` не проверяется: он вне репозитория.
- Ссылка, которая сама — строка `supersedes:`, не «к пересмотру» и не
  «новая ссылка на похороненное»: она обязана вести на похороненное.
- «Новые ссылки» новых артефактов проверяются только у живых: черновик,
  похороненный до коммита, ничего нового не утверждает.
- Добавленные строки PRD — строки, которых в базе нет, если у обеих сторон
  убрать пути ссылок (перенос файла, на который ведёт ссылка, строку не
  делает новой). Если строка требования изменилась только отметкой
  устаревания, новые в ней — только ссылки отметки.
- Без базы (`--base none`) старыми считаются все метки и ссылки: на
  похороненное они дают предупреждения, а не ошибки.
- Предупреждение о длине — у каждого файла PRD (у разбитого — у каждой части)
  больше 300 строк и у каждого `AGENTS.md` и `README.md` под `sdlc/` от 300
  строк.
- Цвет в экране — `#RGB`, `#RRGGBB`, `#RRGGBBAA` не после буквы, цифры или
  `&`; размер — число с `px`, `dp`, `pt`, `sp` (можно через один пробел).
- Неверная база (`--base` не коммит) или не git — отказ с кодом 2.
"""

from __future__ import annotations

import collections
import posixpath
import re
import sys
from dataclasses import dataclass
from typing import Dict, List, Optional, Set, TextIO, Tuple

from . import gitbase, model, views

ERROR = 'ОШИБКА'
WARNING = 'ПРЕДУПРЕЖДЕНИЕ'

PRD_MAX_LINES = 300       # PRD длиннее — предупреждение
RULES_MAX_LINES = 300     # AGENTS.md и README.md такой длины и длиннее
REBUILD_HINT = 'пересоберите: python3 -m sdlc_tool views'

_COLOR_RE = re.compile(
    r'(?<![&\w])#(?:[0-9A-Fa-f]{8}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})(?![0-9A-Za-z_])'
)
_SIZE_RE = re.compile(r'(?<![\w.,])[0-9]+(?:[.,][0-9]+)?[ \u00a0]?(?:px|dp|pt|sp)(?!\w)')
_LABEL_NOUNS = {'UC': 'UC', 'TOKEN': 'токен', 'COMP': 'компонент'}


@dataclass(frozen=True)
class Message:
    """Сообщение проверки."""

    severity: str
    path: str
    line: int
    text: str

    @property
    def sort_key(self) -> Tuple[str, int, str, str]:
        return (self.path, self.line, self.text, self.severity)

    def format(self) -> str:
        where = f'{self.path}:{self.line}' if self.line else self.path
        return f'{self.severity} {where}: {self.text}'


class _Messages:
    """Сборщик сообщений без повторов."""

    def __init__(self) -> None:
        self._items: Set[Message] = set()

    def error(self, path: str, line: int, text: str) -> None:
        self._items.add(Message(ERROR, path, line, text))

    def warning(self, path: str, line: int, text: str) -> None:
        self._items.add(Message(WARNING, path, line, text))

    def errors(self, issues: List[model.Issue]) -> None:
        for issue in issues:
            self.error(issue.path, issue.line, issue.text)

    def sorted(self) -> List[Message]:
        return sorted(self._items, key=lambda item: item.sort_key)


@dataclass
class BaseContext:
    """База для раздела «База: что новое»."""

    ref: str
    repo: model.Repo
    added_code: Dict[str, Set[int]]
    base_ids: Set[str]

    def is_new(self, artifact: model.Artifact) -> bool:
        return artifact.id not in self.base_ids


def _plural(number: int, one: str, few: str, many: str) -> str:
    tail = number % 100
    if 11 <= tail <= 14:
        return many
    if number % 10 == 1:
        return one
    if 2 <= number % 10 <= 4:
        return few
    return many


def summary_line(messages: List[Message]) -> str:
    """Строка итога: `Итог: 1 ошибка, 2 предупреждения`."""
    errors = sum(1 for item in messages if item.severity == ERROR)
    warnings = len(messages) - errors
    return (f'Итог: {errors} {_plural(errors, "ошибка", "ошибки", "ошибок")}, '
            f'{warnings} {_plural(warnings, "предупреждение", "предупреждения", "предупреждений")}')


def _describe_stale(resolved: model.Resolved) -> str:
    if resolved.kind == model.REQUIREMENT_LINK:
        return f'устаревшее требование {resolved.target_id}'
    return f'похороненный {resolved.target_id}'


# --------------------------------------------------------------------------
# 1–3: структура, имена, id


def _check_structure(repo: model.Repo, out: _Messages) -> None:
    for directory in repo.structure_dirs:
        missing = [name for name in model.CONVENTION_FILES
                   if f'{directory}/{name}' not in repo.file_set]
        if missing:
            out.error(f'{directory}/', 0, f'в папке структуры нет {", ".join(missing)}')
    for directory in repo.content_dirs:
        for name in model.CONVENTION_FILES:
            path = f'{directory}/{name}'
            if path in repo.file_set:
                out.error(path, 0, f'в папке содержимого не должно быть {name}')
    out.errors(repo.name_issues)


def _check_duplicate_ids(repo: model.Repo, out: _Messages) -> None:
    for artifact_id in sorted(repo.ids()):
        files = repo.by_id(artifact_id)
        if len(files) < 2:
            continue
        for item in files:
            others = ', '.join(other.path for other in files if other is not item)
            out.error(item.path, 0, f'id {artifact_id} у нескольких файлов: ещё {others}')


def _check_name_refs(repo: model.Repo, out: _Messages) -> None:
    ids = repo.ids()
    modules = {item.module for item in repo.of_type('MOD')}
    for item in repo.artifacts:
        if item.type in model.MODULE_TYPES and item.module not in modules:
            out.error(item.path, 0, f'-IN-{item.module} не ведёт на модуль: нет '
                                    f'файла MOD-*-{item.module}.md')
        for kind, number in item.uc_refs:
            if f'{kind}-{number}' not in ids:
                out.error(item.path, 0, f'в имени UC — несуществующий {kind}-{number}')
        if item.type in model.OWNED_TYPES and item.task_id not in ids:
            out.error(item.path, 0, f'нет задания {item.task_id}')
        if item.type == 'ACC' and item.result_id not in ids:
            out.error(item.path, 0, f'нет сдачи {item.result_id} с тем же номером')


# --------------------------------------------------------------------------
# 4–5: требования и пути UC


def _check_requirements(repo: model.Repo, out: _Messages) -> None:
    out.errors(repo.requirement_issues)


def _check_uc_paths(repo: model.Repo, out: _Messages) -> None:
    for item in repo.of_type('UC'):
        out.errors(repo.uc_path_issues(item))


# --------------------------------------------------------------------------
# 6: ссылки; предупреждение «к пересмотру»


def _check_links(repo: model.Repo, base: Optional[BaseContext], out: _Messages) -> None:
    for path in repo.link_checked_files():
        for link in repo.doc(path).links:
            resolved = repo.resolve(link)
            if resolved.kind == model.EXTERNAL:
                continue
            if resolved.kind == model.MISSING:
                out.error(path, link.line, f'цель ссылки не существует: {link.target}')
                continue
            text = link.text.strip()
            if resolved.kind in (model.ARTIFACT_LINK, model.REQUIREMENT_LINK):
                if text != resolved.target_id:
                    out.error(path, link.line,
                              f'текст ссылки {text}, а ведёт она на {resolved.target_id}')
                if not resolved.anchor_ok:
                    out.error(path, link.line,
                              f'нет якоря #{resolved.fragment} в {resolved.path}')
            elif model.looks_like_id(text):
                out.error(path, link.line,
                          f'текст ссылки {text} похож на id, а ведёт она не на этот '
                          f'артефакт: {link.target}')
    for item in repo.artifacts:
        if item.buried or not model.is_link_checked(item.path):
            continue
        if base is not None and base.is_new(item):
            continue  # у нового артефакта это ошибка базы, а не предупреждение
        for link, resolved in repo.stale_links(item):
            out.warning(item.path, link.line,
                        f'ссылается на {_describe_stale(resolved)} — к пересмотру')


# --------------------------------------------------------------------------
# 7: метки в коде; предупреждение о старых метках


def _check_labels(repo: model.Repo, base: Optional[BaseContext], out: _Messages) -> None:
    for label in repo.labels():
        artifact = repo.get(label.artifact_id)
        if artifact is None or artifact.type != label.type:
            out.error(label.path, label.line,
                      f'метка {label.id} ведёт на несуществующий {_LABEL_NOUNS[label.type]}')
            continue
        if label.is_path and repo.label_target(label) is None:
            out.error(label.path, label.line,
                      f'метка {label.id} ведёт на несуществующий путь UC: '
                      f'в {artifact.id} его нет')
            continue
        if not artifact.buried:
            continue
        if base is not None and label.line in base.added_code.get(label.path, ()):
            continue  # новая метка — ошибка базы
        out.warning(label.path, label.line,
                    f'метка {label.id} ведёт на похороненный {artifact.id} — к пересмотру')


# --------------------------------------------------------------------------
# 8–9: вердикты приёмок, supersedes и шапки


def _check_acceptance(repo: model.Repo, out: _Messages) -> None:
    for item in repo.of_type('ACC'):
        out.errors(repo.verdict_issues(item))


def _header_target(repo: model.Repo, header: model.TombHeader) -> Optional[str]:
    """Id из «Заменён»: артефакт, куда ведёт ссылка, иначе её текст."""
    if header.link is None:
        return None
    resolved = repo.resolve(header.link)
    if resolved.kind == model.ARTIFACT_LINK and resolved.artifact is not None:
        return resolved.artifact.id
    return header.replaced_by


def _check_supersedes(repo: model.Repo, out: _Messages) -> None:
    for item in repo.artifacts:
        out.errors(repo.supersedes_issues(item))
        for link in repo.supersedes(item):
            resolved = repo.resolve(link)
            if resolved.kind != model.ARTIFACT_LINK or resolved.artifact is None:
                out.error(item.path, link.line,
                          f'supersedes ведёт на несуществующий артефакт: {link.target}')
                continue
            old = resolved.artifact
            if old.live:
                out.error(item.path, link.line,
                          f'supersedes ведёт на живой {old.id}: заменённый хоронят — '
                          f'python3 -m sdlc_tool entomb {old.id} --by {item.id}')
                continue
            header = repo.tomb_header(old)
            if header is None or header.error:
                continue  # о шапке скажет проверка похороненного
            replaced = _header_target(repo, header)
            if replaced != item.id:
                out.error(item.path, link.line,
                          f'supersedes: {old.id}, а в шапке {old.id} '
                          f'«Заменён: {replaced or "ничем"}»')
    for item in repo.artifacts:
        header = repo.tomb_header(item)
        if item.live:
            if header is not None:
                out.error(item.path, 1, 'у живого артефакта шапка похороненного: '
                                        'хоронят переносом в obsolete/ — '
                                        'python3 -m sdlc_tool entomb')
            continue
        if header is None:
            out.error(item.path, 1, 'у похороненного нет шапки «Похоронен», «Почему», '
                                    '«Заменён» — хоронят командой python3 -m sdlc_tool entomb')
            continue
        if header.error:
            out.error(item.path, 1, f'шапка похороненного не по формату: {header.error}')
            continue
        if header.link is None:
            continue  # «Заменён: ничем»
        resolved = repo.resolve(header.link)
        if resolved.kind == model.MISSING:
            continue  # о битой ссылке скажет проверка ссылок
        if resolved.kind != model.ARTIFACT_LINK or resolved.artifact is None:
            out.error(item.path, 3, f'«Заменён» ведёт не на артефакт: {header.link.target}')
            continue
        new = resolved.artifact
        replaced_ids = set()
        for link in repo.supersedes(new):
            target = repo.resolve(link)
            if target.kind == model.ARTIFACT_LINK and target.artifact is not None:
                replaced_ids.add(target.artifact.id)
        if item.id not in replaced_ids:
            out.error(item.path, 3, f'«Заменён: {new.id}», а у {new.id} нет строки '
                                    f'supersedes: [{item.id}](…)')


# --------------------------------------------------------------------------
# 10–12: импорты, значения в экранах, производные файлы


def _check_imports(repo: model.Repo, out: _Messages) -> None:
    for path in repo.md_files:
        if posixpath.basename(path) != 'CLAUDE.md':
            continue
        doc = repo.doc(path)
        for index, masked_line in enumerate(doc.masked_lines):
            stripped = masked_line.strip()
            if not stripped.startswith('@'):
                continue
            target = stripped[1:].split()[0] if stripped[1:].strip() else ''
            if not target:
                out.error(path, index + 1, 'пустой импорт @')
                continue
            if target.startswith(('~', '/')):
                continue
            resolved = posixpath.normpath(posixpath.join(posixpath.dirname(path), target))
            if (resolved == '..' or resolved.startswith('../')
                    or not repo.exists(resolved) or repo.is_dir(resolved)):
                out.error(path, index + 1, f'импорт @{target} не разрешается')


def _check_fig_values(repo: model.Repo, out: _Messages) -> None:
    for item in repo.of_type('FIG'):
        doc = repo.doc(item.path)
        chars = list(doc.masked)
        for link in doc.links + doc.images:
            for index in range(link.text_end + 1, link.end):
                if chars[index] != '\n':
                    chars[index] = ' '
        text = ''.join(chars)
        for pattern in (_COLOR_RE, _SIZE_RE):
            for match in pattern.finditer(text):
                out.error(item.path, doc.line_of(match.start()),
                          f'значение {match.group(0)} вместо токена — возьмите токен '
                          'из 3-design/design-system/')


def _first_line_difference(old: str, new: str) -> int:
    return model.first_difference(old.split('\n'), new.split('\n')) + 1


def _check_derived(repo: model.Repo, out: _Messages) -> None:
    try:
        expected = views.render_all(repo)
    except NotImplementedError:
        out.warning('sdlc_tool/views.py', 0,
                    'проверка производных файлов (12) пропущена: views.render_all '
                    'ещё не реализован')
        return
    for path in sorted(expected):
        want = expected[path]
        have = repo.text(path) if path in repo.file_set else None
        if want is None:
            if have is not None:
                out.error(path, 0, f'лишний производный файл — {REBUILD_HINT}')
        elif have is None:
            out.error(path, 0, f'производного файла нет — {REBUILD_HINT}')
        elif have != want:
            out.error(path, _first_line_difference(want, have),
                      f'производный файл устарел — {REBUILD_HINT}')
    for path in repo.files:
        if posixpath.basename(path) == model.INDEX_NAME and path not in expected:
            out.error(path, 0, f'лишний производный файл — {REBUILD_HINT}')


# --------------------------------------------------------------------------
# Предупреждения о длине


def _check_sizes(repo: model.Repo, out: _Messages) -> None:
    for path in repo.prd_files:
        count = model.count_lines(repo.text(path))
        if count > PRD_MAX_LINES:
            out.warning(path, 0, f'{count} {_plural(count, "строка", "строки", "строк")} '
                                 '— пора разбивать')
    for path in repo.md_files:
        if posixpath.basename(path) not in ('AGENTS.md', 'README.md'):
            continue
        count = model.count_lines(repo.text(path))
        if count >= RULES_MAX_LINES:
            out.warning(path, 0, f'{count} {_plural(count, "строка", "строки", "строк")} '
                                 '— пора сокращать')


# --------------------------------------------------------------------------
# 13: база


def _compare_frozen(
    old_text: str, new_path: str, new_text: str, what: str, out: _Messages
) -> None:
    old_form = model.frozen_form(old_text)
    new_form = model.frozen_form(new_text)
    if old_form == new_form:
        return
    header = model.parse_tomb_header(new_text, new_path)
    shift = header.size if header else 0
    line = shift + model.first_difference(old_form.split('\n'), new_form.split('\n')) + 1
    out.error(new_path, line, f'{what}: замороженное не правят — правка это новый '
                              'артефакт с supersedes')


def _check_frozen(repo: model.Repo, base: BaseContext, out: _Messages) -> None:
    old_repo = base.repo
    for old in old_repo.artifacts:
        candidates = repo.by_id(old.id)
        if not candidates:
            out.error(old.path, 0, f'артефакт {old.id} удалён: удалять нельзя, только '
                                   'хоронить — python3 -m sdlc_tool entomb')
            continue
        current = next((item for item in candidates if item.path == old.path), None)
        if current is None and old.live and not old.misplaced:
            current = next((item for item in candidates
                            if item.path == old.obsolete_path), None)
        if current is None:
            for item in candidates:
                out.error(item.path, 0, f'артефакт {old.id} перенесён из {old.path}: '
                                        'переносить можно только из живой папки в её '
                                        'obsolete/')
            continue
        _compare_frozen(old_repo.text(old.path), current.path, repo.text(current.path),
                        f'артефакт {old.id} изменён', out)
    for path in old_repo.snapshots:
        if path not in repo.file_set:
            out.error(path, 0, 'снимок PRD удалён: снимки заморожены')
            continue
        _compare_frozen(old_repo.text(path), path, repo.text(path), 'снимок PRD изменён', out)


def _check_frozen_requirements(repo: model.Repo, base: BaseContext, out: _Messages) -> None:
    for old in base.repo.requirements:
        current = repo.requirement(old.number)
        if current is None:
            where = repo.prd_files[0] if repo.prd_files else old.path
            out.error(where, 0, f'требование {old.id} пропало из PRD: требования не '
                                'удаляют, а отмечают устаревшими')
            continue
        if model.strip_link_paths(old.body) != model.strip_link_paths(current.body):
            out.error(current.path, current.line,
                      f'текст требования {old.id} изменён: изменить смысл — значит '
                      'выдать новый R')
        if old.mark is not None and (
                current.mark is None or current.mark.date != old.mark.date
                or current.mark.replaced_by != old.mark.replaced_by):
            out.error(current.path, current.line,
                      f'отметку устаревания {old.id} сняли или изменили')


def _counter_id(kind: str, task: int, seq: int) -> str:
    if kind in model.OWNED_TYPES:
        return f'{kind}-TASK-{task}-{model.format_nn(seq)}'
    return f'{kind}-{seq}'


def _check_id_order(repo: model.Repo, base: BaseContext, out: _Messages) -> None:
    top: Dict[Tuple[str, int], int] = {}
    for old in base.repo.artifacts:
        top[old.counter] = max(top.get(old.counter, 0), old.seq)
    for item in repo.artifacts:
        if not base.is_new(item):
            continue
        highest = top.get(item.counter, 0)
        if item.seq <= highest:
            kind, task = item.counter
            out.error(item.path, 0,
                      f'новый id {item.id} не больше наибольшего в базе '
                      f'{_counter_id(kind, task, highest)}: номер выдаёт '
                      'python3 -m sdlc_tool next')
    old_numbers = {requirement.number for requirement in base.repo.requirements}
    highest_r = max(old_numbers, default=0)
    for requirement in repo.requirements:
        if requirement.number not in old_numbers and requirement.number <= highest_r:
            out.error(requirement.path, requirement.line,
                      f'новое требование {requirement.id} не больше наибольшего в базе '
                      f'R{highest_r}: номер выдаёт python3 -m sdlc_tool next R')


def _prd_added_links(repo: model.Repo, base: BaseContext) -> List[Tuple[model.Link, model.Resolved]]:
    """Ссылки на артефакты и требования в добавленных строках PRD."""
    old_lines: collections.Counter = collections.Counter()
    old_unmarked: collections.Counter = collections.Counter()
    for path in base.repo.prd_files:
        text = base.repo.text(path)
        for line, stripped in zip(text.split('\n'), model.strip_link_paths(text).split('\n')):
            old_lines[stripped] += 1
            old_unmarked[_unmarked(line, stripped)] += 1
    marks: Dict[Tuple[str, int], model.ObsoleteMark] = {}
    for requirement in repo.requirements:
        if requirement.mark is not None:
            marks[(requirement.path, requirement.line)] = requirement.mark
    result = []
    for path in repo.prd_files:
        doc = repo.doc(path)
        stripped_lines = model.strip_link_paths(doc.text).split('\n')
        for index, (line, stripped) in enumerate(zip(doc.lines, stripped_lines)):
            if old_lines[stripped] > 0:
                old_lines[stripped] -= 1
                continue
            line_no = index + 1
            links = [link for link in doc.links if link.line == line_no]
            mark = marks.get((path, line_no))
            if mark is not None and old_unmarked[_unmarked(line, stripped)] > 0:
                # Строка изменилась только отметкой: новые — ссылки отметки.
                start = doc.line_start(line_no)
                links = [link for link in links
                         if mark.start <= link.start - start < mark.end]
            for link in links:
                resolved = repo.resolve(link)
                if resolved.kind in (model.ARTIFACT_LINK, model.REQUIREMENT_LINK):
                    result.append((link, resolved))
    return result


def _unmarked(line: str, stripped: str) -> str:
    without = model.strip_obsolete_mark(line)
    return stripped if without == line else model.strip_link_paths(without)


def _check_new_links(repo: model.Repo, base: BaseContext, out: _Messages) -> None:
    for item in repo.artifacts:
        if not base.is_new(item) or item.buried or not model.is_link_checked(item.path):
            continue
        for link, resolved in repo.stale_links(item):
            out.error(item.path, link.line,
                      f'новая ссылка ведёт на {_describe_stale(resolved)}: новое '
                      'ссылается только на живое')
    for link, resolved in _prd_added_links(repo, base):
        if repo.is_stale(resolved):
            out.error(link.path, link.line,
                      f'новая ссылка ведёт на {_describe_stale(resolved)}: новое '
                      'ссылается только на живое')


def _check_new_labels(repo: model.Repo, base: BaseContext, out: _Messages) -> None:
    for label in repo.labels():
        if label.line not in base.added_code.get(label.path, ()):
            continue
        artifact = repo.get(label.artifact_id)
        if artifact is not None and artifact.type == label.type and artifact.buried:
            out.error(label.path, label.line,
                      f'новая метка {label.id} ведёт на похороненный {artifact.id}')


def _check_base(repo: model.Repo, base: BaseContext, out: _Messages) -> None:
    _check_frozen(repo, base, out)
    _check_frozen_requirements(repo, base, out)
    _check_id_order(repo, base, out)
    _check_new_links(repo, base, out)
    _check_new_labels(repo, base, out)


# --------------------------------------------------------------------------
# Вход


def load_base(repo: model.Repo, ref: str) -> BaseContext:
    """База `ref` для рабочего дерева `repo`; отказ с кодом 2, если её нет."""
    try:
        base_repo = model.load_base(repo.root, ref)
        added = gitbase.added_lines(repo.root, base_repo.source.commit)
    except gitbase.GitError as error:
        raise model.Refusal(f'база {ref} недоступна: {error}', code=2) from error
    return BaseContext(ref=ref, repo=base_repo, added_code=added,
                       base_ids=base_repo.ids())


def check(repo: model.Repo, base: Optional[str] = 'HEAD', derived: bool = True) -> List[Message]:
    """Все проверки дерева `repo`; `base` — коммит базы или None (без базы).

    `derived=False` пропускает проверку 12 (нужно тестам, которые не собирают
    производные файлы).
    """
    out = _Messages()
    if not repo.has_sdlc:
        out.error('sdlc/', 0, 'нет папки sdlc/')
        return out.sorted()
    context = load_base(repo, base) if base is not None else None
    _check_structure(repo, out)
    _check_duplicate_ids(repo, out)
    _check_name_refs(repo, out)
    _check_requirements(repo, out)
    _check_uc_paths(repo, out)
    _check_links(repo, context, out)
    _check_labels(repo, context, out)
    _check_acceptance(repo, out)
    _check_supersedes(repo, out)
    _check_imports(repo, out)
    _check_fig_values(repo, out)
    if derived:
        _check_derived(repo, out)
    _check_sizes(repo, out)
    if context is not None:
        _check_base(repo, context, out)
    return out.sorted()


def run(root: str, base: Optional[str] = 'HEAD', stream: Optional[TextIO] = None) -> int:
    """Команда `check`: печатает сообщения и итог; код 0 — ошибок нет, 1 — есть."""
    stream = stream or sys.stdout
    messages = check(model.load_repo(root), base)
    for message in messages:
        print(message.format(), file=stream)
    print(summary_line(messages), file=stream)
    return 1 if any(item.severity == ERROR for item in messages) else 0
