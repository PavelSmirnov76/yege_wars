"""Производные файлы: `INDEX.md` в папках артефактов и `6-eval/DASHBOARD.md`.

Форматы — README скрипта, «Производные файлы». Данные — из `model.Repo`,
пути ссылок — `model.rel_link` от папки производного файла. `render_all`
только читает дерево, `write_all` приводит к его результату файлы на диске.
Порядок строк — по id, внутри ячейки «Ссылается на» — по первому появлению;
дат сборки нет, поэтому вывод зависит только от дерева.

Как прочитаны места, где спецификация допускает разное:

- В основной таблице индекса — живые артефакты папки, похороненные — только в
  «Похоронены». «К пересмотру» — живые со ссылками на похороненное и
  устаревшее (`Repo.stale_links`, как предупреждение `check`).
- Ссылка на артефакт — его id без якоря; на путь UC и требование — с якорем.
  Если якоря нет (нет такого пути или требования), пишется id без ссылки:
  ошибку покажет `check` у источника, производный файл её не повторяет.
- В названии ссылки и картинки заменяются их текстом: их пути — от файла
  артефакта, в индексе (особенно у похороненного) они бы не разрешились.
  `|` в ячейках экранируется.
- Пустая ячейка — «—». «Где реализован» без меток — «не покрыто» (закон, «Код
  ссылается на артефакты»); файлы в ней — ссылками, по пути.
- UC бизнес-задачи планирования — живые UC со ссылкой на её файл; UC без
  путей — непроверенный. Причины «нет — …» идут в порядке FAIL, BLOCKED,
  не проверено и разделяются `; `; пути и UC в них — ссылками.
- «Проверено k из m» — пути с любым вердиктом сводки (`PASS`, `FAIL`,
  `BLOCKED`); остальные m − k — «НЕ ПРОВЕРЕНО».
- «Пути UC» задания — ссылки на пути UC в блоке основания: в абзаце, который
  начинается с `**Основание` или `Основание:` (до пустой строки или
  заголовка), или в разделе под заголовком «Основание». Блока нет — «—».
- Сдачи и приёмки в колонках `4-tasks/` и `5-results/` — только живые.
  «Закрыто» — `да`, если у живой приёмки с наибольшим `{NN}` вердикт
  «принято», иначе `нет`. Приёмка без читаемого вердикта — «нет вердикта».
- Прогон ручного кейса — раунд с последней датой. Если его вердикт не
  читается — «нет вердикта», и в сводку этот кейс вердикта не даёт.
- Последний машинный прогон — среди папок с читаемым `summary.json` и без
  проверок, пропущенных через `--skip` (вердикт null в `checks`): по
  `started_at` (ISO 8601; `Z` и время без пояса — UTC; не разбирается —
  раньше любого разобранного), затем по имени папки. Вердикт пути в нём —
  худший из тестов с этой меткой (`tests[].label` — строка или список) и
  записи `paths` (на случай меток, которых нет в `tests`, например SQL).
  Дата прогона — `date` из `summary.json`, иначе дата из имени папки.
- Вердикт пути — из машинного прогона и последнего раунда каждого живого
  кейса со ссылкой на путь: самый поздний по дате, при равной дате худший,
  при полном равенстве — машинный, затем кейс с меньшим номером. Источник —
  `auto <папка прогона>` или `manual <дата> [TC-n](…)`.
- Сводка: UC без путей — строка «НЕ ПРОВЕРЕНО: нет путей»; «Итого путей»
  считает разные пути таблицы. Ссылка на прогон — на его `summary.md`, а
  если его нет — на папку.
- `write_all` сравнивает файлы так же, как `check`: текст UTF-8, переводы
  строк приведены к `\\n`. Удаляет и `INDEX.md` вне папок артефактов (в
  `obsolete/`, в папках дат): имя занято производным файлом, `check` считает
  такие лишними. Если файловая система не различает регистр и рядом лежит то
  же имя в другом регистре (`index.md`), запись затёрла бы его — тогда отказ,
  и ничего не пишется.
"""

from __future__ import annotations

import datetime
import os
import posixpath
import re
from dataclasses import dataclass
from typing import Callable, Dict, Iterable, List, Optional, Sequence, Set, Tuple

from . import model

EMPTY = '—'
NOT_COVERED = 'не покрыто'
NOT_CHECKED = 'НЕ ПРОВЕРЕНО'
NO_VERDICT = 'нет вердикта'
NONE_YET = 'нет'
YES = 'да'
NOTHING = 'ничем'
ACCEPTED = 'принято'

PASS, FAIL, BLOCKED = 'PASS', 'FAIL', 'BLOCKED'
# Тяжесть вердикта: при равной дате берётся худший.
_SEVERITY: Dict[str, int] = {PASS: 1, BLOCKED: 2, FAIL: 3}
AUTO, MANUAL = 'auto', 'manual'

PLANNING_FOLDER = '1-business-tasks/planning'
USE_CASES_FOLDER = '2-specs/use-cases'
DESIGN_SYSTEM_FOLDER = '3-design/design-system'
TASKS_FOLDER = '4-tasks'
RESULTS_FOLDER = '5-results'
ACCEPTANCE_FOLDER = '6-eval/acceptance'
MANUAL_FOLDER = '6-eval/manual'

_BASIS_HEADING_RE = re.compile(r'[ \t]{0,3}(#{1,6})[ \t]+(?:\*\*)?[ \t]*Основание\b')
_BASIS_LINE_RE = re.compile(
    r'[ \t]*(?:[-*+][ \t]+)?(?:\*\*[ \t]*Основание\b|Основание[ \t]*:)')
_HEADING_LINE_RE = re.compile(r'[ \t]{0,3}(#{1,6})(?:[ \t]|$)')


# --------------------------------------------------------------------------
# Ячейки и ссылки


def _escape(text: str) -> str:
    """Текст для ячейки таблицы: `|` разорвал бы строку."""
    return text.replace('|', '\\|')


def _plain(text: str) -> str:
    """Текст без ссылок и картинок: `[текст](цель)` → `текст`."""
    while True:
        doc = model.Document('', text)
        spans = [(item.start, item.end, item.text) for item in doc.links]
        spans += [(item.start, item.end, item.text) for item in doc.images
                  if not any(outer.start <= item.start and item.end <= outer.end
                             for outer in doc.links)]
        if not spans:
            return text
        for start, end, inner in sorted(spans, reverse=True):
            text = text[:start] + inner + text[end:]


def _target(from_file: str, to_path: str, fragment: Optional[str] = None,
            is_dir: bool = False) -> str:
    # `|` в цели разорвал бы ячейку; `%7C` при разрешении раскодируется.
    return model.rel_link(from_file, to_path, fragment, is_dir).replace('|', '%7C')


def _link(from_file: str, text: str, to_path: str, fragment: Optional[str] = None,
          is_dir: bool = False) -> str:
    return f'[{text}]({_target(from_file, to_path, fragment, is_dir)})'


def _artifact_link(from_file: str, artifact: model.Artifact) -> str:
    return _link(from_file, artifact.id, artifact.path)


def _path_link(from_file: str, uc: model.Artifact, uc_path: model.UcPath) -> str:
    return _link(from_file, uc_path.id, uc.path, uc_path.anchor)


def _requirement_link(from_file: str, requirement: model.Requirement) -> str:
    return _link(from_file, requirement.id, requirement.path, requirement.anchor)


def _file_link(from_file: str, path: str) -> str:
    return _link(from_file, f'`{_escape(path)}`', path)


def _is_path_ref(resolved: model.Resolved) -> bool:
    """Ссылка ведёт на путь UC (`UC-3-P-02`), а не на артефакт целиком."""
    return (resolved.kind == model.ARTIFACT_LINK and resolved.artifact is not None
            and resolved.target_id != resolved.artifact.id)


def _ref(from_file: str, resolved: model.Resolved) -> str:
    """Id ссылкой из `from_file`; якорь — только у пути UC и требования."""
    target_id = resolved.target_id or ''
    keeps_anchor = resolved.kind == model.REQUIREMENT_LINK or _is_path_ref(resolved)
    if keeps_anchor and not resolved.anchor_ok:
        return target_id
    fragment = resolved.fragment if keeps_anchor else None
    return _link(from_file, target_id, resolved.path or '', fragment)


def _unique(items: Iterable[model.Resolved]) -> List[model.Resolved]:
    """Без повторов id, в порядке первого появления."""
    seen: Set[str] = set()
    result = []
    for resolved in items:
        key = resolved.target_id or ''
        if key not in seen:
            seen.add(key)
            result.append(resolved)
    return result


def _refs_cell(from_file: str, refs: Sequence[model.Resolved]) -> str:
    return ', '.join(_ref(from_file, resolved) for resolved in refs) or EMPTY


def _table(headers: Sequence[str], rows: Sequence[Sequence[str]]) -> List[str]:
    lines = ['| ' + ' | '.join(headers) + ' |', '|' + '---|' * len(headers)]
    lines += ['| ' + ' | '.join(row) + ' |' for row in rows]
    return lines


def _title(repo: model.Repo, artifact: model.Artifact) -> str:
    title = _plain(repo.title(artifact)).strip()
    return _escape(title) if title else EMPTY


# --------------------------------------------------------------------------
# Машинные прогоны


def _instant(value: object) -> Optional[float]:
    """Момент `started_at` в секундах UTC; не ISO 8601 — None."""
    if not isinstance(value, str):
        return None
    text = value.strip()
    if text[-1:] in ('Z', 'z'):
        text = text[:-1] + '+00:00'
    try:
        moment = datetime.datetime.fromisoformat(text)
    except ValueError:
        return None
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=datetime.timezone.utc)
    return moment.timestamp()


def _run_order(run: model.AutoRun) -> Tuple[int, float, str]:
    instant = _instant((run.summary or {}).get('started_at'))
    return (0, 0.0, run.name) if instant is None else (1, instant, run.name)


def _is_partial(run: model.AutoRun) -> bool:
    """Прогон с проверками, пропущенными через `--skip` (вердикт null)."""
    checks = (run.summary or {}).get('checks')
    if not isinstance(checks, list):
        return False
    return any(isinstance(check, dict) and check.get('verdict') is None
               for check in checks)


def latest_auto_run(repo: model.Repo) -> Optional[model.AutoRun]:
    """Последний полный машинный прогон с читаемым `summary.json`; нет — None.

    Частичный прогон (`--skip`) остаётся доказательством в своей папке, но
    сводку не задаёт: иначе прогон одних тестов Python стёр бы вердикты всех
    путей, которые проверяют тесты Flutter.
    """
    runs = [run for run in repo.auto_runs()
            if run.summary is not None and not _is_partial(run)]
    return max(runs, key=_run_order) if runs else None


def _run_date(run: model.AutoRun) -> str:
    """Дата машинного прогона для сравнения с ручным раундом."""
    summary = run.summary or {}
    for value in (summary.get('date'), run.name[:10], summary.get('started_at')):
        if isinstance(value, str) and model.valid_date(value[:10]):
            return value[:10]
    return ''


def _labels_of(value: object) -> List[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, (list, tuple)):
        return [item for item in value if isinstance(item, str)]
    return []


def auto_verdicts(summary: dict) -> Dict[str, str]:
    """Метка пути → вердикт прогона: худший из тестов с меткой и `paths`."""
    found: Dict[str, List[str]] = {}
    tests = summary.get('tests')
    for test in (tests if isinstance(tests, list) else []):
        if isinstance(test, dict) and test.get('verdict') in _SEVERITY:
            for label in _labels_of(test.get('label')):
                found.setdefault(label, []).append(test['verdict'])
    paths = summary.get('paths')
    for label, verdict in (paths.items() if isinstance(paths, dict) else []):
        if isinstance(label, str) and verdict in _SEVERITY:
            found.setdefault(label, []).append(verdict)
    return {label: max(verdicts, key=_SEVERITY.__getitem__)
            for label, verdicts in found.items()}


# --------------------------------------------------------------------------
# Вердикты путей


@dataclass(frozen=True)
class _Verdict:
    """Вердикт пути и прогон, который его дал."""

    verdict: str
    date: str
    kind: str                               # AUTO или MANUAL
    run: str                                # папка машинного прогона или дата раунда
    case: Optional[model.Artifact] = None   # у ручного — кейс TC

    @property
    def rank(self) -> Tuple[str, int, bool, int]:
        """Больше — главнее: позже, хуже, машинный, кейс с меньшим номером."""
        return (self.date, _SEVERITY[self.verdict], self.kind == AUTO,
                -(self.case.number if self.case is not None else 0))


def _case_paths(repo: model.Repo, case: model.Artifact) -> List[model.Resolved]:
    """Пути UC, на которые ссылается файл артефакта, без повторов."""
    return _unique(resolved for _, resolved in repo.outgoing(case.path)
                   if _is_path_ref(resolved))


class _Views:
    """Данные, общие для производных файлов одного дерева (считаются лениво)."""

    def __init__(self, repo: model.Repo) -> None:
        self.repo = repo
        self._live_ucs: Optional[List[model.Artifact]] = None
        self._uc_links: Dict[str, List[model.Resolved]] = {}
        self._label_files: Optional[Dict[str, List[str]]] = None
        self._auto: Optional[Tuple[Optional[model.AutoRun], Dict[str, str]]] = None
        self._rounds: Optional[Dict[str, model.ManualRun]] = None
        self._manual: Optional[Dict[str, List[_Verdict]]] = None
        self._verdicts: Dict[str, Optional[_Verdict]] = {}

    # -- UC ------------------------------------------------------------------

    @property
    def live_ucs(self) -> List[model.Artifact]:
        if self._live_ucs is None:
            self._live_ucs = self.repo.of_type('UC', live=True)
        return self._live_ucs

    def _links_of(self, uc: model.Artifact) -> List[model.Resolved]:
        if uc.path not in self._uc_links:
            self._uc_links[uc.path] = [resolved for _, resolved in self.repo.outgoing(uc.path)]
        return self._uc_links[uc.path]

    def ucs_citing(self, path: str) -> List[model.Artifact]:
        """Живые UC со ссылкой на файл артефакта `path`."""
        return [uc for uc in self.live_ucs
                if any(resolved.kind == model.ARTIFACT_LINK and resolved.artifact is not None
                       and resolved.artifact.path == path for resolved in self._links_of(uc))]

    def ucs_for_requirement(self, number: int) -> List[model.Artifact]:
        """Живые UC со ссылкой на требование `R{number}`."""
        return [uc for uc in self.live_ucs
                if any(resolved.kind == model.REQUIREMENT_LINK
                       and resolved.requirement == number for resolved in self._links_of(uc))]

    def paths(self, uc: model.Artifact) -> List[model.UcPath]:
        """Пути UC по номеру."""
        return sorted(self.repo.uc_paths(uc), key=lambda item: (int(item.nn), item.nn))

    # -- метки ----------------------------------------------------------------

    @property
    def label_files(self) -> Dict[str, List[str]]:
        """Id метки → файлы кода с ней, по пути."""
        if self._label_files is None:
            files: Dict[str, Set[str]] = {}
            for label in self.repo.labels():
                files.setdefault(label.id, set()).add(label.path)
            self._label_files = {key: sorted(paths) for key, paths in files.items()}
        return self._label_files

    def implemented(self, from_file: str, artifact_id: str) -> str:
        """Ячейка «Где реализован»: файлы с меткой `artifact_id`."""
        files = self.label_files.get(artifact_id, [])
        return ', '.join(_file_link(from_file, path) for path in files) or NOT_COVERED

    def unlabeled_theme_files(self) -> List[str]:
        """Файлы темы без метки `TOKEN-{n}`."""
        tokens = {label.path for label in self.repo.labels() if label.type == 'TOKEN'}
        return [path for path in self.repo.theme_files() if path not in tokens]

    # -- прогоны ------------------------------------------------------------------

    def _auto_data(self) -> Tuple[Optional[model.AutoRun], Dict[str, str]]:
        if self._auto is None:
            run = latest_auto_run(self.repo)
            verdicts = auto_verdicts(run.summary) if run is not None and run.summary else {}
            self._auto = (run, verdicts)
        return self._auto

    @property
    def auto_run(self) -> Optional[model.AutoRun]:
        return self._auto_data()[0]

    @property
    def rounds(self) -> Dict[str, model.ManualRun]:
        """Id кейса → его раунд с последней датой."""
        if self._rounds is None:
            latest: Dict[str, model.ManualRun] = {}
            for run in self.repo.manual_runs():  # по кейсу, затем по дате
                latest[run.tc] = run
            self._rounds = latest
        return self._rounds

    def _manual_verdicts(self) -> Dict[str, List[_Verdict]]:
        if self._manual is None:
            by_path: Dict[str, List[_Verdict]] = {}
            for case in self.repo.of_type('TC', live=True):
                run = self.rounds.get(case.id)
                if run is None or run.verdict not in _SEVERITY:
                    continue
                verdict = _Verdict(run.verdict, run.date, MANUAL, run.date, case)
                for resolved in _case_paths(self.repo, case):
                    by_path.setdefault(resolved.target_id or '', []).append(verdict)
            self._manual = by_path
        return self._manual

    def verdict(self, path_id: str) -> Optional[_Verdict]:
        """Вердикт сводки для пути UC; не проверен — None."""
        if path_id not in self._verdicts:
            candidates = list(self._manual_verdicts().get(path_id, []))
            run, verdicts = self._auto_data()
            if run is not None and path_id in verdicts:
                candidates.append(_Verdict(verdicts[path_id], _run_date(run), AUTO, run.name))
            self._verdicts[path_id] = (max(candidates, key=lambda item: item.rank)
                                       if candidates else None)
        return self._verdicts[path_id]


def basis_lines(doc: model.Document) -> Optional[Tuple[int, int]]:
    """Строки (с 1, включительно) блока основания задания; нет — None."""
    lines = doc.masked_lines
    for index, line in enumerate(lines):
        heading = _BASIS_HEADING_RE.match(line)
        if heading is not None:
            level = len(heading.group(1))
            end = index + 1
            while end < len(lines):
                other = _HEADING_LINE_RE.match(lines[end])
                if other is not None and len(other.group(1)) <= level:
                    break
                end += 1
            return index + 1, end
        if _BASIS_LINE_RE.match(line):
            end = index + 1
            while (end < len(lines) and lines[end].strip()
                   and _HEADING_LINE_RE.match(lines[end]) is None):
                end += 1
            return index + 1, end
    return None


def _basis_paths(repo: model.Repo, task: model.Artifact) -> List[model.Resolved]:
    """Пути UC в основании задания, без повторов, по порядку."""
    block = basis_lines(repo.doc(task.path))
    if block is None:
        return []
    first, last = block
    return _unique(resolved for link, resolved in repo.outgoing(task.path)
                   if first <= link.line <= last and _is_path_ref(resolved))


# --------------------------------------------------------------------------
# Колонки папок


def _planning_columns(views: _Views, index: str, business_task: model.Artifact) -> List[str]:
    ucs = views.ucs_citing(business_task.path)
    if not ucs:
        return [f'{NONE_YET} — нет UC']
    groups: Dict[Optional[str], List[str]] = {FAIL: [], BLOCKED: [], None: []}
    for uc in ucs:
        paths = views.paths(uc)
        if not paths:
            groups[None].append(_artifact_link(index, uc))
        for uc_path in paths:
            verdict = views.verdict(uc_path.id)
            key = verdict.verdict if verdict is not None else None
            if key != PASS:
                groups[key].append(_path_link(index, uc, uc_path))
    reasons = [f'{name}: {", ".join(groups[key])}'
               for key, name in ((FAIL, FAIL), (BLOCKED, BLOCKED), (None, 'не проверено'))
               if groups[key]]
    return [f'{NONE_YET} — {"; ".join(reasons)}' if reasons else YES]


def _use_case_columns(views: _Views, index: str, uc: model.Artifact) -> List[str]:
    paths = views.paths(uc)
    checked = sum(1 for uc_path in paths if views.verdict(uc_path.id) is not None)
    return [str(len(paths)), f'{checked} из {len(paths)}', views.implemented(index, uc.id)]


def _design_columns(views: _Views, index: str, artifact: model.Artifact) -> List[str]:
    return [views.implemented(index, artifact.id)]


def _acceptance_cell(repo: model.Repo, index: str, acceptance: model.Artifact) -> str:
    return f'{_artifact_link(index, acceptance)} — {repo.verdict(acceptance) or NO_VERDICT}'


def _owned(repo: model.Repo, kind: str, task_number: int) -> List[model.Artifact]:
    """Живые сдачи или приёмки задания, по {NN}."""
    return [item for item in repo.of_type(kind, live=True) if item.number == task_number]


def _task_columns(views: _Views, index: str, task: model.Artifact) -> List[str]:
    repo = views.repo
    results = _owned(repo, 'RESULT', task.number)
    acceptances = _owned(repo, 'ACC', task.number)
    closed = bool(acceptances) and repo.verdict(acceptances[-1]) == ACCEPTED
    return [
        _refs_cell(index, _basis_paths(repo, task)),
        ', '.join(_artifact_link(index, item) for item in results) or EMPTY,
        ', '.join(_acceptance_cell(repo, index, item) for item in acceptances) or EMPTY,
        YES if closed else NONE_YET,
    ]


def _result_columns(views: _Views, index: str, result: model.Artifact) -> List[str]:
    repo = views.repo
    task = repo.get(result.task_id or '')
    acceptance = repo.get(f'ACC-TASK-{result.number}-{result.nn}')
    return [
        _artifact_link(index, task) if task is not None else EMPTY,
        (_acceptance_cell(repo, index, acceptance)
         if acceptance is not None and acceptance.live else NONE_YET),
    ]


def _acceptance_columns(views: _Views, index: str, acceptance: model.Artifact) -> List[str]:
    repo = views.repo
    result = repo.get(acceptance.result_id or '')
    return [
        _artifact_link(index, result) if result is not None else EMPTY,
        repo.verdict(acceptance) or EMPTY,
    ]


def _manual_columns(views: _Views, index: str, case: model.Artifact) -> List[str]:
    run = views.rounds.get(case.id)
    last = (f'{_link(index, run.date, run.path)} — {run.verdict or NO_VERDICT}'
            if run is not None else NONE_YET)
    return [_refs_cell(index, _case_paths(views.repo, case)), last]


_Columns = Callable[[_Views, str, model.Artifact], List[str]]
_FOLDER_COLUMNS: Dict[str, Tuple[Tuple[str, ...], _Columns]] = {
    PLANNING_FOLDER: (('Закрыта',), _planning_columns),
    USE_CASES_FOLDER: (('Пути', 'Проверено', 'Где реализован'), _use_case_columns),
    DESIGN_SYSTEM_FOLDER: (('Где реализован',), _design_columns),
    TASKS_FOLDER: (('Пути UC', 'Сдачи', 'Приёмки', 'Закрыто'), _task_columns),
    RESULTS_FOLDER: (('Задание', 'Приёмка'), _result_columns),
    ACCEPTANCE_FOLDER: (('Сдача', 'Вердикт'), _acceptance_columns),
    MANUAL_FOLDER: (('Путь UC', 'Последний прогон'), _manual_columns),
}


# --------------------------------------------------------------------------
# INDEX.md


def _replaced_cell(repo: model.Repo, index: str, artifact: model.Artifact) -> str:
    """«Заменён» из шапки похороненного: id ссылкой, «ничем» или «—»."""
    header = repo.tomb_header(artifact)
    if header is None:
        return EMPTY
    if header.link is not None:
        resolved = repo.resolve(header.link)
        if resolved.kind == model.ARTIFACT_LINK and resolved.artifact is not None:
            return _artifact_link(index, resolved.artifact)
        return _escape(_plain(header.replaced_by or '')) or EMPTY
    return EMPTY if header.error else NOTHING


def _references(repo: model.Repo, artifact: model.Artifact) -> List[model.Resolved]:
    """«Ссылается на»: артефакты и требования из ссылок файла, без себя."""
    return _unique(resolved for _, resolved in repo.outgoing(artifact.path)
                   if resolved.artifact is None or resolved.artifact.path != artifact.path)


def _render_index(views: _Views, folder: str) -> Optional[str]:
    """Текст `INDEX.md` папки артефактов `folder` (от `sdlc/`); артефактов нет — None."""
    repo = views.repo
    artifacts = repo.artifacts_in(folder)
    if not artifacts:
        return None
    index = model.index_path(folder)
    headers, columns = _FOLDER_COLUMNS.get(folder, ((), None))
    live = [item for item in artifacts if item.live]
    buried = [item for item in artifacts if item.buried]
    rows = []
    for artifact in live:
        row = [_artifact_link(index, artifact), _title(repo, artifact),
               _refs_cell(index, _references(repo, artifact))]
        if columns is not None:
            row += columns(views, index, artifact)
        rows.append(row)
    lines = [model.DERIVED_HEADER, '', f'# Индекс: `{folder}/`', '']
    lines += _table(('Id', 'Название', 'Ссылается на') + headers, rows)
    review = []
    for artifact in live:
        stale = _unique(resolved for _, resolved in repo.stale_links(artifact))
        if stale:
            review.append([_artifact_link(index, artifact), _refs_cell(index, stale)])
    if review:
        lines += ['', '## К пересмотру', '']
        lines += _table(('Id', 'Ссылается на похороненное'), review)
    if buried:
        lines += ['', '## Похоронены', '']
        lines += _table(('Id', 'Название', 'Заменён'), [
            [_artifact_link(index, artifact), _title(repo, artifact),
             _replaced_cell(repo, index, artifact)] for artifact in buried])
    if folder == DESIGN_SYSTEM_FOLDER:
        unlabeled = views.unlabeled_theme_files()
        if unlabeled:
            lines += ['', '## Файлы темы без метки', '']
            lines += [f'- {_file_link(index, path)}' for path in unlabeled]
    return '\n'.join(lines) + '\n'


# --------------------------------------------------------------------------
# DASHBOARD.md


def _source(from_file: str, verdict: Optional[_Verdict]) -> str:
    if verdict is None:
        return EMPTY
    if verdict.case is None:
        return f'{AUTO} {verdict.run}'
    return f'{MANUAL} {verdict.date} {_artifact_link(from_file, verdict.case)}'


def _run_link(repo: model.Repo, from_file: str, run: model.AutoRun) -> str:
    summary = f'{run.dir}/summary.md'
    if summary in repo.file_set:
        return _link(from_file, run.name, summary)
    return _link(from_file, run.name, run.dir, is_dir=True)


def _replacement(repo: model.Repo, from_file: str, requirement: model.Requirement) -> str:
    number = requirement.replaced_by
    if number is None:
        return NOTHING
    target = repo.requirement(number)
    return _requirement_link(from_file, target) if target is not None else f'R{number}'


def _render_dashboard(views: _Views) -> Optional[str]:
    """Текст `6-eval/DASHBOARD.md`; PRD нет — None."""
    repo = views.repo
    if not repo.prd_files:
        return None
    here = model.DASHBOARD_PATH
    run = views.auto_run
    latest = _run_link(repo, here, run) if run is not None else NONE_YET
    requirements = sorted(repo.requirements, key=lambda item: item.number)
    rows = []
    counted: Dict[str, Optional[str]] = {}
    for requirement in requirements:
        if requirement.obsolete:
            continue
        cell = _requirement_link(here, requirement)
        ucs = views.ucs_for_requirement(requirement.number)
        if not ucs:
            rows.append([cell, EMPTY, EMPTY, f'{NOT_CHECKED}: нет UC', EMPTY])
        for uc in ucs:
            uc_cell = _artifact_link(here, uc)
            paths = views.paths(uc)
            if not paths:
                rows.append([cell, uc_cell, EMPTY, f'{NOT_CHECKED}: нет путей', EMPTY])
            for uc_path in paths:
                verdict = views.verdict(uc_path.id)
                counted[uc_path.id] = verdict.verdict if verdict is not None else None
                rows.append([cell, uc_cell, _path_link(here, uc, uc_path),
                             verdict.verdict if verdict is not None else NOT_CHECKED,
                             _source(here, verdict)])
    totals = {key: sum(1 for value in counted.values() if value == key)
              for key in (PASS, FAIL, BLOCKED, None)}
    lines = [model.DERIVED_HEADER, '', '# Сводка проверки', '',
             f'Последний машинный прогон: {latest}', '']
    lines += _table(('Требование', 'UC', 'Путь', 'Вердикт', 'Источник'), rows)
    lines += ['', f'Итого путей: PASS {totals[PASS]}, FAIL {totals[FAIL]}, '
                  f'BLOCKED {totals[BLOCKED]}, {NOT_CHECKED} {totals[None]}.']
    obsolete = [item for item in requirements if item.obsolete]
    if obsolete:
        lines += ['', '## Устаревшие требования', '']
        lines += _table(('Требование', 'Заменено'), [
            [_requirement_link(here, item), _replacement(repo, here, item)]
            for item in obsolete])
    return '\n'.join(lines) + '\n'


# --------------------------------------------------------------------------
# Вход


def render_all(repo: model.Repo) -> Dict[str, Optional[str]]:
    """Тексты всех производных файлов, какими их собрал бы `views`.

    Ключ — путь от корня репозитория (`sdlc/2-specs/use-cases/INDEX.md`,
    `sdlc/6-eval/DASHBOARD.md`). Значение — полный текст файла
    (`model.DERIVED_HEADER` первой строкой, `\\n` в конце) или None: файла
    быть не должно. В словаре есть каждая папка артефактов из
    `model.ARTIFACT_FOLDERS` (ключ `model.index_path(folder)`), каждый
    существующий `INDEX.md` под `sdlc/` (не нужен — None) и
    `model.DASHBOARD_PATH`.

    Только читает `repo`; результат детерминирован. `check` (проверка 12)
    сравнивает его с файлами дерева, `write_all` — пишет.
    """
    views = _Views(repo)
    result: Dict[str, Optional[str]] = {}
    for folder in sorted(model.ARTIFACT_FOLDERS):
        result[model.index_path(folder)] = _render_index(views, folder)
    for path in repo.files:
        if posixpath.basename(path) == model.INDEX_NAME and path not in result:
            result[path] = None
    result[model.DASHBOARD_PATH] = _render_dashboard(views)
    return result


def _names(directory: str) -> List[str]:
    try:
        return sorted(os.listdir(directory))
    except OSError:
        return []


def _read(absolute: str) -> Optional[str]:
    """Текст файла ровно с этим именем (с учётом регистра); нет — None."""
    directory, name = os.path.split(absolute)
    if name not in _names(directory) or not os.path.isfile(absolute):
        return None
    with open(absolute, encoding='utf-8', errors='replace') as handle:
        return handle.read()


def write_all(repo: model.Repo) -> List[str]:
    """Приводит производные файлы в `repo.root` к `render_all(repo)`.

    Создаёт и переписывает файлы с текстом, удаляет файлы со значением None;
    совпадающие не трогает. Возвращает отсортированные пути (от корня)
    созданных, изменённых и удалённых файлов. Отказ (`model.Refusal`, код
    1), если запись затёрла бы файл с тем же именем в другом регистре; тогда
    не пишется ничего.
    """
    rendered = render_all(repo)
    plan: List[Tuple[str, str, Optional[str]]] = []
    for path in sorted(rendered):
        absolute = os.path.join(repo.root, *path.split('/'))
        want = rendered[path]
        have = _read(absolute)
        if want == have:
            continue
        if want is not None and have is None and os.path.exists(absolute):
            directory, name = os.path.split(absolute)
            other = next((item for item in _names(directory)
                          if item.lower() == name.lower()), name)
            raise model.Refusal(
                f'{posixpath.dirname(path)}/{other}: имя {name} занято производным '
                'файлом, а файловая система не различает регистр — переименуйте '
                'этот файл')
        plan.append((path, absolute, want))
    for _, absolute, want in plan:
        if want is None:
            os.remove(absolute)
            continue
        os.makedirs(os.path.dirname(absolute), exist_ok=True)
        with open(absolute, 'w', encoding='utf-8', newline='\n') as handle:
            handle.write(want)
    return [path for path, _, _ in plan]
