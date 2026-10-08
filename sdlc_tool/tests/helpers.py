"""Фикстура тестов sdlc_tool: временный git-репозиторий с деревом `sdlc/`.

`Tree` — копия шаблонного репозитория: все папки структуры с `README.md`,
`AGENTS.md`, `CLAUDE.md` (импорт `@AGENTS.md`) и один коммит. Шаблон
создаётся один раз на процесс и копируется в каждый тест.

`seed(tree)` пишет согласованный мир: PRD с R1 и R2, бизнес-задачу, модуль,
сущность, событие, актора, UC с путём, токен, компонент, экран, задание,
сдачу, приёмку и ручной кейс; все ссылки разрешаются, ошибок нет. Пути —
константы модуля.

`bury(tree, path, …)` хоронит артефакт руками так, как это делает `entomb`:
перенос в `obsolete/`, шапка, пути ссылок дерева и самого файла.

    python3 -m unittest discover -s sdlc_tool/tests -t .
"""

from __future__ import annotations

import atexit
import os
import shutil
import subprocess
import tempfile
import unittest
from typing import List, Optional, Sequence, Tuple

from sdlc_tool import check, model

STRUCTURE_DIRS: Tuple[str, ...] = (
    'sdlc',
    'sdlc/0-vibes',
    'sdlc/0-vibes/prd',
    'sdlc/0-vibes/prd/history',
    'sdlc/0-vibes/raw',
    'sdlc/1-business-tasks',
    'sdlc/1-business-tasks/observation',
    'sdlc/1-business-tasks/observation/errors',
    'sdlc/1-business-tasks/observation/infos',
    'sdlc/1-business-tasks/observation/warnings',
    'sdlc/1-business-tasks/planning',
    'sdlc/2-specs',
    'sdlc/2-specs/actors',
    'sdlc/2-specs/entities',
    'sdlc/2-specs/events',
    'sdlc/2-specs/modules',
    'sdlc/2-specs/use-cases',
    'sdlc/3-design',
    'sdlc/3-design/design-system',
    'sdlc/4-tasks',
    'sdlc/5-results',
    'sdlc/6-eval',
    'sdlc/6-eval/acceptance',
    'sdlc/6-eval/auto',
    'sdlc/6-eval/manual',
    'sdlc/7-security-check',
    'sdlc/8-deploy',
    'sdlc/9-observation',
    'sdlc/9-observation/errors',
    'sdlc/9-observation/infos',
    'sdlc/9-observation/warnings',
)

# Мир `seed`.
PRD = 'sdlc/0-vibes/prd/PRD.md'
RAW_DAY = 'sdlc/0-vibes/raw/2026-11-01'
BT_1 = 'sdlc/1-business-tasks/planning/BT-1-PLANNING-LOGIN.md'
MOD_1 = 'sdlc/2-specs/modules/MOD-1-AUTH.md'
ENT_1 = 'sdlc/2-specs/entities/ENT-1-ACCOUNT-IN-AUTH.md'
EVT_1 = 'sdlc/2-specs/events/EVT-1-SIGNED-IN-IN-AUTH.md'
ACTOR_1 = 'sdlc/2-specs/actors/ACTOR-1-STUDENT-IN-AUTH.md'
UC_1 = 'sdlc/2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md'
TOKEN_1 = 'sdlc/3-design/design-system/TOKEN-1-COLOR.md'
COMP_1 = 'sdlc/3-design/design-system/COMP-1-BUTTON.md'
FIG_1 = 'sdlc/3-design/FIG-1-LOGIN.md'
TASK_1 = 'sdlc/4-tasks/TASK-1-LOGIN.md'
RESULT_1 = 'sdlc/5-results/RESULT-TASK-1-01.md'
ACC_1 = 'sdlc/6-eval/acceptance/ACC-TASK-1-01.md'
TC_1 = 'sdlc/6-eval/manual/TC-1-LOGIN.md'

_GIT_OPTIONS = (
    '-c', 'user.name=sdlc-tool-test',
    '-c', 'user.email=sdlc-tool-test@example.invalid',
    '-c', 'commit.gpgsign=false',
    '-c', 'core.autocrlf=false',
    '-c', f'core.hooksPath={os.devnull}',
    # Без фонового обслуживания: после коммита git дописывает в .git
    # отдельным процессом, и удаление временного репозитория падает.
    '-c', 'maintenance.auto=false',
    '-c', 'gc.auto=0',
)
_TEMPLATE: Optional[str] = None


def run_git(root: str, *args: str) -> str:
    """git в репозитории фикстуры; ошибка git — AssertionError."""
    completed = subprocess.run(
        ['git', '-C', root] + list(_GIT_OPTIONS) + list(args),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if completed.returncode != 0:
        raise AssertionError(
            f'git {" ".join(args)}: {completed.stderr.decode("utf-8", "replace")}')
    return completed.stdout.decode('utf-8', 'replace')


def _write(root: str, path: str, text: str) -> None:
    absolute = os.path.join(root, *path.split('/'))
    os.makedirs(os.path.dirname(absolute), exist_ok=True)
    with open(absolute, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write(text)


def structure_files(directory: str) -> List[Tuple[str, str]]:
    """Файлы соглашений папки структуры."""
    name = directory.rsplit('/', 1)[-1]
    return [
        (f'{directory}/README.md', f'# {name}\n\nЗачем эта папка.\n'),
        (f'{directory}/AGENTS.md', f'Правила папки {name}.\n'),
        (f'{directory}/CLAUDE.md', '@AGENTS.md\n'),
    ]


def _template() -> str:
    global _TEMPLATE
    if _TEMPLATE is None:
        base = tempfile.mkdtemp(prefix='sdlc_tool_template_')
        atexit.register(shutil.rmtree, base, True)
        root = os.path.join(base, 'repo')
        os.makedirs(root)
        run_git(root, 'init', '-q')
        for directory in STRUCTURE_DIRS:
            for path, text in structure_files(directory):
                _write(root, path, text)
        _write(root, 'lib/main.dart', 'void main() {}\n')
        run_git(root, 'add', '-A')
        run_git(root, 'commit', '-q', '--no-verify', '-m', 'каркас')
        _TEMPLATE = root
    return _TEMPLATE


def link(from_path: str, to_path: str, text: str, fragment: Optional[str] = None) -> str:
    """Markdown-ссылка из файла `from_path` на `to_path` с видимым текстом."""
    return f'[{text}]({model.rel_link(from_path, to_path, fragment)})'


def requirement(number: int, text: str, mark: str = '') -> str:
    """Строка требования; `mark` — отметка с ведущим пробелом или ''."""
    return f'<a id="r{number}"></a>**R{number}.**{mark} {text}'


def obsolete_mark(date: str = '2026-11-02', by: Optional[int] = None) -> str:
    """Отметка устаревания в формате PRD."""
    if by is None:
        return f' **Устарело {date}, заменено ничем.**'
    return f' **Устарело {date}, заменено [R{by}](#r{by}).**'


def prd_text(*requirements: str, extra: str = '') -> str:
    """PRD с разделом требований."""
    body = '\n\n'.join(requirements)
    return (f'# PRD\n\n## Назначение и границы\n\nПлатформа тренировки.\n\n'
            f'## Требования\n\n{body}\n{extra}')


def uc_text(
    number: int,
    paths: Sequence[Tuple[str, str]] = (('01', 'вход с верным паролем'),),
    basis: str = '',
    title: str = 'вход по паролю',
) -> str:
    """Текст UC: основание и пути с исходами того же номера."""
    lines = [f'# UC-{number} — {title}', '', '## Основание', '', basis, '',
             '## Пути', '']
    for nn, name in paths:
        lines += [f'### <a id="uc-{number}-p-{nn}"></a>UC-{number}-P-{nn} — {name}', '',
                  'Ученик вводит логин и пароль.', '',
                  f'**Исход:** UC-{number}-O-{nn} — открыт каталог', '']
    return '\n'.join(lines)


class Tree:
    """Временный git-репозиторий с деревом `sdlc/`."""

    def __init__(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix='sdlc_tool_test_')
        self.root = os.path.join(self._tmp.name, 'repo')
        shutil.copytree(_template(), self.root, symlinks=True)

    def cleanup(self) -> None:
        self._tmp.cleanup()

    def abs(self, path: str) -> str:
        return os.path.join(self.root, *path.split('/'))

    def write(self, path: str, text: str) -> None:
        _write(self.root, path, text)

    def read(self, path: str) -> str:
        with open(self.abs(path), encoding='utf-8') as handle:
            return handle.read()

    def exists(self, path: str) -> bool:
        return os.path.exists(self.abs(path))

    def remove(self, path: str) -> None:
        target = self.abs(path)
        if os.path.isdir(target):
            shutil.rmtree(target)
        else:
            os.remove(target)

    def move(self, source: str, destination: str) -> None:
        os.makedirs(os.path.dirname(self.abs(destination)), exist_ok=True)
        os.replace(self.abs(source), self.abs(destination))

    def replace(self, path: str, old: str, new: str) -> None:
        """Заменяет в файле ровно одно вхождение `old`."""
        text = self.read(path)
        if text.count(old) != 1:
            raise AssertionError(f'{path}: {old!r} встречается {text.count(old)} раз')
        self.write(path, text.replace(old, new))

    def git(self, *args: str) -> str:
        return run_git(self.root, *args)

    def commit(self, message: str = 'шаг') -> str:
        self.git('add', '-A')
        self.git('commit', '-q', '--no-verify', '--allow-empty', '-m', message)
        return self.git('rev-parse', 'HEAD').strip()

    def repo(self) -> model.Repo:
        return model.load_repo(self.root)

    def check(self, base: Optional[str] = None, derived: bool = False) -> List[check.Message]:
        """Сообщения `check`; по умолчанию без базы и без проверки 12."""
        return check.check(self.repo(), base, derived=derived)

    def errors(self, base: Optional[str] = None) -> List[str]:
        return [item.format() for item in self.check(base) if item.severity == check.ERROR]

    def warnings(self, base: Optional[str] = None) -> List[str]:
        return [item.format() for item in self.check(base) if item.severity == check.WARNING]


class TreeTestCase(unittest.TestCase):
    """База тестов с деревом: `self.tree`, проверки сообщений."""

    def setUp(self) -> None:
        self.tree = Tree()
        self.addCleanup(self.tree.cleanup)

    def assertMessage(self, messages: Sequence[str], path: str, fragment: str) -> None:
        """Есть сообщение о файле `path` (или `path:строка`) с текстом `fragment`."""
        for message in messages:
            where = message.split(' ', 1)[1].split(': ', 1)[0]
            if (where == path or where.startswith(path + ':')) and fragment in message:
                return
        self.fail(f'нет сообщения {path}: …{fragment}… среди:\n' + '\n'.join(messages))

    def assertOnly(self, messages: Sequence[str], path: str, fragment: str) -> None:
        """Сообщение ровно одно, и оно — о `path` с `fragment`."""
        self.assertEqual(len(messages), 1, '\n'.join(messages))
        self.assertMessage(messages, path, fragment)


def seed(tree: Tree) -> None:
    """Согласованный мир без ошибок (пути — константы модуля)."""
    tree.write(f'{RAW_DAY}/notes.md', 'Ученики просят вход по паролю.\n')
    tree.write(PRD, prd_text(
        requirement(1, 'Ученик входит по логину и паролю.'),
        requirement(2, 'Ученик видит каталог задач.'),
    ))
    tree.write(BT_1, '\n'.join([
        '# BT-1 — вход по паролю', '',
        f'Требование: {link(BT_1, PRD, "R1", "r1")}.',
        f'Доказательство: {link(BT_1, RAW_DAY, "0-vibes/raw/2026-11-01/")}.', '']))
    tree.write(MOD_1, '\n'.join([
        '# MOD-1 — AUTH', '', f'Основание: {link(MOD_1, BT_1, "BT-1")}.', '']))
    tree.write(ENT_1, '\n'.join([
        '# ENT-1 — учётная запись', '', f'Модуль: {link(ENT_1, MOD_1, "MOD-1")}.', '']))
    tree.write(EVT_1, '\n'.join([
        '# EVT-1 — вход выполнен', '', f'Сущность: {link(EVT_1, ENT_1, "ENT-1")}.', '']))
    tree.write(ACTOR_1, '\n'.join([
        '# ACTOR-1 — ученик', '',
        f'Сущность: {link(ACTOR_1, ENT_1, "ENT-1")}, событие: {link(ACTOR_1, EVT_1, "EVT-1")}.',
        '']))
    tree.write(UC_1, uc_text(1, basis=(
        f'{link(UC_1, PRD, "R1", "r1")}, {link(UC_1, BT_1, "BT-1")}, '
        f'{link(UC_1, MOD_1, "MOD-1")}.')))
    tree.write(TOKEN_1, '\n'.join([
        '# TOKEN-1 — цвета', '',
        f'Основание: {link(TOKEN_1, UC_1, "UC-1")}.', '',
        '| Имя | Значение | Назначение |', '|---|---|---|',
        '| <a id="accent"></a>`accent` | `#1E88E5` | акцент |', '']))
    tree.write(COMP_1, '\n'.join([
        '# COMP-1 — кнопка', '',
        f'Токены: `accent` — {link(COMP_1, TOKEN_1, "TOKEN-1", "accent")}.', '']))
    tree.write(FIG_1, '\n'.join([
        '# FIG-1 — экран входа', '',
        f'Основание: {link(FIG_1, UC_1, "UC-1")}.', '',
        f'Состояние {link(FIG_1, UC_1, "UC-1-P-01", "uc-1-p-01")}: кнопка '
        f'{link(FIG_1, COMP_1, "COMP-1")}, цвет {link(FIG_1, TOKEN_1, "TOKEN-1", "accent")}.',
        '']))
    tree.write(TASK_1, '\n'.join([
        '# TASK-1 — вход', '',
        f'**Основание:** {link(TASK_1, UC_1, "UC-1-P-01", "uc-1-p-01")}, '
        f'{link(TASK_1, FIG_1, "FIG-1")}, {link(TASK_1, BT_1, "BT-1")}.', '']))
    tree.write(RESULT_1, '\n'.join([
        '# RESULT-TASK-1-01', '', f'Задание: {link(RESULT_1, TASK_1, "TASK-1")}.', '']))
    tree.write(ACC_1, '\n'.join([
        '# ACC-TASK-1-01', '',
        f'Сдача: {link(ACC_1, RESULT_1, "RESULT-TASK-1-01")}; '
        f'задание: {link(ACC_1, TASK_1, "TASK-1")}.', '',
        '**Вердикт:** принято', '']))
    tree.write(TC_1, '\n'.join([
        '# TC-1 — вход', '',
        f'Путь UC: {link(TC_1, UC_1, "UC-1-P-01", "uc-1-p-01")}.', '']))


def _apply(text: str, edits: List[Tuple[int, int, str]]) -> str:
    for start, end, value in sorted(edits, reverse=True):
        text = text[:start] + value + text[end:]
    return text


def bury(
    tree: Tree,
    path: str,
    by: Optional[Tuple[str, str]] = None,
    why: str = 'понятие снято',
    date: str = '2026-11-02',
) -> str:
    """Хоронит артефакт руками, как `entomb`; возвращает новый путь.

    `by` — (id, путь) замены или None — «ничем».
    """
    repo = tree.repo()
    artifact = repo.artifact_at(path)
    assert artifact is not None, path
    new_path = artifact.obsolete_path
    for other in repo.md_files:
        if other == path:
            continue
        doc = repo.doc(other)
        edits = []
        for item in doc.links:
            resolved = repo.resolve(item)
            if resolved.kind == model.ARTIFACT_LINK and resolved.path == path:
                edits.append((item.target_start, item.target_end,
                              model.rel_link(other, new_path, resolved.fragment)))
        if edits:
            tree.write(other, _apply(doc.text, edits))
    doc = repo.doc(path)
    edits = []
    for item in doc.links + doc.images:
        if item.target.startswith('#'):
            continue
        resolved = repo.resolve(item)
        if resolved.kind in (model.EXTERNAL, model.MISSING) or resolved.path is None:
            continue
        target = new_path if resolved.path == path else resolved.path
        edits.append((item.target_start, item.target_end,
                      model.rel_link(new_path, target, resolved.fragment,
                                     is_dir=resolved.kind == model.DIR_LINK)))
    replaced = (by[0], model.rel_link(new_path, by[1])) if by else None
    header = model.format_tomb_header(date, why, replaced)
    tree.write(new_path, header + _apply(doc.text, edits))
    tree.remove(path)
    return new_path
