"""Похороны артефактов, устаревание требований и снимки PRD: команды
`entomb` и `snapshot-prd`, переписывание путей ссылок.

Форматы шапок — README скрипта, «`supersedes` и шапки», отметки устаревания —
`sdlc/0-vibes/prd/AGENTS.md`; пишут их `model.format_tomb_header`,
`model.format_snapshot_header`, `model.format_obsolete_mark`, читают
`model.parse_*`. Цель ссылки переписывается в диапазоне
`Link.target_start…target_end`, новая цель — `model.rel_link`. Производные
файлы здесь не пересобираются: после успешной команды CLI зовёт
`views.write_all` по заново прочитанному дереву (переданный `repo` после
записи устарел). При отказе ни один файл не меняется.

Как прочитаны места, где спецификация допускает разное:

- `entomb` переписывает ссылки на хоронимый файл во всех `.md` под `sdlc/`,
  и там, где `check` ссылки не проверяет (заметки `raw/`, прогоны): путь —
  навигация, его ведёт скрипт. Производные `INDEX.md` и `DASHBOARD.md` не
  трогает — их пересобирает `views`; файлы вне `sdlc/` — тоже.
- Новая цель — путь от файла со ссылкой, даже если старая была от корня
  (`/sdlc/…`). Якорь (как записан, с `%XX`), `<…>`, заголовок ссылки и `/` на
  конце пути остаются как были.
- В перенесённом файле перебазируется каждая относительная цель ссылок и
  картинок, и битая тоже: она ведёт туда же, куда вела. Якорь без пути и цель
  от корня не меняются; ссылка на сам файл ведёт на его новое место.
- Причина обязательна у артефакта (шапка «Почему») и не нужна требованию: у
  отметки устаревания поля причины нет, `why` не используется.
- Артефакт заменяют живым артефактом, требование — живым требованием.
  Заменяющий артефакт уже пишет строку `supersedes: [старый id](…)` (закон,
  «Устаревание»), иначе — отказ. Отказ и тогда, когда `supersedes` на
  хоронимый пишет кто-то кроме `--by` (и при `--by none`): шапка и
  `supersedes` разошлись бы (ошибка 9 `check`).
- Отказ, если файл, который пришлось бы переписать, не в UTF-8: запись
  испортила бы его байты.
- Снимок берёт `PRD.md` рабочего дерева как есть. Ссылки на требования
  (`[R12](#r12)`, `[R12](PRD.md#r12)`) ведут в текущий PRD — `../PRD.md#r12`:
  ссылка на требование — только в текущий PRD. Прочие якоря без пути не
  меняются и ведут в сам снимок; остальные цели перебазируются.
- Вход снимка — существующий файл или папка под `sdlc/`. Текст ссылки «Вход»
  — путь от `sdlc/` (у папки — с `/` на конце), а если вход — артефакт, его
  id. Снимок разбитого PRD не снимается: разбиение скрипт ещё не делает.
  Отметку устаревания в разбитом PRD `entomb` ставит: замена из другой части
  — с путём перед `#r{k}`.
"""

from __future__ import annotations

import os
import posixpath
import re
from typing import Dict, List, Optional, Sequence, Tuple

from . import model

# Правка текста: начало и конец заменяемого куска, новый кусок.
_Edit = Tuple[int, int, str]


# --------------------------------------------------------------------------
# entomb


def entomb(
    repo: model.Repo,
    target_id: str,
    by: Optional[str],
    why: Optional[str],
    date: str,
) -> List[str]:
    """Хоронит артефакт или отмечает устаревшим требование.

    `target_id` — id артефакта (`UC-5`, `RESULT-TASK-7-02`) или требования
    (`R7`). `by` — id замены (`UC-9`, `R12`) или None — «ничем» (в CLI
    `--by none`). `why` — причина (None — `--why` не передан). `date` —
    `ГГГГ-ММ-ДД`, уже проверенная CLI.

    Артефакт: переносит файл в `obsolete/` своей папки, пишет сверху шапку,
    переписывает пути ссылок всего дерева на старое место и пути ссылок самого
    файла. Требование: ставит в PRD отметку устаревания сразу после
    `**R{n}.**`.

    Возвращает отсортированные пути (от корня) созданных, изменённых и
    удалённых файлов. Отказ — `model.Refusal` (код 1). Производные файлы не
    пересобирает: после успеха CLI зовёт `views.write_all`.
    """
    _require_date(date)
    ref = model.parse_id(target_id)
    if ref is None:
        raise model.Refusal(f'{target_id} — не id артефакта или требования: нужен '
                            'id вида UC-5, RESULT-TASK-7-02 или R7')
    if ref.part is not None:
        raise model.Refusal(f'{target_id} — путь или исход внутри UC-{ref.number}: '
                            'отдельно их не хоронят, хоронят UC целиком')
    if ref.type == model.REQUIREMENT:
        return _obsolete_requirement(repo, ref.number, by, date)
    return _bury(repo, target_id, by, why, date)


def _bury(
    repo: model.Repo, target_id: str, by: Optional[str], why: Optional[str], date: str
) -> List[str]:
    reason = _one_line(why)
    if not reason:
        raise model.Refusal('нужна причина: --why ТЕКСТ — её пишет шапка «Почему»')
    artifact = _single(repo, target_id, 'артефакта')
    if artifact.buried:
        raise model.Refusal(f'{target_id} уже похоронен: {artifact.path}')
    if artifact.misplaced:
        raise model.Refusal(f'{target_id} лежит не в своей папке: {artifact.path} — '
                            'сначала исправьте место')
    if repo.tomb_header(artifact) is not None:
        raise model.Refusal(f'у живого {target_id} уже есть шапка похороненного: '
                            f'{artifact.path}')
    replacement = _replacement(repo, artifact, by)
    old_path, new_path = artifact.path, artifact.obsolete_path
    _require_free(repo, new_path)

    texts: Dict[str, str] = {}
    for path in repo.md_files:
        if path == old_path or _is_derived(path):
            continue
        doc = repo.doc(path)
        edits = [(link.target_start, link.target_end, _retarget(link, path, new_path))
                 for link in _targets(doc) if _leads_to(repo, link, old_path)]
        if edits:
            texts[path] = _apply(doc.text, edits)
    doc = repo.doc(old_path)
    replaced = None
    if replacement is not None:
        replaced = (replacement.id, model.rel_link(new_path, replacement.path))
    header = model.format_tomb_header(date, reason, replaced)
    texts[new_path] = header + _apply(doc.text, _rebase_edits(repo, doc, new_path, moved=True))

    rewritten = sorted((set(texts) - {new_path}) | {old_path})
    for path in rewritten:
        _require_utf8(repo, path)
    for path in sorted(texts):
        _write(repo, path, texts[path])
    os.remove(_abs(repo, old_path))
    return sorted(rewritten + [new_path])


def _single(repo: model.Repo, artifact_id: str, what: str) -> model.Artifact:
    """Единственный файл с этим id; нет или несколько — отказ."""
    found = repo.by_id(artifact_id)
    if not found:
        raise model.Refusal(f'{what} {artifact_id} нет')
    if len(found) > 1:
        paths = ', '.join(item.path for item in found)
        raise model.Refusal(f'id {artifact_id} у нескольких файлов: {paths} — '
                            'сначала исправьте')
    return found[0]


def _replacement(
    repo: model.Repo, artifact: model.Artifact, by: Optional[str]
) -> Optional[model.Artifact]:
    """Артефакт для «Заменён» или None — «ничем»; несогласие с `supersedes`
    дерева — отказ."""
    superseding = [item for item in repo.artifacts
                   if item.path != artifact.path and _supersedes(repo, item, artifact)]
    if by is None:
        if superseding:
            raise model.Refusal(f'supersedes: [{artifact.id}](…) пишет '
                                f'{_ids(superseding)} — хороните с --by '
                                f'{superseding[0].id}')
        return None
    ref = model.parse_id(by)
    if ref is None or ref.part is not None or ref.type == model.REQUIREMENT:
        raise model.Refusal(f'--by {by}: артефакт заменяют артефактом — нужен его id '
                            'или none')
    if by == artifact.id:
        raise model.Refusal(f'{by} не заменяют им самим')
    replacement = _single(repo, by, 'замены')
    if replacement.buried:
        raise model.Refusal(f'замена {by} похоронена: {replacement.path} — заменяют '
                            'только живым')
    if all(item.path != replacement.path for item in superseding):
        line = f'supersedes: [{artifact.id}]({model.rel_link(replacement.path, artifact.path)})'
        raise model.Refusal(f'у {by} нет строки {line} — её пишет заменяющий артефакт '
                            '(закон, «Устаревание»)')
    others = [item for item in superseding if item.path != replacement.path]
    if others:
        raise model.Refusal(f'supersedes: [{artifact.id}](…) пишет не только {by}, но и '
                            f'{_ids(others)}, а в шапке «Заменён» — один id')
    return replacement


def _supersedes(repo: model.Repo, item: model.Artifact, old: model.Artifact) -> bool:
    """У `item` есть строка `supersedes` со ссылкой на файл `old`."""
    return any(_leads_to(repo, link, old.path) for link in repo.supersedes(item))


def _ids(items: Sequence[model.Artifact]) -> str:
    return ', '.join(item.id for item in items)


def _obsolete_requirement(
    repo: model.Repo, number: int, by: Optional[str], date: str
) -> List[str]:
    if not repo.prd_files:
        raise model.Refusal(f'PRD нет: {model.PRD_PATH}')
    requirement = repo.requirement(number)
    if requirement is None:
        raise model.Refusal(f'требования R{number} нет в PRD')
    copies = [found for path in repo.prd_files
              for found in model.parse_requirements(repo.text(path), path)[0]
              if found.number == number]
    if len(copies) > 1:
        places = ', '.join(f'{found.path}:{found.line}' for found in copies)
        raise model.Refusal(f'номер R{number} повторён: {places} — сначала исправьте')
    problems = [issue.text for issue in repo.requirement_issues
                if (issue.path, issue.line) == (requirement.path, requirement.line)]
    if problems:
        raise model.Refusal(f'строка R{number} с ошибкой: {problems[0]}')
    if requirement.mark is not None:
        raise model.Refusal(f'R{number} уже устарело {requirement.mark.date}: '
                            f'{requirement.path}:{requirement.line}')
    replaced_by: Optional[int] = None
    target_path = ''
    if by is not None:
        ref = model.parse_id(by)
        if ref is None or ref.type != model.REQUIREMENT:
            raise model.Refusal(f'--by {by}: требование заменяют требованием — нужен '
                                'R{k} или none')
        if ref.number == number:
            raise model.Refusal(f'{by} не заменяют им самим')
        replacement = repo.requirement(ref.number)
        if replacement is None:
            raise model.Refusal(f'заменяющего требования {by} нет в PRD')
        if replacement.obsolete:
            raise model.Refusal(f'заменяющее требование {by} устарело — заменяют только '
                                'живым')
        replaced_by = ref.number
        if replacement.path != requirement.path:
            target_path = model.rel_link(requirement.path, replacement.path)
    doc = repo.doc(requirement.path)
    offset = doc.line_start(requirement.line) + model.mark_offset(requirement)
    mark = model.format_obsolete_mark(date, replaced_by, target_path)
    _require_utf8(repo, requirement.path)
    _write(repo, requirement.path, doc.text[:offset] + mark + doc.text[offset:])
    return [requirement.path]


# --------------------------------------------------------------------------
# snapshot-prd


def snapshot_prd(repo: model.Repo, why: str, input_path: str, date: str) -> str:
    """Снимает текущий PRD в `0-vibes/prd/history/PRD-{date}.md` (второй за
    день — `…-02.md` и далее) с шапкой «Сменён / Почему / Вход» и
    перебазированными путями ссылок.

    `input_path` — вход как его передал пользователь: от корня репозитория
    (`sdlc/0-vibes/raw/2026-11-02/`) или от `sdlc/` (`0-vibes/raw/2026-11-02/`);
    абсолютный путь внутри репозитория тоже годится.
    Возвращает путь снимка от корня. Отказ — `model.Refusal` (код 1).
    Производные файлы не пересобирает: после успеха CLI зовёт
    `views.write_all`.
    """
    _require_date(date)
    reason = _one_line(why)
    if not reason:
        raise model.Refusal('нужна причина: --why ТЕКСТ — её пишет шапка «Почему»')
    if not repo.prd_files:
        raise model.Refusal(f'PRD нет: {model.PRD_PATH}')
    if repo.prd_files != [model.PRD_PATH]:
        raise model.Refusal(f'PRD разбит на части в {model.PRD_SPLIT_DIR}/ — снимок '
                            'разбитого PRD скрипт ещё не делает')
    source = _input_path(repo, input_path)
    is_dir = source in repo.dirs
    artifact = repo.artifact_at(source)
    if artifact is not None:
        text = artifact.id
    else:
        text = model.sdlc_rel(source) + ('/' if is_dir else '')
    path = _snapshot_path(repo, date)
    _require_free(repo, path)
    header = model.format_snapshot_header(
        date, reason, text, model.rel_link(path, source, is_dir=is_dir))
    doc = repo.doc(model.PRD_PATH)
    _write(repo, path, header + _apply(doc.text, _rebase_edits(repo, doc, path, moved=False)))
    return path


def _input_path(repo: model.Repo, given: str) -> str:
    """Путь входа от корня: существующий файл или папка под `sdlc/`."""
    value = given.strip()
    if os.path.isabs(value):
        path = posixpath.normpath(os.path.relpath(value, repo.root).replace(os.sep, '/'))
    else:
        path = posixpath.normpath(value) if value else ''
        if path != model.SDLC and not path.startswith(model.SDLC + '/'):
            path = posixpath.normpath(posixpath.join(model.SDLC, path))
    if not path.startswith(model.SDLC + '/'):
        raise model.Refusal(f'вход «{given}» — не файл и не папка под sdlc/: нужна папка '
                            '0-vibes/raw/<дата>/ или сигнал 9-observation/')
    if path not in repo.file_set and path not in repo.dirs:
        raise model.Refusal(f'входа {path} нет')
    return path


def _snapshot_path(repo: model.Repo, date: str) -> str:
    """Свободное имя снимка за дату: первый — без номера, дальше — `-02`, …"""
    pattern = re.compile(rf'PRD-{re.escape(date)}(?:-([0-9]+))?\.md')
    taken = [0]
    for path in repo.snapshots:
        match = pattern.fullmatch(posixpath.basename(path))
        if match:
            taken.append(int(match.group(1)) if match.group(1) else 1)
    number = max(taken) + 1
    suffix = f'-{model.format_nn(number)}' if number > 1 else ''
    return f'{model.HISTORY_DIR}/PRD-{date}{suffix}.md'


# --------------------------------------------------------------------------
# Ссылки


def _targets(doc: model.Document) -> List[model.Link]:
    """Ссылки и картинки вне кода: у тех и других цель — путь."""
    return doc.links + doc.images


def _leads_to(repo: model.Repo, link: model.Link, path: str) -> bool:
    """Ссылка разрешается в файл артефакта `path`."""
    if link.is_external:
        return False
    resolved = repo.resolve(link)
    return resolved.kind == model.ARTIFACT_LINK and resolved.path == path


def _retarget(link: model.Link, from_file: str, to_path: str) -> str:
    """Цель ссылки `link`, стоящей в файле `from_file`, на `to_path` (от
    корня): путь — от файла, якорь и `/` на конце пути — как были."""
    raw_path, sep, fragment = link.target.partition('#')
    path = model.rel_link(from_file, to_path, is_dir=raw_path.endswith('/'))
    return path + sep + fragment


def _rebase_edits(
    repo: model.Repo, doc: model.Document, new_file: str, moved: bool
) -> List[_Edit]:
    """Правки целей ссылок и картинок `doc`, текст которого ляжет в
    `new_file`: каждая цель ведёт туда же, куда вела.

    `moved` — файл переезжает (`entomb`): ссылка на сам файл ведёт на новое
    место. Иначе текст копируется (`snapshot-prd`), а исходный файл остаётся
    на месте: ссылки на него ведут на него. Якорь без пути не меняется — тот
    же файл, — кроме ссылки на требование: она ведёт в текущий PRD. Цель от
    корня не меняется, если ведёт не на переезжающий файл.
    """
    edits: List[_Edit] = []
    for link in _targets(doc):
        if link.is_external:
            continue
        raw_path, _ = link.split_target()
        resolved = repo.resolve(link)
        if resolved.path is None:
            continue
        if raw_path == '' and resolved.kind != model.REQUIREMENT_LINK:
            continue
        target = resolved.path
        if moved and target == doc.path:
            target = new_file
        elif raw_path.startswith('/'):
            continue
        new_target = _retarget(link, new_file, target)
        if new_target != link.target:
            edits.append((link.target_start, link.target_end, new_target))
    return edits


def _apply(text: str, edits: Sequence[_Edit]) -> str:
    """Текст с правками; куски правок не пересекаются."""
    parts: List[str] = []
    last = 0
    for start, end, value in sorted(edits):
        parts += [text[last:start], value]
        last = end
    parts.append(text[last:])
    return ''.join(parts)


# --------------------------------------------------------------------------
# Файлы


def _is_derived(path: str) -> bool:
    """Производный файл — его пишет `views`."""
    return posixpath.basename(path) == model.INDEX_NAME or path == model.DASHBOARD_PATH


def _abs(repo: model.Repo, path: str) -> str:
    return os.path.join(repo.root, *path.split('/'))


def _require_free(repo: model.Repo, path: str) -> None:
    """На месте нового файла ничего нет — и без учёта регистра букв, как на
    диске macOS: иначе запись затёрла бы чужой файл."""
    if os.path.exists(_abs(repo, path)):
        raise model.Refusal(f'{path} уже есть')


def _require_utf8(repo: model.Repo, path: str) -> None:
    """Файл читается как UTF-8 без замен: `Repo` читает с заменой байтов, и
    запись переписанного текста испортила бы файл."""
    try:
        with open(_abs(repo, path), encoding='utf-8') as handle:
            handle.read()
    except UnicodeDecodeError as error:
        raise model.Refusal(f'{path} не в UTF-8 ({error.reason}): переписать его ссылки '
                            'нельзя, не испортив файл') from error


def _write(repo: model.Repo, path: str, text: str) -> None:
    target = _abs(repo, path)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write(text)


def _require_date(date: str) -> None:
    if not model.valid_date(date):
        raise model.Refusal(f'дата {date} — не ГГГГ-ММ-ДД')


def _one_line(text: Optional[str]) -> str:
    """Текст одной строкой без лишних пробелов; None — ''."""
    return ' '.join((text or '').split())
