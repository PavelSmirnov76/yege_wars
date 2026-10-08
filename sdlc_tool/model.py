"""Модель дерева конвейера: артефакты, требования, пути UC, якоря, ссылки, метки.

Правила разбора — `sdlc_tool/README.md`, раздел «Модель дерева». Модель
строится над «источником» файлов: рабочее дерево (`FsSource`, `load_repo`)
или коммит git (`gitbase.GitSource`, `load_base`). Разбор ленивый и
кэшируется в `Repo`; ошибки формата, найденные при разборе, — `Issue`, их
превращает в сообщения `check`.

Пути везде — от корня репозитория, через `/` (`sdlc/2-specs/...`). Папки
артефактов (`ARTIFACT_FOLDERS`, `Artifact.folder`) — от `sdlc/`, без `/` на
конце, как в спецификации (`2-specs/use-cases`).

Как прочитаны места, где спецификация допускает разное:

- Блоки кода — ограды из трёх и более ``` или ~~~ с любым отступом (внутри
  пунктов списка тоже); незакрытая ограда тянется до конца файла. Код в строке
  — по CommonMark: серия обратных кавычек закрывается серией той же длины, в
  пределах абзаца. Отступ в четыре пробела блоком кода не считается.
- Ссылка — только встроенная `[текст](цель)`; ссылки-сноски `[текст][метка]`
  не разбираются. Картинка `![…](…)` — не ссылка и не проверяется, но её цель
  срезается при сравнении с базой, как у ссылки (`](…)` → `]()` из README
  касается и её: при переносе в `obsolete/` путь картинки перебазируется), и
  маскируется при поиске значений в экранах.
- Цель, начинающаяся с `/`, разрешается от корня репозитория (как на GitHub).
  Существование цели проверяется с учётом регистра букв, как в CI на Linux.
- Видимый текст ссылки на артефакт сравнивается с id после обрезки пробелов по
  краям; оформление (`**UC-3**`, `` `UC-3` ``) id не считается.
- Ссылка на требование — только в текущий PRD. Ссылка с текстом `R7` в снимок
  `history/` — ошибка «текст, похожий на id, ведёт не на этот артефакт»;
  поэтому `snapshot-prd` переписывает ссылки только с якорем (`#r12`) в
  `../PRD.md#r12`.
- Похоже на id — `R7`, `UC-3`, `UC-3-P-02`, `UC-3-O-02`,
  `RESULT-TASK-7-02` целиком; номера с ведущими нулями тоже похожи.
- Требование-кандидат — строка, которая начинается (после отступа и маркера
  списка) с `<a id="r` или `**R{цифры}`. Кандидат не по формату
  `<a id="r{n}"></a>**R{n}.** …` в начале строки — ошибка; так ловится и
  требование без якоря. Отметка устаревания — ровно
  ` **Устарело ГГГГ-ММ-ДД, заменено [R{k}](…#r{k}).**` или
  ` **Устарело ГГГГ-ММ-ДД, заменено ничем.**` сразу после `**R{n}.**`; путь
  перед `#r{k}` допускается (на случай разбитого PRD). Отметка с ошибкой
  (иная форма, не сразу после id, неверная дата) — ошибка формата.
- PRD разбит, если в `0-vibes/prd/PRD/` есть `.md`: тогда PRD — они, а
  `PRD.md` рядом не читается.
- Путь UC — заголовок `###`, в котором есть `<a id="uc-` или `UC-{n}-P-`.
  Раздел пути кончается любым заголовком уровня 1–3. Исход — строка,
  начинающаяся с `**Исход` или `Исход:`. Исход вне раздела пути — ошибка.
  `{nn}` пути и исхода — по грамматике `{NN}`: `01`…`99`, `100`…
- Строка вердикта может стоять в пункте списка: `- **Вердикт:** принято`,
  `2. **Вердикт:** принято`. Кандидат — строка, начинающаяся с `**Вердикт`
  или `Вердикт:`; кандидат не по формату — ошибка; две строки по формату —
  ошибка. То же в `transcript.md` с `PASS`, `FAIL`, `BLOCKED`.
- `supersedes:` — строка, начинающаяся ровно с `supersedes: `, дальше только
  ссылки через запятую. Строк и ссылок может быть несколько (слияние).
- Шапка похороненного — ровно три строки `> **Похоронен:** …`,
  `> **Почему:** …`, `> **Заменён:** …` и пустая строка после них. Файл,
  который начинается с `> **Похоронен:**`, но не по формату, — шапка с
  ошибкой; при сравнении с базой срезается весь начальный блок строк `>`.
  Шапка снимка PRD — так же с `Сменён`, `Почему`, `Вход`.
- Файл в папке структуры или содержимого, имя которого похоже на артефакт
  (`UC-3-…`, `RESULT-TASK-…`), но который лежит не в папке артефактов своего
  типа, — ошибка «не в своей папке» (глоб `**/UC-3-*.md` найдёт два файла).
- В `0-vibes/prd/history/` кроме файлов соглашений и `INDEX.md` — только
  снимки `PRD-ГГГГ-ММ-ДД.md` и `PRD-ГГГГ-ММ-ДД-{NN}.md`; иное имя — ошибка.
- Метка в коде — `UC-{цифры}`, `UC-{цифры}-P-{цифры}`, `TOKEN-…`, `COMP-…`;
  цифры с ведущими нулями тоже метка (и ведёт в несуществующий id). Файлы
  кода — те, что видит git (отслеживаемые и неотслеживаемые без
  игнорируемых), поэтому `supabase/seed/local/` не читается; без git —
  обход папок без скрытых и без `supabase/seed/local/`.
- Переводы строк читаются как `\\n` (`\\r\\n` приводится).
"""

from __future__ import annotations

import bisect
import datetime
import json
import os
import posixpath
import re
import urllib.parse
from dataclasses import dataclass
from typing import Dict, List, Optional, Sequence, Set, Tuple, Union

from . import gitbase

# --------------------------------------------------------------------------
# Константы дерева

SDLC = 'sdlc'

# Слова-типы id артефактов-файлов, в порядке таблицы закона.
TYPE_WORDS: Tuple[str, ...] = (
    'BT', 'MOD', 'ACTOR', 'ENT', 'EVT', 'UC', 'TOKEN', 'COMP', 'FIG', 'TASK',
    'RESULT', 'ACC', 'TC', 'SEC', 'REL',
)
REQUIREMENT = 'R'
ID_TYPES: Tuple[str, ...] = (REQUIREMENT,) + TYPE_WORDS
# Типы, у которых id включает задание-владельца: RESULT-TASK-7-02.
OWNED_TYPES: Tuple[str, ...] = ('RESULT', 'ACC')
BT_TYPES: Tuple[str, ...] = ('ERROR', 'WARNING', 'INFO', 'PLANNING')
# Типы, чьё имя несёт модуль -IN-{WORD}.
MODULE_TYPES: Tuple[str, ...] = ('ACTOR', 'ENT', 'EVT', 'UC')

# Папка артефактов (от sdlc/) → типы, которые в ней лежат.
ARTIFACT_FOLDERS: Dict[str, Tuple[str, ...]] = {
    '1-business-tasks/observation/errors': ('BT',),
    '1-business-tasks/observation/infos': ('BT',),
    '1-business-tasks/observation/warnings': ('BT',),
    '1-business-tasks/planning': ('BT',),
    '2-specs/actors': ('ACTOR',),
    '2-specs/entities': ('ENT',),
    '2-specs/events': ('EVT',),
    '2-specs/modules': ('MOD',),
    '2-specs/use-cases': ('UC',),
    '3-design': ('FIG',),
    '3-design/design-system': ('TOKEN', 'COMP'),
    '4-tasks': ('TASK',),
    '5-results': ('RESULT',),
    '6-eval/acceptance': ('ACC',),
    '6-eval/manual': ('TC',),
    '7-security-check': ('SEC',),
    '8-deploy': ('REL',),
}
# {TYPE} бизнес-задачи по папке.
BT_FOLDER_TYPES: Dict[str, str] = {
    '1-business-tasks/observation/errors': 'ERROR',
    '1-business-tasks/observation/infos': 'INFO',
    '1-business-tasks/observation/warnings': 'WARNING',
    '1-business-tasks/planning': 'PLANNING',
}
# Тип → папки артефактов этого типа.
TYPE_FOLDERS: Dict[str, Tuple[str, ...]] = {
    kind: tuple(sorted(f for f, kinds in ARTIFACT_FOLDERS.items() if kind in kinds))
    for kind in TYPE_WORDS
}

NAME_TEMPLATES: Dict[str, str] = {
    'BT': 'BT-{n}-{TYPE}-{TITLE}.md',
    'MOD': 'MOD-{n}-{WORD}.md',
    'ACTOR': 'ACTOR-{n}-{NAME}-IN-{WORD}.md',
    'ENT': 'ENT-{n}-{NAME}-IN-{WORD}.md',
    'EVT': 'EVT-{n}-{NAME}-IN-{WORD}.md',
    'UC': 'UC-{n}-ACTOR-{a}-EVT-{e}-ENT-{s}-{NAME}-IN-{WORD}.md',
    'TOKEN': 'TOKEN-{n}-{WORD}.md',
    'COMP': 'COMP-{n}-{NAME}.md',
    'FIG': 'FIG-{n}-{NAME}.md',
    'TASK': 'TASK-{n}-{NAME}.md',
    'RESULT': 'RESULT-TASK-{n}-{NN}.md или RESULT-TASK-{n}-{NN}-{NAME}.md',
    'ACC': 'ACC-TASK-{n}-{NN}.md или ACC-TASK-{n}-{NN}-{NAME}.md',
    'TC': 'TC-{n}-{NAME}.md',
    'SEC': 'SEC-{n}-{NAME}.md',
    'REL': 'REL-{n}-{NAME}.md',
}

CONVENTION_FILES: Tuple[str, ...] = ('README.md', 'AGENTS.md', 'CLAUDE.md')
INDEX_NAME = 'INDEX.md'
OBSOLETE = 'obsolete'

PRD_DIR = 'sdlc/0-vibes/prd'
PRD_PATH = 'sdlc/0-vibes/prd/PRD.md'
PRD_SPLIT_DIR = 'sdlc/0-vibes/prd/PRD'
HISTORY_DIR = 'sdlc/0-vibes/prd/history'
RAW_DIR = 'sdlc/0-vibes/raw'
AUTO_DIR = 'sdlc/6-eval/auto'
MANUAL_DIR = 'sdlc/6-eval/manual'
DASHBOARD_PATH = 'sdlc/6-eval/DASHBOARD.md'
DERIVED_HEADER = (
    '<!-- Производный файл: собирает `python3 -m sdlc_tool views`, '
    'руками не править. -->'
)

CODE_DIRS = gitbase.CODE_DIRS
CODE_EXTENSIONS = gitbase.CODE_EXTENSIONS
THEME_DIR = 'lib/app/theme'
# Секреты: не читаются, даже когда git недоступен.
SECRET_DIRS: Tuple[str, ...] = ('supabase/seed/local',)

STRUCTURE = 'structure'
CONTENT = 'content'

ACCEPTANCE_VERDICTS: Tuple[str, ...] = ('принято', 'возврат')
MANUAL_VERDICTS: Tuple[str, ...] = ('PASS', 'FAIL', 'BLOCKED')

# --------------------------------------------------------------------------
# Общие классы


class Refusal(Exception):
    """Отказ команды: текст для пользователя и код возврата CLI."""

    def __init__(self, message: str, code: int = 1) -> None:
        super().__init__(message)
        self.code = code


@dataclass(frozen=True)
class Issue:
    """Нарушение формата, найденное при разборе: файл, строка (0 — нет), текст."""

    path: str
    line: int
    text: str


# --------------------------------------------------------------------------
# Пути и папки

_DATE_RE = re.compile(r'[0-9]{4}-[0-9]{2}-[0-9]{2}')
_SNAPSHOT_RE = re.compile(
    r'PRD-([0-9]{4}-[0-9]{2}-[0-9]{2})(?:-(0[2-9]|[1-9][0-9]+))?\.md'
)


def is_date(text: str) -> bool:
    """Строка — дата `ГГГГ-ММ-ДД` (только форма, без проверки календаря)."""
    return bool(_DATE_RE.fullmatch(text))


def valid_date(text: str) -> bool:
    """Строка — настоящая дата `ГГГГ-ММ-ДД`."""
    if not is_date(text):
        return False
    try:
        datetime.date.fromisoformat(text)
    except ValueError:
        return False
    return True


def sdlc_rel(path: str) -> str:
    """Путь от `sdlc/` для пути от корня (`sdlc` → '')."""
    if path == SDLC:
        return ''
    if path.startswith(SDLC + '/'):
        return path[len(SDLC) + 1:]
    raise ValueError(f'путь не под sdlc/: {path}')


def classify_dir(path: str) -> str:
    """`STRUCTURE` или `CONTENT` для папки `path` (от корня, под `sdlc/`)."""
    rel = sdlc_rel(path)
    parts = rel.split('/') if rel else []
    if OBSOLETE in parts:
        return CONTENT
    if len(parts) >= 3:
        head = parts[0], parts[1]
        if head == ('0-vibes', 'raw') and is_date(parts[2]):
            return CONTENT
        if head == ('6-eval', 'auto'):
            return CONTENT
        if head == ('6-eval', 'manual') and is_date(parts[2]):
            return CONTENT
        if head == ('0-vibes', 'prd') and parts[2] == 'PRD':
            return CONTENT
    return STRUCTURE


def is_link_checked(path: str) -> bool:
    """Ссылки файла проверяются: `.md` под `sdlc/`, кроме содержимого `raw/`,
    прогонов `6-eval/auto/` и раундов `6-eval/manual/`."""
    if not path.endswith('.md'):
        return False
    try:
        rel = sdlc_rel(posixpath.dirname(path))
    except ValueError:
        return False
    parts = rel.split('/') if rel else []
    if len(parts) >= 3:
        head = parts[0], parts[1]
        if head == ('0-vibes', 'raw') and is_date(parts[2]):
            return False
        if head == ('6-eval', 'auto'):
            return False
        if head == ('6-eval', 'manual') and is_date(parts[2]):
            return False
    return True


def artifact_home(directory: str) -> Tuple[Optional[str], bool]:
    """Папка артефактов (от `sdlc/`), в которой или в чьём `obsolete/` лежит
    папка `directory` (от корня), и признак `obsolete/`; не она — (None, False)."""
    try:
        rel = sdlc_rel(directory)
    except ValueError:
        return None, False
    if rel in ARTIFACT_FOLDERS:
        return rel, False
    parent, _, last = rel.rpartition('/')
    if last == OBSOLETE and parent in ARTIFACT_FOLDERS:
        return parent, True
    return None, False


def folder_path(folder: str) -> str:
    """Папка артефактов от корня: '2-specs/use-cases' → 'sdlc/2-specs/use-cases'."""
    return f'{SDLC}/{folder}' if folder else SDLC


def index_path(folder: str) -> str:
    """Путь `INDEX.md` папки артефактов `folder` (от `sdlc/`)."""
    return f'{folder_path(folder)}/{INDEX_NAME}'


def is_snapshot_name(filename: str) -> bool:
    """Имя файла — снимок PRD `PRD-ГГГГ-ММ-ДД[-NN].md`."""
    return bool(_SNAPSHOT_RE.fullmatch(filename))


def count_lines(text: str) -> int:
    """Число строк текста, как у `wc -l` плюс последняя строка без `\\n`."""
    if not text:
        return 0
    return text.count('\n') + (0 if text.endswith('\n') else 1)


def _encode_target_path(path: str) -> str:
    # Только то, что ломает разбор ссылки; кириллица остаётся читаемой.
    return (path.replace('%', '%25').replace(' ', '%20')
            .replace('(', '%28').replace(')', '%29'))


def rel_link(
    from_file: str,
    to_path: str,
    fragment: Optional[str] = None,
    is_dir: bool = False,
) -> str:
    """Цель ссылки из файла `from_file` на `to_path` (оба от корня).

    Ссылка файла на себя с якорем — просто `#якорь`. У папки — `/` на конце.
    """
    if to_path == from_file and fragment:
        return '#' + fragment
    base = posixpath.dirname(from_file) or '.'
    rel = posixpath.relpath(to_path or '.', base)
    if is_dir and not rel.endswith('/'):
        rel += '/'
    rel = _encode_target_path(rel)
    if fragment:
        rel += '#' + fragment
    return rel


# --------------------------------------------------------------------------
# Имена артефактов

_N = r'[1-9][0-9]*'
_NN = r'(?:0[1-9]|[1-9][0-9]+)'
_NAME = r'[A-Z0-9]+(?:-[A-Z0-9]+)*'

_NAME_RES: Dict[str, 're.Pattern[str]'] = {
    'BT': re.compile(rf'BT-({_N})-([A-Z0-9]+)-({_NAME})'),
    'MOD': re.compile(rf'MOD-({_N})-({_NAME})'),
    'TOKEN': re.compile(rf'TOKEN-({_N})-({_NAME})'),
    'UC': re.compile(rf'UC-({_N})-ACTOR-({_N})-EVT-({_N})-ENT-({_N})-({_NAME})'),
    'RESULT': re.compile(rf'RESULT-TASK-({_N})-({_NN})(?:-({_NAME}))?'),
    'ACC': re.compile(rf'ACC-TASK-({_N})-({_NN})(?:-({_NAME}))?'),
}
for _kind in ('ACTOR', 'ENT', 'EVT', 'COMP', 'FIG', 'TASK', 'TC', 'SEC', 'REL'):
    _NAME_RES[_kind] = re.compile(rf'{_kind}-({_N})-({_NAME})')
del _kind

_ARTIFACT_LIKE_RE = re.compile(
    r'(?:(?:BT|MOD|ACTOR|ENT|EVT|UC|TOKEN|COMP|FIG|TASK|TC|SEC|REL)-[0-9]'
    r'|(?:RESULT|ACC)-TASK-[0-9])'
)


@dataclass(frozen=True)
class ArtifactName:
    """Разобранное имя файла артефакта."""

    id: str
    type: str
    number: int             # n; у RESULT и ACC — номер задания
    nn: Optional[str]       # у RESULT и ACC — номер сдачи как в имени: '02'
    name: str               # часть имени после id без .md; '' — нет
    bt_type: Optional[str]  # у BT — ERROR, WARNING, INFO, PLANNING
    module: Optional[str]   # у ACTOR, ENT, EVT, UC — {WORD} из -IN-; у MOD — имя
    uc_refs: Tuple[Tuple[str, int], ...]  # у UC: (('ACTOR', a), ('EVT', e), ('ENT', s))


def looks_like_artifact_name(filename: str) -> bool:
    """Имя начинается как id артефакта: `UC-3…`, `RESULT-TASK-7…`."""
    return bool(_ARTIFACT_LIKE_RE.match(filename))


def parse_artifact_name(filename: str) -> Tuple[Optional[ArtifactName], Optional[str]]:
    """Разбирает имя файла по грамматике README скрипта.

    Возвращает (имя, None) или (None, причина отказа по-русски).
    """
    if not filename.endswith('.md'):
        return None, 'не файл .md'
    stem = filename[:-3]
    kind = stem.split('-', 1)[0]
    if kind not in TYPE_WORDS:
        return None, 'имя не начинается с типа id'
    template = NAME_TEMPLATES[kind]
    match = _NAME_RES[kind].fullmatch(stem)
    if match is None:
        return None, f'имя не по грамматике {template}'
    number = int(match.group(1))
    nn: Optional[str] = None
    bt_type: Optional[str] = None
    module: Optional[str] = None
    uc_refs: Tuple[Tuple[str, int], ...] = ()
    words: List[str] = []
    if kind == 'BT':
        bt_type = match.group(2)
        if bt_type not in BT_TYPES:
            return None, (f'тип бизнес-задачи {bt_type} — не '
                          f'{", ".join(BT_TYPES)}')
        words.append(match.group(3))
    elif kind in ('MOD', 'TOKEN'):
        word = match.group(2)
        if '-' in word:
            return None, f'{{WORD}} — одно слово без дефисов, а не {word}: {template}'
        if kind == 'MOD':
            module = word
        words.append(word)
    elif kind in MODULE_TYPES:
        if kind == 'UC':
            uc_refs = (('ACTOR', int(match.group(2))),
                       ('EVT', int(match.group(3))),
                       ('ENT', int(match.group(4))))
            rest = match.group(5)
        else:
            rest = match.group(2)
        head, sep, word = rest.rpartition('-IN-')
        if not sep:
            return None, f'нет -IN-{{WORD}}: имя не по грамматике {template}'
        if '-' in word:
            return None, f'модуль {word} в -IN-{{WORD}} — не одно слово: {template}'
        module = word
        words += [head, word]
    elif kind in OWNED_TYPES:
        nn = match.group(2)
        if match.group(3):
            words.append(match.group(3))
    else:
        words.append(match.group(2))
    for part in words:
        for word in part.split('-'):
            if word in TYPE_WORDS:
                return None, f'слово-тип {word} отдельным словом в имени'
    artifact_id = f'{kind}-TASK-{number}-{nn}' if nn else f'{kind}-{number}'
    name = stem[len(artifact_id) + 1:] if len(stem) > len(artifact_id) else ''
    return ArtifactName(
        id=artifact_id, type=kind, number=number, nn=nn, name=name,
        bt_type=bt_type, module=module, uc_refs=uc_refs,
    ), None


def expected_folders(name: ArtifactName) -> Tuple[str, ...]:
    """Папки (от `sdlc/`), где может лежать артефакт с этим именем; у
    бизнес-задачи — папка её {TYPE}."""
    if name.type == 'BT':
        return tuple(folder for folder, kind in sorted(BT_FOLDER_TYPES.items())
                     if kind == name.bt_type)
    return TYPE_FOLDERS[name.type]


def _misplaced_text(name: ArtifactName) -> str:
    places = ', '.join(f'{folder_path(folder)}/' for folder in expected_folders(name))
    return f'артефакт {name.id} не в своей папке: его место — {places}'


@dataclass(frozen=True)
class Artifact:
    """Файл-артефакт: имя, место и признаки места.

    `folder` — папка артефактов от `sdlc/`, где лежит файл (для лежащего в
    `obsolete/` — папка над ним). У лежащего не в своей папке (`misplaced`) —
    фактическая папка, тоже без `obsolete`.
    """

    id: str
    type: str
    number: int
    nn: Optional[str]
    name: str
    bt_type: Optional[str]
    module: Optional[str]
    uc_refs: Tuple[Tuple[str, int], ...]
    path: str
    folder: str
    buried: bool
    misplaced: bool

    @property
    def live(self) -> bool:
        return not self.buried

    @property
    def filename(self) -> str:
        return posixpath.basename(self.path)

    @property
    def dir(self) -> str:
        """Папка файла от корня (с `obsolete`, если он там)."""
        return posixpath.dirname(self.path)

    @property
    def seq(self) -> int:
        """Номер в своём счётчике: n, у RESULT и ACC — {NN}."""
        return int(self.nn) if self.nn else self.number

    @property
    def counter(self) -> Tuple[str, int]:
        """Счётчик id: (тип, 0), у RESULT и ACC — (тип, номер задания)."""
        return (self.type, self.number if self.type in OWNED_TYPES else 0)

    @property
    def task_id(self) -> Optional[str]:
        """У RESULT и ACC — id задания: `TASK-7`."""
        return f'TASK-{self.number}' if self.type in OWNED_TYPES else None

    @property
    def result_id(self) -> Optional[str]:
        """У RESULT и ACC — id сдачи с тем же номером: `RESULT-TASK-7-02`."""
        if self.type in OWNED_TYPES:
            return f'RESULT-TASK-{self.number}-{self.nn}'
        return None

    @property
    def sort_key(self) -> Tuple[int, int, int, str]:
        """Порядок производных файлов: тип, номер (у сдач — задание, {NN})."""
        return (TYPE_WORDS.index(self.type), self.number,
                int(self.nn) if self.nn else 0, self.path)

    @property
    def live_path(self) -> str:
        """Путь, где файл лежал бы живым (в своей папке, без `obsolete/`)."""
        return f'{folder_path(self.folder)}/{self.filename}'

    @property
    def obsolete_path(self) -> str:
        """Путь, где файл лежал бы похороненным."""
        return f'{folder_path(self.folder)}/{OBSOLETE}/{self.filename}'


# --------------------------------------------------------------------------
# Id

_ID_PATTERNS: Tuple[Tuple[str, 're.Pattern[str]'], ...] = (
    ('R', re.compile(rf'R({_N})')),
    ('path', re.compile(rf'UC-({_N})-([PO])-({_NN})')),
    ('owned', re.compile(rf'(RESULT|ACC)-TASK-({_N})-({_NN})')),
    ('plain', re.compile(
        rf'(BT|MOD|ACTOR|ENT|EVT|UC|TOKEN|COMP|FIG|TASK|TC|SEC|REL)-({_N})')),
)
_ID_LIKE_RE = re.compile(
    r'(?:R[0-9]+'
    r'|UC-[0-9]+-[PO]-[0-9]+'
    r'|(?:RESULT|ACC)-TASK-[0-9]+-[0-9]+'
    r'|(?:BT|MOD|ACTOR|ENT|EVT|UC|TOKEN|COMP|FIG|TASK|TC|SEC|REL)-[0-9]+)'
)


@dataclass(frozen=True)
class IdRef:
    """Разобранный id: требование, артефакт, путь или исход UC."""

    text: str
    type: str                 # 'R' или слово-тип; у пути и исхода — 'UC'
    number: int               # n; у RESULT и ACC — номер задания; у пути — номер UC
    nn: Optional[str] = None  # у RESULT и ACC — {NN}; у пути и исхода — {nn}
    part: Optional[str] = None  # 'P' — путь UC, 'O' — исход UC

    @property
    def artifact_id(self) -> str:
        """Id артефакта (или требования), которому принадлежит этот id."""
        if self.part:
            return f'UC-{self.number}'
        return self.text


def parse_id(text: str) -> Optional[IdRef]:
    """Строгий разбор id: `R7`, `UC-3`, `UC-3-P-02`, `RESULT-TASK-7-02`…"""
    for kind, pattern in _ID_PATTERNS:
        match = pattern.fullmatch(text)
        if match is None:
            continue
        if kind == 'R':
            return IdRef(text, REQUIREMENT, int(match.group(1)))
        if kind == 'path':
            return IdRef(text, 'UC', int(match.group(1)), match.group(3),
                         match.group(2))
        if kind == 'owned':
            return IdRef(text, match.group(1), int(match.group(2)),
                         match.group(3))
        return IdRef(text, match.group(1), int(match.group(2)))
    return None


def looks_like_id(text: str) -> bool:
    """Текст целиком похож на id (цифры могут быть с ведущими нулями)."""
    return bool(_ID_LIKE_RE.fullmatch(text.strip()))


def format_nn(number: int) -> str:
    """Номер {NN}: минимум две цифры."""
    return f'{number:02d}'


# --------------------------------------------------------------------------
# Markdown: код, ссылки, якоря

_FENCE_RE = re.compile(r'[ \t]*(`{3,}|~{3,})(.*)')
_ANCHOR_RE = re.compile(r'<a id="([^"]+)"></a>')
_SCHEME_RE = re.compile(r'[A-Za-z][A-Za-z0-9+.-]*:')
_HEADING_RE = re.compile(r'(#{1,6})(?:[ \t]+(.*?))?(?:[ \t]+#+)?[ \t]*$')


def _blank(chars: List[str], start: int, end: int) -> None:
    for index in range(start, end):
        if chars[index] != '\n':
            chars[index] = ' '


def _blank_line_follows(text: str, index: int) -> bool:
    length = len(text)
    while index < length and text[index] in ' \t':
        index += 1
    return index >= length or text[index] == '\n'


def _closing_backticks(text: str, index: int, run: int) -> Optional[int]:
    length = len(text)
    while index < length:
        char = text[index]
        if char == '`':
            end = index
            while end < length and text[end] == '`':
                end += 1
            if end - index == run:
                return index
            index = end
            continue
        if char == '\n' and _blank_line_follows(text, index + 1):
            return None
        index += 1
    return None


def mask_code(text: str) -> str:
    """Текст той же длины: блоки кода и код в строке заменены пробелами,
    переводы строк сохранены."""
    chars = list(text)
    offset = 0
    fence_char = ''
    fence_len = 0
    for line in text.split('\n'):
        start = offset
        offset += len(line) + 1
        if not fence_char:
            match = _FENCE_RE.match(line)
            if match is None:
                continue
            marker = match.group(1)
            if marker[0] == '`' and '`' in match.group(2):
                continue
            fence_char, fence_len = marker[0], len(marker)
        else:
            stripped = line.strip()
            if (len(stripped) >= fence_len
                    and stripped == fence_char * len(stripped)):
                fence_char = ''
        _blank(chars, start, start + len(line))
    fenced = ''.join(chars)
    length = len(fenced)
    index = 0
    while index < length:
        if fenced[index] != '`':
            index += 1
            continue
        end = index
        while end < length and fenced[end] == '`':
            end += 1
        if index > 0 and fenced[index - 1] == '\\':
            index = end
            continue
        close = _closing_backticks(fenced, end, end - index)
        if close is None:
            index = end
            continue
        _blank(chars, index, close + (end - index))
        index = close + (end - index)
    return ''.join(chars)


@dataclass(frozen=True)
class Link:
    """Ссылка `[текст](цель)` (или картинка) со смещениями в тексте файла.

    `start` — `[` (у картинки — `!`), `end` — после `)`, `text_end` — `]`,
    `target_start`…`target_end` — сама цель без `<>` и заголовка: её
    переписывает `tomb`.
    """

    path: str
    line: int
    text: str
    target: str
    start: int
    end: int
    text_start: int
    text_end: int
    target_start: int
    target_end: int

    @property
    def is_external(self) -> bool:
        """Цель со схемой (`https:`, `mailto:`) — не проверяется."""
        return bool(_SCHEME_RE.match(self.target))

    def split_target(self) -> Tuple[str, Optional[str]]:
        """(путь, якорь) цели; `%XX` раскодированы; якоря нет — None."""
        raw_path, sep, fragment = self.target.partition('#')
        return (urllib.parse.unquote(raw_path),
                urllib.parse.unquote(fragment) if sep else None)


def _match_bracket(text: str, index: int, high: int) -> Optional[int]:
    depth = 0
    while index < high:
        char = text[index]
        if char == '\\':
            index += 2
            continue
        if char == '[':
            depth += 1
        elif char == ']':
            depth -= 1
            if depth == 0:
                return index
        elif char == '\n' and _blank_line_follows(text, index + 1):
            return None
        index += 1
    return None


def _match_paren(text: str, index: int, high: int) -> Optional[int]:
    depth = 0
    while index < high:
        char = text[index]
        if char == '\\':
            index += 2
            continue
        if char == '(':
            depth += 1
        elif char == ')':
            depth -= 1
            if depth == 0:
                return index
        elif char == '\n':
            return None
        index += 1
    return None


def _destination(text: str, start: int, end: int) -> Optional[Tuple[int, int]]:
    index = start
    while index < end and text[index] in ' \t\n':
        index += 1
    if index < end and text[index] == '<':
        close = text.find('>', index + 1, end)
        if close == -1:
            return None
        return index + 1, close
    first = index
    while index < end and text[index] not in ' \t\n':
        index += 1
    return first, index


_RawLink = Tuple[int, int, int, int, int, int]


def _scan_links(
    masked: str, text: str, low: int, high: int,
    links: List[_RawLink], images: List[_RawLink],
) -> None:
    index = low
    while index < high:
        char = masked[index]
        if char == '\\':
            index += 2
            continue
        if char != '[':
            index += 1
            continue
        close = _match_bracket(masked, index, high)
        if close is None or close + 1 >= high or masked[close + 1] != '(':
            index += 1
            continue
        paren = _match_paren(masked, close + 1, high)
        if paren is None:
            index += 1
            continue
        destination = _destination(text, close + 2, paren)
        if destination is None:
            index += 1
            continue
        image = (index > low and masked[index - 1] == '!'
                 and not (index - 1 > low and masked[index - 2] == '\\'))
        item = (index - 1 if image else index, index + 1, close,
                destination[0], destination[1], paren + 1)
        if image:
            images.append(item)
        else:
            links.append(item)
            # Картинка внутри текста ссылки: [![…](…)](…).
            _scan_links(masked, text, index + 1, close, [], images)
        index = paren + 1


class Document:
    """Разобранный Markdown-файл: строки, код, ссылки, картинки, якоря."""

    def __init__(self, path: str, text: str) -> None:
        self.path = path
        self.text = text
        self._masked: Optional[str] = None
        self._line_starts: Optional[List[int]] = None
        self._links: Optional[List[Link]] = None
        self._images: Optional[List[Link]] = None
        self._anchors: Optional[Set[str]] = None

    @property
    def lines(self) -> List[str]:
        """Строки без `\\n`; у текста с `\\n` на конце последняя — ''."""
        return self.text.split('\n')

    @property
    def masked(self) -> str:
        """Текст с кодом, заменённым пробелами (см. `mask_code`)."""
        if self._masked is None:
            self._masked = mask_code(self.text)
        return self._masked

    @property
    def masked_lines(self) -> List[str]:
        return self.masked.split('\n')

    def line_of(self, offset: int) -> int:
        """Номер строки (с 1) по смещению в тексте."""
        if self._line_starts is None:
            starts = [0]
            for index, char in enumerate(self.text):
                if char == '\n':
                    starts.append(index + 1)
            self._line_starts = starts
        return bisect.bisect_right(self._line_starts, offset)

    def line_start(self, line: int) -> int:
        """Смещение начала строки `line` (с 1)."""
        self.line_of(0)
        assert self._line_starts is not None
        return self._line_starts[line - 1]

    def _parse_links(self) -> None:
        raw_links: List[_RawLink] = []
        raw_images: List[_RawLink] = []
        _scan_links(self.masked, self.text, 0, len(self.text),
                    raw_links, raw_images)
        self._links = [self._make(item) for item in raw_links]
        self._images = sorted((self._make(item) for item in raw_images),
                              key=lambda link: link.start)

    def _make(self, item: _RawLink) -> Link:
        start, text_start, text_end, target_start, target_end, end = item
        return Link(
            path=self.path, line=self.line_of(start),
            text=self.text[text_start:text_end],
            target=self.text[target_start:target_end],
            start=start, end=end, text_start=text_start, text_end=text_end,
            target_start=target_start, target_end=target_end,
        )

    @property
    def links(self) -> List[Link]:
        """Ссылки вне кода, по порядку в тексте; картинок среди них нет."""
        if self._links is None:
            self._parse_links()
        assert self._links is not None
        return self._links

    @property
    def images(self) -> List[Link]:
        """Картинки `![…](…)` вне кода."""
        if self._images is None:
            self._parse_links()
        assert self._images is not None
        return self._images

    @property
    def anchors(self) -> Set[str]:
        """Якоря `<a id="…"></a>` вне кода."""
        if self._anchors is None:
            self._anchors = set(_ANCHOR_RE.findall(self.masked))
        return self._anchors


def find_links(text: str, path: str = '') -> List[Link]:
    """Ссылки текста вне кода (без картинок)."""
    return Document(path, text).links


def find_anchors(text: str) -> Set[str]:
    """Якоря `<a id="…"></a>` текста вне кода."""
    return Document('', text).anchors


def strip_link_paths(text: str) -> str:
    """Убирает цели ссылок и картинок вне кода: `](…)` → `]()`.

    Картинки — тоже: при переносе файла в `obsolete/` их пути перебазируются
    так же, как пути ссылок.
    """
    doc = Document('', text)
    # Область `(…)` у каждой ссылки и картинки; у картинки в тексте ссылки
    # она внутри текста ссылки, так что области не пересекаются.
    regions = sorted((item.text_end + 1, item.end) for item in doc.links + doc.images)
    parts = []
    last = 0
    for start, end in regions:
        parts.append(text[last:start])
        parts.append('()')
        last = end
    parts.append(text[last:])
    return ''.join(parts)


# --------------------------------------------------------------------------
# Шапки похороненного и снимка PRD

_TOMB_FIELDS = ('Похоронен', 'Почему', 'Заменён')
_SNAPSHOT_FIELDS = ('Сменён', 'Почему', 'Вход')
_FIELD_RE = re.compile(r'> \*\*([^*]+):\*\* (.*)')


@dataclass(frozen=True)
class TombHeader:
    """Шапка похороненного артефакта.

    `size` — сколько строк срезать, чтобы получить исходный текст: строки
    шапки и пустая строка после них. `replaced_by` — видимый текст ссылки
    «Заменён» (id) или None, если «ничем»; `link` — сама ссылка.
    """

    date: str
    why: str
    replaced_by: Optional[str]
    link: Optional[Link]
    size: int
    error: Optional[str] = None


@dataclass(frozen=True)
class SnapshotHeader:
    """Шапка снимка PRD; `link` — ссылка «Вход»."""

    date: str
    why: str
    link: Optional[Link]
    size: int
    error: Optional[str] = None


def _header_block(text: str, first_field: str) -> Optional[Tuple[List[str], int]]:
    """Начальный блок строк `>` (если первая — `> **{first_field}:**`) и
    сколько строк срезать вместе с пустой строкой после блока."""
    if not text.startswith(f'> **{first_field}:**'):
        return None
    lines = text.split('\n')
    count = 0
    while count < len(lines) and lines[count].startswith('>'):
        count += 1
    size = count
    if count < len(lines) and lines[count].strip() == '':
        size += 1
    return lines[:count], size


@dataclass(frozen=True)
class _Header:
    values: Dict[str, str]
    link: Optional[Link]   # единственная ссылка, занимающая третье поле целиком
    size: int
    error: Optional[str]


def _parse_header(text: str, path: str, names: Tuple[str, str, str]) -> Optional[_Header]:
    block = _header_block(text, names[0])
    if block is None:
        return None
    lines, size = block
    values: Dict[str, str] = {}
    errors: List[str] = []
    if len(lines) != 3:
        errors.append(f'в шапке {len(lines)} строк вместо трёх')
    for index, line in enumerate(lines[:3]):
        match = _FIELD_RE.fullmatch(line)
        if match is None or match.group(1) != names[index]:
            errors.append(f'строка {index + 1} шапки — не `> **{names[index]}:** …`')
            continue
        values[names[index]] = match.group(2).strip()
    if size == len(lines) and len(lines) < len(text.split('\n')):
        errors.append('после шапки нет пустой строки')
    date = values.get(names[0], '')
    if names[0] in values and not valid_date(date):
        errors.append(f'дата {date} — не ГГГГ-ММ-ДД')
    link: Optional[Link] = None
    if len(lines) >= 3:
        # Ссылка третьего поля — со смещениями в тексте всего файла.
        third_start = len(lines[0]) + 1 + len(lines[1]) + 1
        field_start = third_start + len(f'> **{names[2]}:** ')
        field_end = third_start + len(lines[2])
        header_links = find_links('\n'.join(lines[:3]), path)
        whole = [item for item in header_links
                 if item.start == field_start and item.end == field_end]
        link = whole[0] if whole else None
    return _Header(values, link, size, errors[0] if errors else None)


def parse_tomb_header(text: str, path: str = '') -> Optional[TombHeader]:
    """Шапка похороненного в начале текста; нет — None."""
    header = _parse_header(text, path, _TOMB_FIELDS)
    if header is None:
        return None
    error = header.error
    replaced = header.values.get('Заменён')
    replaced_by: Optional[str] = None
    link: Optional[Link] = None
    if replaced is not None and replaced != 'ничем':
        if header.link is None:
            error = error or '«Заменён» — не `[ID](путь)` и не «ничем»'
        else:
            link = header.link
            replaced_by = link.text.strip()
    return TombHeader(
        date=header.values.get('Похоронен', ''),
        why=header.values.get('Почему', ''),
        replaced_by=replaced_by, link=link, size=header.size, error=error,
    )


def parse_snapshot_header(text: str, path: str = '') -> Optional[SnapshotHeader]:
    """Шапка снимка PRD в начале текста; нет — None."""
    header = _parse_header(text, path, _SNAPSHOT_FIELDS)
    if header is None:
        return None
    error = header.error
    if 'Вход' in header.values and header.link is None:
        error = error or '«Вход» — не `[путь](путь)`'
    return SnapshotHeader(
        date=header.values.get('Сменён', ''), why=header.values.get('Почему', ''),
        link=header.link, size=header.size, error=error,
    )


def strip_tomb_header(text: str) -> str:
    """Текст без шапки похороненного (если она есть, даже с ошибкой)."""
    block = _header_block(text, _TOMB_FIELDS[0])
    if block is None:
        return text
    _, size = block
    return '\n'.join(text.split('\n')[size:])


def frozen_form(text: str) -> str:
    """Текст для сравнения с базой: без шапки похороненного и путей ссылок."""
    return strip_link_paths(strip_tomb_header(text))


def _one_line(text: str) -> str:
    return ' '.join(text.split())


def format_tomb_header(date: str, why: str, replaced: Optional[Tuple[str, str]] = None) -> str:
    """Шапка похороненного, как её читает `parse_tomb_header`, с пустой
    строкой после неё. `replaced` — (id замены, цель ссылки из файла в
    `obsolete/`) или None — «ничем». `why` сводится в одну строку."""
    by = f'[{replaced[0]}]({replaced[1]})' if replaced else 'ничем'
    return (f'> **Похоронен:** {date}\n> **Почему:** {_one_line(why)}\n'
            f'> **Заменён:** {by}\n\n')


def format_snapshot_header(date: str, why: str, input_text: str, input_target: str) -> str:
    """Шапка снимка PRD, как её читает `parse_snapshot_header`, с пустой
    строкой после неё: «Вход» — ссылка `[input_text](input_target)`."""
    return (f'> **Сменён:** {date}\n> **Почему:** {_one_line(why)}\n'
            f'> **Вход:** [{input_text}]({input_target})\n\n')


# --------------------------------------------------------------------------
# Требования PRD

_REQ_CANDIDATE_RE = re.compile(
    r'\s*(?:[-*+][ \t]+|[0-9]+[.)][ \t]+)?(?:<a\s+id\s*=\s*["\']?r[0-9]|\*\*R[0-9])',
    re.IGNORECASE,
)
_REQ_START_RE = re.compile(rf'<a id="r({_N})"></a>\*\*R({_N})\.\*\*(?= |$)')
_REQ_NUMBERS_RE = re.compile(r'(?:id\s*=\s*["\']?r|\*\*R)([0-9]+)', re.IGNORECASE)
_MARK_RE = re.compile(
    r' \*\*Устарело ([0-9]{4}-[0-9]{2}-[0-9]{2}), заменено '
    r'(?:\[R([1-9][0-9]*)\]\(([^()\s]*)#r([1-9][0-9]*)\)|ничем)\.\*\*'
)
_MARK_LOOSE_RE = re.compile(r'^\s*\**\s*устарел|\*\*\s*устарел', re.IGNORECASE)


@dataclass(frozen=True)
class ObsoleteMark:
    """Отметка устаревания требования.

    `start`/`end` — смещения отметки (с ведущим пробелом) в первой строке.
    """

    date: str
    replaced_by: Optional[int]  # номер заменяющего требования; None — «ничем»
    start: int
    end: int


@dataclass(frozen=True)
class Requirement:
    """Требование `R{n}` в PRD: от строки с якорем до пустой строки,
    заголовка или следующего требования."""

    number: int
    path: str
    line: int
    end_line: int
    text: str
    mark: Optional[ObsoleteMark]

    @property
    def id(self) -> str:
        return f'R{self.number}'

    @property
    def anchor(self) -> str:
        return f'r{self.number}'

    @property
    def obsolete(self) -> bool:
        return self.mark is not None

    @property
    def replaced_by(self) -> Optional[int]:
        return self.mark.replaced_by if self.mark else None

    @property
    def body(self) -> str:
        """Текст без отметки устаревания."""
        if self.mark is None:
            return self.text
        return self.text[:self.mark.start] + self.text[self.mark.end:]


def is_requirement_candidate(line: str) -> bool:
    """Строка похожа на начало требования (см. docstring модуля)."""
    return bool(_REQ_CANDIDATE_RE.match(line))


def format_obsolete_mark(date: str, replaced_by: Optional[int] = None, target_path: str = '') -> str:
    """Отметка устаревания с ведущим пробелом, как её читает
    `parse_requirements`: ` **Устарело 2026-11-02, заменено [R12](#r12).**`
    или `… заменено ничем.**`. `target_path` — путь перед `#r{k}`, если
    заменяющее требование в другой части разбитого PRD ('' — тот же файл)."""
    if replaced_by is None:
        return f' **Устарело {date}, заменено ничем.**'
    return (f' **Устарело {date}, заменено '
            f'[R{replaced_by}]({target_path}#r{replaced_by}).**')


def mark_offset(requirement: Requirement) -> int:
    """Смещение в первой строке требования, куда ставится отметка: сразу
    после `**R{n}.**` (это же смещение в тексте файла от начала строки)."""
    match = _REQ_START_RE.match(requirement.text)
    assert match is not None, requirement.id
    return match.end()


def strip_obsolete_mark(line: str) -> str:
    """Строка требования без отметки устаревания; иная строка — как есть."""
    match = _REQ_START_RE.match(line)
    if match is None:
        return line
    mark = _MARK_RE.match(line, match.end())
    if mark is None:
        return line
    return line[:mark.start()] + line[mark.end():]


def _parse_mark(
    line: str, after_id: int, number: int, path: str, line_no: int,
    issues: List[Issue],
) -> Optional[ObsoleteMark]:
    """Отметка устаревания сразу после `**R{n}.**` (смещение `after_id`)."""
    match = _MARK_RE.match(line, after_id)
    if match is None:
        if _MARK_LOOSE_RE.search(line[after_id:]):
            issues.append(Issue(path, line_no,
                                f'отметка устаревания R{number} не по формату: '
                                'нужно сразу после id ` **Устарело ГГГГ-ММ-ДД, '
                                'заменено [R{k}](#r{k}).**` или '
                                '` **Устарело ГГГГ-ММ-ДД, заменено ничем.**`'))
        return None
    date = match.group(1)
    text_k, anchor_k = match.group(2), match.group(4)
    if not valid_date(date):
        issues.append(Issue(path, line_no,
                            f'отметка устаревания R{number} не по формату: '
                            f'дата {date} — не ГГГГ-ММ-ДД'))
        return None
    if text_k is not None and text_k != anchor_k:
        issues.append(Issue(path, line_no,
                            f'отметка устаревания R{number} не по формату: '
                            f'текст R{text_k}, а якорь #r{anchor_k}'))
        return None
    return ObsoleteMark(
        date=date, replaced_by=int(text_k) if text_k is not None else None,
        start=match.start(), end=match.end(),
    )


def parse_requirements(
    text: str, path: str
) -> Tuple[List[Requirement], List[Issue], Set[int]]:
    """Требования файла PRD, ошибки формата и все номера из строк-кандидатов
    (их учитывает `next R`). Повторы номера ловит `Repo` по всему PRD."""
    doc = Document(path, text)
    requirements: List[Requirement] = []
    issues: List[Issue] = []
    numbers: Set[int] = set()
    # Открытое требование: номер, первая строка, строки текста, отметка.
    open_number = 0
    open_line = 0
    open_lines: List[str] = []
    open_mark: Optional[ObsoleteMark] = None

    def close() -> None:
        nonlocal open_lines
        if open_lines:
            requirements.append(Requirement(
                number=open_number, path=path, line=open_line,
                end_line=open_line + len(open_lines) - 1,
                text='\n'.join(open_lines), mark=open_mark,
            ))
        open_lines = []

    for index, (line, masked_line) in enumerate(zip(doc.lines, doc.masked_lines)):
        line_no = index + 1
        candidate = is_requirement_candidate(masked_line)
        if open_lines:
            if (masked_line.strip() and not _HEADING_RE.match(masked_line)
                    and not candidate):
                open_lines.append(line)
                continue
            close()
        if not candidate:
            continue
        numbers.update(int(found) for found in _REQ_NUMBERS_RE.findall(masked_line))
        match = _REQ_START_RE.match(line)
        if match is None:
            issues.append(Issue(path, line_no,
                                'строка требования не по формату: нужно '
                                '`<a id="r{n}"></a>**R{n}.** …` в начале строки'))
            continue
        if match.group(1) != match.group(2):
            issues.append(Issue(path, line_no,
                                f'номер в якоре r{match.group(1)} и в тексте '
                                f'R{match.group(2)} разный'))
            continue
        open_number = int(match.group(1))
        open_line = line_no
        open_lines = [line]
        open_mark = _parse_mark(line, match.end(), open_number, path, line_no, issues)
    close()
    return requirements, issues, numbers


# --------------------------------------------------------------------------
# Пути UC

_PATH_CANDIDATE_RE = re.compile(r'<a\s+id\s*=\s*["\']?uc-|UC-[0-9]+-P-', re.IGNORECASE)
_PATH_RE = re.compile(
    r'### <a id="uc-([0-9]+)-p-([0-9]+)"></a>UC-([0-9]+)-P-([0-9]+) — (\S.*)'
)
_OUTCOME_CANDIDATE_RE = re.compile(r'\s*(?:\*\*\s*Исход|Исход\s*:)')
_OUTCOME_RE = re.compile(r'\*\*Исход:\*\* UC-([0-9]+)-O-([0-9]+) — (\S.*)')
_CANON_N_RE = re.compile(_N)
_CANON_NN_RE = re.compile(_NN)


@dataclass(frozen=True)
class UcPath:
    """Путь UC: заголовок `### <a id="uc-3-p-02"></a>UC-3-P-02 — имя` и его
    исход (если строка исхода одна и по формату)."""

    uc: int
    nn: str
    name: str
    line: int
    outcome_nn: Optional[str]
    outcome_name: Optional[str]
    outcome_line: Optional[int]

    @property
    def id(self) -> str:
        return f'UC-{self.uc}-P-{self.nn}'

    @property
    def anchor(self) -> str:
        return f'uc-{self.uc}-p-{self.nn}'

    @property
    def outcome_id(self) -> Optional[str]:
        return f'UC-{self.uc}-O-{self.outcome_nn}' if self.outcome_nn else None


class _PathSection:
    """Раздел пути UC при разборе: заголовок и найденные строки исхода."""

    def __init__(self, uc: int, nn: str, name: str, line: int) -> None:
        self.uc = uc
        self.nn = nn
        self.name = name
        self.line = line
        # Строки исхода: (nn, имя, строка) или None — строка с ошибкой.
        self.outcomes: List[Optional[Tuple[str, str, int]]] = []

    @property
    def id(self) -> str:
        return f'UC-{self.uc}-P-{self.nn}'

    def finish(self, path: str, issues: List[Issue]) -> UcPath:
        if not self.outcomes:
            issues.append(Issue(path, self.line, f'у пути {self.id} нет исхода'))
        elif len(self.outcomes) > 1:
            issues.append(Issue(path, self.line,
                                f'у пути {self.id} строк исхода {len(self.outcomes)} '
                                '— нужна одна'))
        outcome = self.outcomes[0] if len(self.outcomes) == 1 else None
        return UcPath(
            uc=self.uc, nn=self.nn, name=self.name, line=self.line,
            outcome_nn=outcome[0] if outcome else None,
            outcome_name=outcome[1] if outcome else None,
            outcome_line=outcome[2] if outcome else None,
        )


def _path_heading_issue(match: 're.Match[str]', uc_number: int, seen: Set[str]) -> Optional[str]:
    anchor_n, anchor_nn, text_n, text_nn, _ = match.groups()
    if (anchor_n, anchor_nn) != (text_n, text_nn):
        return (f'якорь uc-{anchor_n}-p-{anchor_nn} не совпадает с заголовком '
                f'UC-{text_n}-P-{text_nn}')
    if not _CANON_N_RE.fullmatch(text_n) or not _CANON_NN_RE.fullmatch(text_nn):
        return (f'номер пути UC-{text_n}-P-{text_nn} не по формату: n без ведущих '
                'нулей, nn — 01…99')
    if int(text_n) != uc_number:
        return f'путь UC-{text_n}-P-{text_nn} в файле UC-{uc_number}: номер UC не тот'
    if text_nn in seen:
        return f'путь UC-{text_n}-P-{text_nn} повторён'
    return None


def parse_uc_paths(
    text: str, path: str, uc_number: int
) -> Tuple[List[UcPath], List[Issue]]:
    """Пути файла UC с номером `uc_number` и ошибки их формата."""
    doc = Document(path, text)
    result: List[UcPath] = []
    issues: List[Issue] = []
    seen: Set[str] = set()
    section: Optional[_PathSection] = None
    # Раздел под заголовком пути с ошибкой: его исходы не разбираются.
    bad_section = False
    for index, (line, masked_line) in enumerate(zip(doc.lines, doc.masked_lines)):
        line_no = index + 1
        heading = _HEADING_RE.match(masked_line)
        if heading and len(heading.group(1)) <= 3:
            if section is not None:
                result.append(section.finish(path, issues))
            section = None
            bad_section = False
            if len(heading.group(1)) != 3 or not _PATH_CANDIDATE_RE.search(masked_line):
                continue
            match = _PATH_RE.fullmatch(line.rstrip())
            problem = (_path_heading_issue(match, uc_number, seen) if match
                       else 'заголовок пути не по формату: нужно '
                            '`### <a id="uc-{n}-p-{nn}"></a>UC-{n}-P-{nn} — <имя>`')
            if problem or match is None:
                issues.append(Issue(path, line_no, problem or ''))
                bad_section = True
                continue
            nn = match.group(4)
            seen.add(nn)
            section = _PathSection(uc_number, nn, match.group(5).strip(), line_no)
            continue
        if not _OUTCOME_CANDIDATE_RE.match(masked_line) or bad_section:
            continue
        if section is None:
            issues.append(Issue(path, line_no, 'исход вне раздела пути'))
            continue
        match = _OUTCOME_RE.fullmatch(line.strip())
        if match is None:
            issues.append(Issue(path, line_no,
                                'строка исхода не по формату: нужно '
                                '`**Исход:** UC-{n}-O-{nn} — <имя>`'))
            section.outcomes.append(None)
            continue
        out_n, out_nn, out_name = match.groups()
        if out_n != str(uc_number) or out_nn != section.nn:
            issues.append(Issue(path, line_no,
                                f'исход UC-{out_n}-O-{out_nn} не совпадает с путём '
                                f'{section.id}: номер исхода — номер пути'))
            section.outcomes.append(None)
            continue
        section.outcomes.append((out_nn, out_name.strip(), line_no))
    if section is not None:
        result.append(section.finish(path, issues))
    return result, issues


# --------------------------------------------------------------------------
# Вердикты, supersedes, названия

_LIST_PREFIX = r'(?:[-*+] |[0-9]+[.)] )?'
_ACC_VERDICT_RE = re.compile(rf'{_LIST_PREFIX}\*\*Вердикт:\*\* (принято|возврат)')
_MANUAL_VERDICT_RE = re.compile(rf'{_LIST_PREFIX}\*\*Вердикт:\*\* (PASS|FAIL|BLOCKED)')
_VERDICT_CANDIDATE_RE = re.compile(
    r'\s*(?:[-*+][ \t]+|[0-9]+[.)][ \t]+)?(?:\*\*\s*Вердикт|Вердикт\s*:)',
    re.IGNORECASE,
)


def _parse_verdict(
    text: str, path: str, pattern: 're.Pattern[str]', example: str
) -> Tuple[Optional[str], List[Issue]]:
    doc = Document(path, text)
    issues: List[Issue] = []
    found: List[Tuple[int, str]] = []
    candidates = 0
    for index, (line, masked_line) in enumerate(zip(doc.lines, doc.masked_lines)):
        if not _VERDICT_CANDIDATE_RE.match(masked_line):
            continue
        candidates += 1
        match = pattern.fullmatch(line.strip())
        if match is None:
            issues.append(Issue(path, index + 1,
                                f'строка вердикта не по формату: нужно {example}'))
            continue
        found.append((index + 1, match.group(1)))
    if candidates == 0:
        issues.append(Issue(path, 0, f'нет строки вердикта {example}'))
    if len(found) > 1:
        issues.append(Issue(path, found[1][0],
                            f'строк вердикта {len(found)} — нужна одна'))
        return None, issues
    return (found[0][1] if found else None), issues


def parse_acceptance_verdict(text: str, path: str = '') -> Tuple[Optional[str], List[Issue]]:
    """Вердикт приёмки (`принято`, `возврат`) и ошибки строки вердикта."""
    return _parse_verdict(text, path, _ACC_VERDICT_RE,
                          '`**Вердикт:** принято` или `**Вердикт:** возврат`')


def parse_manual_verdict(text: str, path: str = '') -> Tuple[Optional[str], List[Issue]]:
    """Вердикт прогона ручного кейса (`PASS`, `FAIL`, `BLOCKED`) из
    `transcript.md` и ошибки строки вердикта."""
    return _parse_verdict(text, path, _MANUAL_VERDICT_RE,
                          '`**Вердикт:** PASS` (или `FAIL`, `BLOCKED`)')


_SUPERSEDES_CANDIDATE_RE = re.compile(r'\s*supersedes\s*:', re.IGNORECASE)
_SUPERSEDES_PREFIX = 'supersedes: '


def parse_supersedes(text: str, path: str = '') -> Tuple[List[Link], List[Issue]]:
    """Ссылки строк `supersedes: [ID](путь)` и ошибки их формата."""
    doc = Document(path, text)
    result: List[Link] = []
    issues: List[Issue] = []
    for index, (line, masked_line) in enumerate(zip(doc.lines, doc.masked_lines)):
        if not _SUPERSEDES_CANDIDATE_RE.match(masked_line):
            continue
        line_no = index + 1
        line_start = doc.line_start(line_no)
        line_links = [link for link in doc.links if link.line == line_no
                      and link.end <= line_start + len(line)]
        ok = line.startswith(_SUPERSEDES_PREFIX) and bool(line_links)
        if ok:
            rest = list(line[len(_SUPERSEDES_PREFIX):])
            shift = line_start + len(_SUPERSEDES_PREFIX)
            for link in line_links:
                if link.start < shift:
                    ok = False
                    break
                for offset in range(link.start - shift, link.end - shift):
                    rest[offset] = ' '
            ok = ok and set(''.join(rest)) <= {' ', ',', '\t'}
        if not ok:
            issues.append(Issue(path, line_no,
                                'строка supersedes не по формату: нужно '
                                '`supersedes: [ID](путь)`'))
            continue
        result.extend(line_links)
    return result, issues


_TITLE_SEPARATORS = (':', '—', '–', '-')


def parse_title(text: str, artifact_id: str, fallback: str) -> str:
    """Название артефакта: первый заголовок `# …` без id в начале и
    разделителя после него; нет заголовка (или он — только id) — `fallback`."""
    doc = Document('', text)
    for line, masked_line in zip(doc.lines, doc.masked_lines):
        heading = _HEADING_RE.match(masked_line)
        if heading is None or len(heading.group(1)) != 1:
            continue
        content_match = _HEADING_RE.match(line)
        content = (content_match.group(2) or '') if content_match else ''
        content = content.strip()
        if content.startswith(artifact_id):
            after = content[len(artifact_id):]
            if not after or not re.match(r'[A-Za-z0-9-]', after[0]):
                rest = after.lstrip()
                if rest[:1] in _TITLE_SEPARATORS:
                    rest = rest[1:]
                content = rest.strip()
        return content or fallback
    return fallback


# --------------------------------------------------------------------------
# Метки в коде

_LABEL_RE = re.compile(
    r'(?<![^\W_])(?<!-)'
    r'(?:UC-([0-9]+)(?:-P-([0-9]+))?|(TOKEN|COMP)-([0-9]+))'
    r'(?![^\W_])(?!-)'
)


@dataclass(frozen=True)
class Label:
    """Метка в коде: голый id `UC-3`, `UC-3-P-02`, `TOKEN-1`, `COMP-2`."""

    path: str
    line: int
    id: str
    type: str          # 'UC', 'TOKEN', 'COMP'
    nn: Optional[str]  # у метки пути — {nn}

    @property
    def artifact_id(self) -> str:
        """Id артефакта метки, как записан: у `UC-3-P-02` — `UC-3`."""
        return self.id.split('-P-', 1)[0]

    @property
    def is_path(self) -> bool:
        return self.nn is not None


def find_labels(text: str, path: str = '') -> List[Label]:
    """Метки в тексте файла кода, по порядку."""
    result = []
    line_no = 1
    last = 0
    for match in _LABEL_RE.finditer(text):
        line_no += text.count('\n', last, match.start())
        last = match.start()
        if match.group(1) is not None:
            result.append(Label(path, line_no, match.group(0), 'UC', match.group(2)))
        else:
            result.append(Label(path, line_no, match.group(0), match.group(3), None))
    return result


# --------------------------------------------------------------------------
# Источник файлов рабочего дерева


class FsSource:
    """Источник файлов для `Repo`: рабочее дерево на диске.

    Существование пути проверяется с учётом регистра (по `os.listdir`).
    """

    def __init__(self, root: str) -> None:
        self.root = os.path.abspath(root)
        self._listings: Dict[str, Optional[Set[str]]] = {}

    def _abs(self, path: str) -> str:
        return os.path.join(self.root, *path.split('/')) if path else self.root

    def _listdir(self, directory: str) -> Optional[Set[str]]:
        if directory not in self._listings:
            try:
                self._listings[directory] = set(os.listdir(directory))
            except OSError:
                self._listings[directory] = None
        return self._listings[directory]

    def walk_sdlc(self) -> Tuple[List[str], List[str]]:
        """Файлы и папки под `sdlc/` (от корня), без скрытых, отсортированы.

        Папки — только те, где есть файлы (на любой глубине), как в git:
        пустая папка в рабочем дереве не меняет итог проверки.
        """
        base = self._abs(SDLC)
        files: List[str] = []
        if not os.path.isdir(base):
            return files, []
        for current, dir_names, file_names in os.walk(base):
            dir_names[:] = sorted(name for name in dir_names
                                  if not name.startswith('.'))
            rel = os.path.relpath(current, self.root).replace(os.sep, '/')
            for name in file_names:
                if not name.startswith('.'):
                    files.append(f'{rel}/{name}')
        dirs: Set[str] = {SDLC}
        for path in files:
            parent = path.rpartition('/')[0]
            while parent and parent not in dirs:
                dirs.add(parent)
                parent = parent.rpartition('/')[0]
        return sorted(files), sorted(dirs)

    def read(self, path: str) -> str:
        """Текст файла (UTF-8, переводы строк — `\\n`)."""
        with open(self._abs(path), encoding='utf-8', errors='replace') as handle:
            return handle.read()

    def exists(self, path: str) -> bool:
        if path in ('', '.'):
            return True
        current = self.root
        for part in path.split('/'):
            if part in ('', '.'):
                continue
            names = self._listdir(current)
            if names is None or part not in names:
                return False
            current = os.path.join(current, part)
        return True

    def is_dir(self, path: str) -> bool:
        return self.exists(path) and os.path.isdir(self._abs(path))

    def code_files(self) -> List[str]:
        """Файлы кода с метками (см. `gitbase.is_code_file`)."""
        try:
            candidates = gitbase.worktree_files(self.root, CODE_DIRS)
        except gitbase.GitError:
            candidates = []
            for top in CODE_DIRS:
                base = self._abs(top)
                for current, dir_names, file_names in os.walk(base):
                    rel = os.path.relpath(current, self.root).replace(os.sep, '/')
                    dir_names[:] = sorted(
                        name for name in dir_names
                        if not name.startswith('.')
                        and f'{rel}/{name}' not in SECRET_DIRS
                    )
                    for name in file_names:
                        if not name.startswith('.'):
                            candidates.append(f'{rel}/{name}')
        return sorted(path for path in candidates
                      if gitbase.is_code_file(path)
                      and not any(path.startswith(secret + '/')
                                  for secret in SECRET_DIRS))


# --------------------------------------------------------------------------
# Разрешение ссылок

EXTERNAL = 'external'
MISSING = 'missing'
ARTIFACT_LINK = 'artifact'
REQUIREMENT_LINK = 'requirement'
FILE_LINK = 'file'
DIR_LINK = 'dir'

_PATH_ANCHOR_RE = re.compile(r'uc-([0-9]+)-p-([0-9]+)')
_REQ_ANCHOR_RE = re.compile(rf'r({_N})')


@dataclass(frozen=True)
class Resolved:
    """Куда ведёт ссылка.

    `kind`: EXTERNAL, MISSING, ARTIFACT_LINK, REQUIREMENT_LINK, FILE_LINK,
    DIR_LINK. `path` — цель от корня без якоря. `target_id` — id, которым
    ссылка обязана называться: `UC-3`, `UC-3-P-02` (якорь пути в файле UC),
    `R7`. `anchor_ok` — якорь есть в файле (у ссылок на артефакт и требование;
    у прочих всегда True).
    """

    kind: str
    path: Optional[str]
    fragment: Optional[str]
    artifact: Optional[Artifact] = None
    requirement: Optional[int] = None
    target_id: Optional[str] = None
    anchor_ok: bool = True


# --------------------------------------------------------------------------
# Прогоны


@dataclass(frozen=True)
class ManualRun:
    """Прогон ручного кейса: `6-eval/manual/<дата>/TC-{n}/transcript.md`."""

    date: str
    tc: str
    path: str
    verdict: Optional[str]
    issues: Tuple[Issue, ...]


@dataclass(frozen=True)
class AutoRun:
    """Машинный прогон: папка `6-eval/auto/<имя>/` с `summary.json`.

    `summary` — разобранный JSON (None, если не читается; причина — `error`).
    """

    name: str
    dir: str
    summary: Optional[dict]
    error: Optional[str]


# --------------------------------------------------------------------------
# Дерево


class Repo:
    """Дерево конвейера поверх источника файлов (рабочее дерево или коммит).

    Конструктор читает список файлов и имена артефактов; тексты, ссылки,
    требования, пути UC и метки разбираются при первом обращении.
    """

    def __init__(self, source: Union[FsSource, 'gitbase.GitSource']) -> None:
        self.source = source
        self.root: str = source.root
        files, dirs = source.walk_sdlc()
        self.files: List[str] = list(files)
        self.file_set: Set[str] = set(files)
        self.dirs: List[str] = list(dirs)
        self.md_files: List[str] = [path for path in files if path.endswith('.md')]
        self.structure_dirs: List[str] = [
            path for path in dirs if classify_dir(path) == STRUCTURE]
        self.content_dirs: List[str] = [
            path for path in dirs if classify_dir(path) == CONTENT]
        self.artifacts: List[Artifact] = []
        self.name_issues: List[Issue] = []
        self._scan_names()
        self.artifacts.sort(key=lambda item: item.sort_key)
        self._by_path: Dict[str, Artifact] = {item.path: item for item in self.artifacts}
        self._by_id: Dict[str, List[Artifact]] = {}
        for item in self.artifacts:
            self._by_id.setdefault(item.id, []).append(item)
        split = [path for path in files
                 if posixpath.dirname(path) == PRD_SPLIT_DIR and path.endswith('.md')]
        if split:
            self.prd_files: List[str] = sorted(split)
        elif PRD_PATH in self.file_set:
            self.prd_files = [PRD_PATH]
        else:
            self.prd_files = []
        self.snapshots: List[str] = sorted(
            path for path in files
            if posixpath.dirname(path) == HISTORY_DIR
            and is_snapshot_name(posixpath.basename(path)))
        self._docs: Dict[str, Document] = {}
        self._requirements: Optional[List[Requirement]] = None
        self._requirement_by_number: Dict[int, Requirement] = {}
        self._requirement_issues: List[Issue] = []
        self._requirement_numbers: Set[int] = set()
        self._uc_cache: Dict[str, Tuple[List[UcPath], List[Issue]]] = {}
        self._supersedes: Dict[str, Tuple[List[Link], List[Issue]]] = {}
        self._verdicts: Dict[str, Tuple[Optional[str], List[Issue]]] = {}
        self._labels: Optional[List[Label]] = None
        self._code_files: Optional[List[str]] = None

    # -- имена и места -----------------------------------------------------

    def _scan_names(self) -> None:
        for path in self.md_files:
            directory = posixpath.dirname(path)
            filename = posixpath.basename(path)
            home, buried = artifact_home(directory)
            if home is not None and (filename in CONVENTION_FILES
                                     or filename == INDEX_NAME):
                continue
            if directory == HISTORY_DIR:
                if (filename not in CONVENTION_FILES and filename != INDEX_NAME
                        and not is_snapshot_name(filename)):
                    self.name_issues.append(Issue(
                        path, 0, 'в history/ — только снимки PRD-ГГГГ-ММ-ДД.md '
                        'и PRD-ГГГГ-ММ-ДД-{NN}.md'))
                continue
            parsed, reason = parse_artifact_name(filename)
            if parsed is None:
                if home is not None:
                    self.name_issues.append(Issue(
                        path, 0, f'файл в папке артефактов не по грамматике имени: {reason}'))
                elif looks_like_artifact_name(filename):
                    self.name_issues.append(Issue(
                        path, 0, 'имя похоже на id артефакта, а файл не в папке '
                        f'артефактов и не по грамматике: {reason}'))
                continue
            problem: Optional[str] = None
            if home is None:
                parent, _, last = sdlc_rel(directory).rpartition('/')
                buried = last == OBSOLETE
                folder = parent if buried else sdlc_rel(directory)
                problem = _misplaced_text(parsed)
            else:
                folder = home
                if parsed.type not in ARTIFACT_FOLDERS[home]:
                    problem = _misplaced_text(parsed)
                elif parsed.type == 'BT' and parsed.bt_type != BT_FOLDER_TYPES[home]:
                    problem = (f'у бизнес-задачи тип {parsed.bt_type}, а папка '
                               f'{home}/ — для {BT_FOLDER_TYPES[home]}')
            if problem:
                self.name_issues.append(Issue(path, 0, problem))
            misplaced = problem is not None
            self.artifacts.append(Artifact(
                id=parsed.id, type=parsed.type, number=parsed.number, nn=parsed.nn,
                name=parsed.name, bt_type=parsed.bt_type, module=parsed.module,
                uc_refs=parsed.uc_refs, path=path, folder=folder, buried=buried,
                misplaced=misplaced,
            ))

    @property
    def has_sdlc(self) -> bool:
        return SDLC in self.dirs

    def artifact_at(self, path: str) -> Optional[Artifact]:
        """Артефакт по пути файла."""
        return self._by_path.get(path)

    def by_id(self, artifact_id: str) -> List[Artifact]:
        """Все файлы с этим id (больше одного — ошибка 2)."""
        return list(self._by_id.get(artifact_id, []))

    def get(self, artifact_id: str) -> Optional[Artifact]:
        """Артефакт по id: если файлов несколько — лежащий на месте, живой."""
        found = self._by_id.get(artifact_id)
        if not found:
            return None
        return sorted(found, key=lambda item: (item.misplaced, item.buried, item.path))[0]

    def ids(self) -> Set[str]:
        """Все id артефактов-файлов дерева."""
        return set(self._by_id)

    def of_type(self, kind: str, live: Optional[bool] = None) -> List[Artifact]:
        """Артефакты типа `kind`; `live=True` — только живые, False — похороненные."""
        return [item for item in self.artifacts if item.type == kind
                and (live is None or item.live == live)]

    def artifacts_in(self, folder: str) -> List[Artifact]:
        """Артефакты папки `folder` (от `sdlc/`), живые и похороненные, лежащие
        на месте, по порядку производных файлов."""
        return [item for item in self.artifacts
                if item.folder == folder and not item.misplaced]

    # -- файлы ----------------------------------------------------------------

    def exists(self, path: str) -> bool:
        return self.source.exists(path)

    def is_dir(self, path: str) -> bool:
        return self.source.is_dir(path)

    def text(self, path: str) -> str:
        return self.doc(path).text

    def doc(self, path: str) -> Document:
        """Разобранный файл (кэш)."""
        if path not in self._docs:
            self._docs[path] = Document(path, self.source.read(path))
        return self._docs[path]

    def link_checked_files(self) -> List[str]:
        """`.md`, чьи ссылки проверяются (см. `is_link_checked`)."""
        return [path for path in self.md_files if is_link_checked(path)]

    # -- PRD --------------------------------------------------------------------

    def _parse_prd(self) -> None:
        if self._requirements is not None:
            return
        requirements: List[Requirement] = []
        issues: List[Issue] = []
        numbers: Set[int] = set()
        for path in self.prd_files:
            found, found_issues, found_numbers = parse_requirements(self.text(path), path)
            requirements += found
            issues += found_issues
            numbers |= found_numbers
        seen: Dict[int, Requirement] = {}
        unique: List[Requirement] = []
        for requirement in requirements:
            if requirement.number in seen:
                first = seen[requirement.number]
                issues.append(Issue(requirement.path, requirement.line,
                                    f'номер R{requirement.number} повторён: уже в '
                                    f'{first.path}:{first.line}'))
                continue
            seen[requirement.number] = requirement
            unique.append(requirement)
        for requirement in unique:
            target = requirement.replaced_by
            if target is not None and target not in seen:
                issues.append(Issue(requirement.path, requirement.line,
                                    f'R{requirement.number} заменено R{target}, '
                                    'а такого требования нет'))
        self._requirements = unique
        self._requirement_by_number = seen
        self._requirement_issues = issues
        self._requirement_numbers = numbers | set(seen)

    @property
    def requirements(self) -> List[Requirement]:
        """Требования PRD (без повторов номера), по файлам и строкам."""
        self._parse_prd()
        assert self._requirements is not None
        return self._requirements

    @property
    def requirement_issues(self) -> List[Issue]:
        """Ошибки требований (проверка 4)."""
        self._parse_prd()
        return self._requirement_issues

    @property
    def requirement_numbers(self) -> Set[int]:
        """Все номера, встреченные в строках требований (для `next R`)."""
        self._parse_prd()
        return self._requirement_numbers

    def requirement(self, number: int) -> Optional[Requirement]:
        """Требование по номеру; нет — None."""
        self._parse_prd()
        return self._requirement_by_number.get(number)

    # -- UC ------------------------------------------------------------------

    def _uc(self, artifact: Artifact) -> Tuple[List[UcPath], List[Issue]]:
        if artifact.path not in self._uc_cache:
            self._uc_cache[artifact.path] = parse_uc_paths(
                self.text(artifact.path), artifact.path, artifact.number)
        return self._uc_cache[artifact.path]

    def uc_paths(self, artifact: Artifact) -> List[UcPath]:
        """Пути UC (без заголовков с ошибкой), по порядку в файле."""
        return self._uc(artifact)[0]

    def uc_path_issues(self, artifact: Artifact) -> List[Issue]:
        """Ошибки путей UC (проверка 5)."""
        return self._uc(artifact)[1]

    def find_uc_path(self, path_id: str) -> Optional[Tuple[Artifact, UcPath]]:
        """Путь UC по id `UC-3-P-02` (в живом или похороненном UC)."""
        ref = parse_id(path_id)
        if ref is None or ref.part != 'P':
            return None
        artifact = self.get(f'UC-{ref.number}')
        if artifact is None:
            return None
        for uc_path in self.uc_paths(artifact):
            if uc_path.nn == ref.nn:
                return artifact, uc_path
        return None

    # -- строки артефактов -----------------------------------------------------

    def title(self, artifact: Artifact) -> str:
        """Название артефакта (см. `parse_title`)."""
        return parse_title(self.text(artifact.path), artifact.id, artifact.name)

    def tomb_header(self, artifact: Artifact) -> Optional[TombHeader]:
        """Шапка похороненного в начале файла; нет — None."""
        return parse_tomb_header(self.text(artifact.path), artifact.path)

    def _supersedes_parsed(self, artifact: Artifact) -> Tuple[List[Link], List[Issue]]:
        if artifact.path not in self._supersedes:
            doc = self.doc(artifact.path)
            links, issues = parse_supersedes(doc.text, artifact.path)
            self._supersedes[artifact.path] = (links, issues)
        return self._supersedes[artifact.path]

    def supersedes(self, artifact: Artifact) -> List[Link]:
        """Ссылки строк `supersedes:` артефакта."""
        return self._supersedes_parsed(artifact)[0]

    def supersedes_issues(self, artifact: Artifact) -> List[Issue]:
        return self._supersedes_parsed(artifact)[1]

    def _verdict(self, artifact: Artifact) -> Tuple[Optional[str], List[Issue]]:
        if artifact.path not in self._verdicts:
            self._verdicts[artifact.path] = parse_acceptance_verdict(
                self.text(artifact.path), artifact.path)
        return self._verdicts[artifact.path]

    def verdict(self, artifact: Artifact) -> Optional[str]:
        """Вердикт приёмки ACC: `принято`, `возврат` или None."""
        return self._verdict(artifact)[0]

    def verdict_issues(self, artifact: Artifact) -> List[Issue]:
        """Ошибки строки вердикта приёмки (проверка 8)."""
        return self._verdict(artifact)[1]

    # -- ссылки ---------------------------------------------------------------

    def resolve(self, link: Link) -> Resolved:
        """Куда ведёт ссылка (см. `Resolved`)."""
        if link.is_external:
            return Resolved(EXTERNAL, None, None)
        raw_path, fragment = link.split_target()
        if raw_path == '':
            target = link.path
        elif raw_path.startswith('/'):
            target = posixpath.normpath(raw_path.lstrip('/') or '.')
        else:
            target = posixpath.normpath(
                posixpath.join(posixpath.dirname(link.path), raw_path))
        if target == '.':
            target = ''
        if target == '..' or target.startswith('../') or not self.source.exists(target):
            return Resolved(MISSING, target, fragment)
        artifact = self._by_path.get(target)
        if artifact is not None:
            target_id = artifact.id
            if fragment and artifact.type == 'UC':
                match = _PATH_ANCHOR_RE.fullmatch(fragment)
                if match:
                    target_id = f'UC-{match.group(1)}-P-{match.group(2)}'
            anchor_ok = fragment is None or fragment in self.doc(target).anchors
            return Resolved(ARTIFACT_LINK, target, fragment, artifact=artifact,
                            target_id=target_id, anchor_ok=anchor_ok)
        if target in self.prd_files and fragment is not None:
            match = _REQ_ANCHOR_RE.fullmatch(fragment)
            if match:
                number = int(match.group(1))
                return Resolved(REQUIREMENT_LINK, target, fragment,
                                requirement=number, target_id=f'R{number}',
                                anchor_ok=fragment in self.doc(target).anchors)
        kind = DIR_LINK if self.source.is_dir(target) else FILE_LINK
        return Resolved(kind, target, fragment)

    def outgoing(self, path: str) -> List[Tuple[Link, Resolved]]:
        """Ссылки файла на артефакты и требования по порядку, без ссылок
        шапки похороненного («Заменён» — ссылка вперёд)."""
        doc = self.doc(path)
        header = parse_tomb_header(doc.text, path)
        skip = header.size if header else 0
        result = []
        for link in doc.links:
            if link.line <= skip:
                continue
            resolved = self.resolve(link)
            if resolved.kind in (ARTIFACT_LINK, REQUIREMENT_LINK):
                result.append((link, resolved))
        return result

    def is_stale(self, resolved: Resolved) -> bool:
        """Ссылка ведёт на похороненный артефакт или устаревшее требование."""
        if resolved.kind == ARTIFACT_LINK:
            return resolved.artifact is not None and resolved.artifact.buried
        if resolved.kind == REQUIREMENT_LINK and resolved.requirement is not None:
            requirement = self.requirement(resolved.requirement)
            return requirement is not None and requirement.obsolete
        return False

    def stale_links(self, artifact: Artifact) -> List[Tuple[Link, Resolved]]:
        """Ссылки артефакта на похороненное и устаревшее («к пересмотру»), без
        строк `supersedes:` и шапки похороненного."""
        supersedes_lines = {link.line for link in self.supersedes(artifact)}
        return [(link, resolved) for link, resolved in self.outgoing(artifact.path)
                if link.line not in supersedes_lines and self.is_stale(resolved)]

    # -- метки ------------------------------------------------------------------

    def code_files(self) -> List[str]:
        """Файлы кода, где ищутся метки."""
        if self._code_files is None:
            self._code_files = list(self.source.code_files())
        return self._code_files

    def theme_files(self) -> List[str]:
        """Файлы темы `lib/app/theme/*.dart`."""
        return [path for path in self.code_files()
                if posixpath.dirname(path) == THEME_DIR and path.endswith('.dart')]

    def labels(self) -> List[Label]:
        """Метки во всех файлах кода, по файлам и строкам."""
        if self._labels is None:
            result: List[Label] = []
            for path in self.code_files():
                result += find_labels(self.source.read(path), path)
            self._labels = result
        return self._labels

    def label_target(self, label: Label) -> Optional[Artifact]:
        """Артефакт метки (у метки пути — UC, если в нём есть этот путь)."""
        artifact = self.get(label.artifact_id)
        if artifact is None or artifact.type != label.type:
            return None
        if label.is_path:
            if all(uc_path.nn != label.nn for uc_path in self.uc_paths(artifact)):
                return None
        return artifact

    # -- прогоны -----------------------------------------------------------------

    def manual_runs(self) -> List[ManualRun]:
        """Прогоны ручных кейсов, по кейсу (номеру) и дате."""
        runs = []
        prefix = MANUAL_DIR + '/'
        for path in self.files:
            if not path.startswith(prefix):
                continue
            parts = path[len(prefix):].split('/')
            if (len(parts) == 3 and is_date(parts[0])
                    and re.fullmatch(rf'TC-{_N}', parts[1])
                    and parts[2] == 'transcript.md'):
                verdict, issues = parse_manual_verdict(self.text(path), path)
                runs.append(ManualRun(parts[0], parts[1], path, verdict, tuple(issues)))
        runs.sort(key=lambda run: (int(run.tc[3:]), run.date, run.path))
        return runs

    def auto_runs(self) -> List[AutoRun]:
        """Машинные прогоны (папки `6-eval/auto/*/` с `summary.json`), по имени."""
        runs = []
        prefix = AUTO_DIR + '/'
        for path in self.files:
            if not path.startswith(prefix):
                continue
            parts = path[len(prefix):].split('/')
            if len(parts) != 2 or parts[1] != 'summary.json':
                continue
            summary: Optional[dict] = None
            error: Optional[str] = None
            try:
                data = json.loads(self.source.read(path))
                if isinstance(data, dict):
                    summary = data
                else:
                    error = 'summary.json — не объект JSON'
            except ValueError as problem:
                error = f'summary.json не читается: {problem}'
            runs.append(AutoRun(parts[0], posixpath.dirname(path), summary, error))
        runs.sort(key=lambda run: run.name)
        return runs


def load_repo(root: str) -> Repo:
    """Дерево рабочей копии в корне `root`."""
    return Repo(FsSource(root))


def load_base(root: str, ref: str) -> Repo:
    """Дерево коммита `ref` (gitbase.GitError, если коммита нет)."""
    return Repo(gitbase.GitSource(root, ref))


def first_difference(old: Sequence[str], new: Sequence[str]) -> int:
    """Индекс первой различающейся строки двух списков (или длина меньшего)."""
    for index, (left, right) in enumerate(zip(old, new)):
        if left != right:
            return index
    return min(len(old), len(new))
