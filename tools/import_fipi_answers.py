#!/usr/bin/env python3
"""Заливка подтверждённых ответов банка ФИПИ в базу через Content API.

Ответы задач банка решены вне репозитория: в `solutions.json` выгрузки
(`~/projects/ege-informatics-2027`, не под git) 199 записей с
`verified: true` — их подтвердил банк ФИПИ (sdlc/0-vibes/raw/2026-10-08/SOLVE_REPORT.md). Скрипт
переносит их в базу. Для каждой подтверждённой задачи:

1. `admin_set_task_answer` — ответ, формат, эталон и разбор. Файлы, темы,
   условие задачи не меняются; `admin_upsert_task` для задач банка не
   годится — он стёр бы ссылки на вложения в Storage;
2. эталон запускается локально, рабочий каталог — `assets/files/`
   выгрузки;
3. `admin_verify_reference` с его выводом: база должна ответить
   `matches: true`. Несовпадение — ошибка и остановка, а не пропуск.

Задача, у которой ответ, формат и эталон уже совпадают с `solutions.json`,
а эталон сверен, пропускается. Поэтому повторный запуск безопасен: иначе
он снял бы публикацию (новый ответ уводит опубликованную задачу в review).

`--publish` только публикует — ответы к этому времени должны быть залиты.
Публикуются задачи без вложений и без ссылки на задание 19 (правило —
`select_publishable`), это ровно 139; если правило отобрало другое число,
не публикуется ничего. Перед публикацией у каждой задачи проверяется, что
файлов в базе нет, а ответ залит и сверен.

Не больше 50 вызовов `admin_*` в минуту: база пускает 60 записей в минуту
(`content_writes_per_minute`). На `[rate_limit]` — пауза 60 с и повтор.

Ответы и эталоны скрипт не печатает: вывод попадает в журналы. Только slug,
этап и итог.

Запуск (доступы — в переменных окружения, см. docs/content-api.md):

    python3 tools/import_fipi_answers.py --dry-run    # без сети
    set -a; . supabase/.env.local; set +a
    python3 tools/import_fipi_answers.py --slug fipi-efeab3
    python3 tools/import_fipi_answers.py              # все подтверждённые
    python3 tools/import_fipi_answers.py --publish    # 139 задач
"""

from __future__ import annotations

import argparse
import collections
import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, Callable, Deque, Dict, List, Optional, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent))

from content_client import ContentApiError, ContentClient  # noqa: E402

DEFAULT_DUMP = "~/projects/ege-informatics-2027"

# Столько задач банка отбирает правило публикации (см. select_publishable).
EXPECTED_TO_PUBLISH = 139

# Темп: база пускает 60 записей в минуту на пользователя, берём с запасом.
CALLS_PER_MINUTE = 50
WINDOW_SECONDS = 60.0
RATE_LIMIT_PAUSE_SECONDS = 60
RATE_LIMIT_ATTEMPTS = 5

REFERENCE_TIMEOUT_SECONDS = 60

ANSWER_FORMATS = ("single", "pair", "multi", "string")

# Как в public.normalize_answer: btrim срезает с краёв только пробелы,
# затем любые пробельные последовательности схлопываются в один пробел.
_SPACES = re.compile(r"[ \t\n\r\f\v]+")
_NUMBER = re.compile(r"-?[0-9]+(\.[0-9]+)?")
_EXCEPTION_NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_.]*")


class AnswerImportError(RuntimeError):
    """Задача не прошла проверку: дальше скрипт не идёт."""


def task_slug(short_id: str) -> str:
    """slug задачи банка: `fipi-` и шифр в нижнем регистре."""
    return "fipi-" + short_id.lower()


def _slug_argument(value: str) -> str:
    """Аргумент --slug: принимается и slug, и шифр задачи."""
    value = value.strip().lower()
    return value if value.startswith("fipi-") else "fipi-" + value


def _canonical_number(token: str) -> str:
    """Число как его печатает numeric базы, без незначащих нулей."""
    negative = token.startswith("-")
    whole, _, fraction = token.lstrip("-").partition(".")
    whole = whole.lstrip("0") or "0"
    fraction = fraction.rstrip("0")
    if whole == "0" and not fraction:
        negative = False
    return ("-" if negative else "") + whole + ("." + fraction if fraction else "")


def normalize_answer(answer: Optional[str], answer_format: str) -> Optional[str]:
    """Повторяет `public.normalize_answer` базы.

    `None` — ответ не подходит к формату: такой ответ никогда не совпадёт.
    """
    if answer is None:
        return None
    text = _SPACES.sub(" ", answer.strip(" "))
    if answer_format == "string":
        return text
    if answer_format not in ("single", "pair", "multi") or text == "":
        return None

    tokens = text.split(" ")
    if answer_format == "single" and len(tokens) != 1:
        return None
    if answer_format == "pair" and len(tokens) != 2:
        return None
    if not all(_NUMBER.fullmatch(token) for token in tokens):
        return None
    return " ".join(_canonical_number(token) for token in tokens)


def answers_match(output: str, answer: str, answer_format: str) -> bool:
    """Совпадает ли вывод с ответом так, как сравнивает база."""
    expected = normalize_answer(answer, answer_format)
    return expected is not None and normalize_answer(output, answer_format) == expected


# -- выгрузка ----------------------------------------------------------------


def load_dump(dump_root: Path) -> Tuple[List[Dict[str, Any]], Dict[str, Dict[str, Any]]]:
    """Записи `solutions.json` и задания `tasks.json` по шифру."""
    for name in ("solutions.json", "tasks.json"):
        if not (dump_root / name).is_file():
            raise AnswerImportError(f"в «{dump_root}» нет {name} — это не выгрузка банка")
    solutions = json.loads((dump_root / "solutions.json").read_text(encoding="utf-8"))
    tasks = json.loads((dump_root / "tasks.json").read_text(encoding="utf-8"))
    return solutions, {task["short_id"]: task for task in tasks}


def select_confirmed(solutions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Записи, подтверждённые банком: их и заливаем."""
    return [entry for entry in solutions if entry.get("verified") is True]


def select_publishable(
    confirmed: List[Dict[str, Any]], tasks: Dict[str, Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """Подтверждённые задачи, которые клиент уже умеет показывать.

    Без вложений (файлов и картинок): клиент не читает Storage. Без
    `parent_id`: условие ссылается на задание 19, которое не публикуется.
    Без неполного условия и не дубли.
    """
    result = []
    for entry in confirmed:
        task = tasks.get(entry["short_id"])
        if task is None:
            raise AnswerImportError(f"{entry['short_id']}: нет в tasks.json")
        if (
            task.get("assets")
            or task.get("parent_id")
            or task.get("condition_incomplete")
            or task.get("duplicate_of")
        ):
            continue
        result.append(entry)
    return result


def check_entry(entry: Dict[str, Any]) -> None:
    """Те же проверки, что у admin_set_task_answer, — до отправки."""
    slug = task_slug(entry["short_id"])
    answer_format = entry.get("answer_format")
    answer = entry.get("answer")
    if answer_format not in ANSWER_FORMATS:
        raise AnswerImportError(f"{slug}: неизвестный формат ответа")
    if not isinstance(answer, str) or not answer.strip():
        raise AnswerImportError(f"{slug}: пустой ответ")
    if answer_format == "string" and ("\n" in answer or "\r" in answer):
        raise AnswerImportError(f"{slug}: строковый ответ не в одну строку")
    if normalize_answer(answer, answer_format) is None:
        raise AnswerImportError(f"{slug}: ответ не соответствует формату {answer_format}")
    if not (entry.get("reference_solution") or "").strip():
        raise AnswerImportError(f"{slug}: нет эталонного решения")


def build_payload(entry: Dict[str, Any]) -> Dict[str, Any]:
    """Тело admin_set_task_answer."""
    payload = {
        "slug": task_slug(entry["short_id"]),
        "answer": entry["answer"],
        "answer_format": entry["answer_format"],
        "reference_solution": entry["reference_solution"],
    }
    if entry.get("answer_explanation"):
        payload["answer_explanation"] = entry["answer_explanation"]
    return payload


# -- эталон ------------------------------------------------------------------


def _exception_name(stderr: str) -> str:
    """Имя исключения из последней строки трассировки — без её текста.

    Трассировка печатает строки эталона, а текст исключения может
    содержать данные: наружу уходит только имя класса.
    """
    lines = [line for line in stderr.splitlines() if line.strip()]
    name = lines[-1].split(":", 1)[0].strip() if lines else ""
    return name if _EXCEPTION_NAME.fullmatch(name) else "ошибка выполнения"


def run_reference(code: str, files_dir: Path, timeout: float = REFERENCE_TIMEOUT_SECONDS) -> str:
    """Запускает эталон в каталоге вложений и возвращает его вывод."""
    with tempfile.TemporaryDirectory() as tmp:
        script = Path(tmp) / "reference.py"
        script.write_text(code, encoding="utf-8")
        try:
            result = subprocess.run(
                [sys.executable, "-I", str(script)],
                cwd=files_dir,
                capture_output=True,
                encoding="utf-8",
                errors="replace",
                timeout=timeout,
                check=False,
            )
        except subprocess.TimeoutExpired as error:
            raise AnswerImportError(f"эталон не уложился в {timeout:g} с") from error
    if result.returncode != 0:
        raise AnswerImportError(
            f"эталон завершился с кодом {result.returncode} "
            f"({_exception_name(result.stderr)})"
        )
    return result.stdout.strip()


# -- темп --------------------------------------------------------------------


class Throttle:
    """Не больше `limit` вызовов за `window` секунд (скользящее окно)."""

    def __init__(
        self,
        limit: int = CALLS_PER_MINUTE,
        window: float = WINDOW_SECONDS,
        clock: Callable[[], float] = time.monotonic,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self._limit = limit
        self._window = window
        self._clock = clock
        self._sleep = sleep
        self._calls: Deque[float] = collections.deque()

    def wait(self) -> None:
        """Ждёт, пока очередной вызов уложится в лимит, и учитывает его."""
        while True:
            now = self._clock()
            while self._calls and now - self._calls[0] >= self._window:
                self._calls.popleft()
            if len(self._calls) < self._limit:
                self._calls.append(now)
                return
            self._sleep(self._window - (now - self._calls[0]))


# -- заливка -----------------------------------------------------------------


def _redact(text: str, secrets: List[str]) -> str:
    """Вычищает из сообщения ответ и эталон, если они туда попали."""
    for secret in secrets:
        if secret and len(secret.strip()) >= 2 and secret in text:
            text = text.replace(secret, "«…»")
    return text


def is_loaded(task: Dict[str, Any], entry: Dict[str, Any]) -> bool:
    """Ответ, формат и эталон в базе те же, что в выгрузке, и эталон сверен."""
    return (
        task.get("answer") == entry["answer"]
        and task.get("answer_format") == entry["answer_format"]
        and task.get("reference_solution") == entry["reference_solution"]
        and task.get("reference_verified_at") is not None
    )


class AnswerImporter:
    """Заливка ответов и публикация через Content API."""

    def __init__(
        self,
        client: Any,
        files_dir: Path,
        *,
        throttle: Optional[Throttle] = None,
        sleep: Callable[[float], None] = time.sleep,
        reference_runner: Callable[[str, Path], str] = run_reference,
    ) -> None:
        self._client = client
        self._files_dir = files_dir
        self._throttle = throttle or Throttle(sleep=sleep)
        self._sleep = sleep
        self._run_reference = reference_runner

    def _call(self, entry: Dict[str, Any], method: Callable[..., Any], *args: Any) -> Any:
        """Вызов admin_* с соблюдением темпа и повтором после [rate_limit]."""
        slug = task_slug(entry["short_id"])
        for attempt in range(1, RATE_LIMIT_ATTEMPTS + 1):
            self._throttle.wait()
            try:
                return method(*args)
            except ContentApiError as error:
                if error.code == "rate_limit" and attempt < RATE_LIMIT_ATTEMPTS:
                    print(
                        f"{slug}: [rate_limit], пауза {RATE_LIMIT_PAUSE_SECONDS} с и повтор"
                    )
                    self._sleep(RATE_LIMIT_PAUSE_SECONDS)
                    continue
                secrets = [entry["answer"], entry["reference_solution"]]
                raise AnswerImportError(
                    f"{slug}: [{error.code}] {_redact(error.message, secrets)}"
                ) from error
        raise AssertionError("недостижимо: цикл повторов всегда возвращает или бросает")

    def _fetch(self, entry: Dict[str, Any]) -> Dict[str, Any]:
        """Задача из базы; заодно проверка, что slug ведёт к тому заданию банка."""
        slug = task_slug(entry["short_id"])
        task = self._call(entry, self._client.get_task, slug)
        if task.get("origin") != "fipi" or task.get("fipi_short_id") != entry["short_id"]:
            raise AnswerImportError(f"{slug}: в базе под этим slug не задание банка {entry['short_id']}")
        return task

    def load(self, entries: List[Dict[str, Any]]) -> None:
        """Заливает ответы; на первой ошибке останавливается."""
        for entry in entries:
            check_entry(entry)

        loaded = skipped = 0
        for entry in entries:
            if self.load_one(entry):
                loaded += 1
            else:
                skipped += 1
        print(f"\nЗалито: {loaded}, уже были залиты: {skipped}, всего: {len(entries)}")

    def load_one(self, entry: Dict[str, Any]) -> bool:
        """Одна задача; False — она уже залита и сверена, вызовов записи не было."""
        slug = task_slug(entry["short_id"])
        task = self._fetch(entry)
        if is_loaded(task, entry):
            print(f"{slug}: уже залита, эталон сверен — пропуск")
            return False

        result = self._call(entry, self._client.set_answer, build_payload(entry))
        try:
            output = self._run_reference(entry["reference_solution"], self._files_dir)
        except AnswerImportError as error:
            raise AnswerImportError(f"{slug}: {error}") from error
        verdict = self._call(entry, self._client.verify_reference, slug, output)
        if not (verdict or {}).get("matches"):
            raise AnswerImportError(
                f"{slug}: база не подтвердила вывод эталона (matches: false)"
            )
        print(f"{slug}: ответ записан, эталон сверен, статус {result.get('status')}")
        return True

    def publish(
        self, publishable: List[Dict[str, Any]], only: Optional[str] = None
    ) -> None:
        """Публикует отобранные задачи, проверив каждую до первой публикации."""
        if len(publishable) != EXPECTED_TO_PUBLISH:
            raise AnswerImportError(
                f"правило отобрало {len(publishable)} задач вместо "
                f"{EXPECTED_TO_PUBLISH} — не публикую ничего"
            )
        targets = publishable
        if only is not None:
            targets = [e for e in publishable if task_slug(e["short_id"]) == only]
            if not targets:
                raise AnswerImportError(f"{only}: не проходит правило публикации")

        plan = []
        for entry in targets:
            slug = task_slug(entry["short_id"])
            task = self._fetch(entry)
            files = task.get("files") or []
            if files:
                raise AnswerImportError(
                    f"{slug}: у задачи в базе {len(files)} файл(ов) — не публикую ничего"
                )
            if not is_loaded(task, entry):
                raise AnswerImportError(
                    f"{slug}: ответ не залит или эталон не сверен — "
                    "сначала запуск без --publish; не публикую ничего"
                )
            plan.append((entry, task.get("status")))
            print(f"{slug}: файлов нет, ответ сверен")

        published = skipped = 0
        for entry, status in plan:
            slug = task_slug(entry["short_id"])
            if status == "published":
                print(f"{slug}: уже опубликована — пропуск")
                skipped += 1
                continue
            self._call(entry, self._client.set_status, slug, "published")
            print(f"{slug}: опубликована")
            published += 1
        print(
            f"\nОпубликовано: {published}, уже были опубликованы: {skipped}, "
            f"всего: {len(plan)}"
        )


def dry_run(
    entries: List[Dict[str, Any]],
    publishable: List[Dict[str, Any]],
    files_dir: Path,
    *,
    expect_full: bool,
) -> int:
    """Без сети: запускает эталоны и сверяет вывод с ответом, как база."""
    failures = 0
    for entry in entries:
        slug = task_slug(entry["short_id"])
        try:
            check_entry(entry)
            output = run_reference(entry["reference_solution"], files_dir)
        except AnswerImportError as error:
            failures += 1
            print(f"ОШИБКА {slug}: {error}", file=sys.stderr)
            continue
        if answers_match(output, entry["answer"], entry["answer_format"]):
            print(f"{slug}: вывод эталона совпал с ответом")
        else:
            failures += 1
            print(f"ОШИБКА {slug}: вывод эталона не совпал с ответом", file=sys.stderr)

    print(f"\nк заливке: {len(entries)}, к публикации: {len(publishable)}")
    if expect_full and len(publishable) != EXPECTED_TO_PUBLISH:
        failures += 1
        print(
            f"ОШИБКА: правило публикации отобрало {len(publishable)}, "
            f"ожидалось {EXPECTED_TO_PUBLISH}",
            file=sys.stderr,
        )
    if failures:
        print(f"Ошибок: {failures}", file=sys.stderr)
    return 1 if failures else 0


def main(
    argv: Optional[List[str]] = None,
    *,
    client: Any = None,
    sleep: Callable[[float], None] = time.sleep,
    clock: Callable[[], float] = time.monotonic,
) -> int:
    """Точка входа."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dump", default=DEFAULT_DUMP, help="каталог выгрузки банка")
    parser.add_argument("--slug", help="одна задача: slug или шифр")
    parser.add_argument(
        "--publish", action="store_true", help="опубликовать задачи по правилу отбора"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="без сети: запустить эталоны и сверить вывод с ответами",
    )
    args = parser.parse_args(argv)

    try:
        dump_root = Path(args.dump).expanduser()
        files_dir = dump_root / "assets" / "files"
        solutions, tasks = load_dump(dump_root)
        confirmed = select_confirmed(solutions)
        publishable = select_publishable(confirmed, tasks)

        only = _slug_argument(args.slug) if args.slug else None
        entries = confirmed
        if only is not None:
            entries = [e for e in confirmed if task_slug(e["short_id"]) == only]
            if not entries:
                raise AnswerImportError(f"{only}: нет среди подтверждённых в solutions.json")

        if args.dry_run:
            chosen = [e for e in publishable if e in entries]
            return dry_run(entries, chosen, files_dir, expect_full=only is None)

        importer = AnswerImporter(
            client if client is not None else ContentClient(),
            files_dir,
            throttle=Throttle(clock=clock, sleep=sleep),
            sleep=sleep,
        )
        if args.publish:
            importer.publish(publishable, only)
        else:
            importer.load(entries)
    except AnswerImportError as error:
        print(f"ОСТАНОВКА: {error}", file=sys.stderr)
        return 1
    except ContentApiError as error:
        print(f"ОСТАНОВКА: [{error.code}] {error.message}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
