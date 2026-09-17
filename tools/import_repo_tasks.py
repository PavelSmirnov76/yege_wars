#!/usr/bin/env python3
"""Разовый импорт банка задач из репозитория в базу через Content API.

Раньше папки `tasks/<номер>/<slug>/` были источником истины и заливались
seed-скриптом. Теперь источник истины — база, а репозиторий остаётся
резервной копией; этот скрипт переносит уже написанные задачи в новую схему
и заодно служит образцом работы с API.

Что делает для каждой задачи:

1. читает `task.yaml`, `statement.md` и файлы данных из папки задачи;
2. берёт эталонное решение из `supabase/seed/local/reference/<slug>/solution.py`
   (лежит только локально, в git его нет);
3. **запускает решение** в папке задачи, чтобы `open('24.txt')` читал
   настоящий файл, и берёт вывод как ответ;
4. сверяет вывод с `supabase/seed/local/answers.local.json` — расхождение
   означает, что банк и эталоны разошлись, импорт такой задачи не делается;
5. отправляет задачу в статусе `review`, сверяет эталон через API
   и публикует.

Запуск (доступы — в переменных окружения, см. docs/content-api.md):

    python3 tools/import_repo_tasks.py --dry-run     # только локальная проверка
    python3 tools/import_repo_tasks.py               # импорт в базу
    python3 tools/import_repo_tasks.py --slug e24-longest-run
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

sys.path.insert(0, str(Path(__file__).resolve().parent))

from content_client import ContentApiError, ContentClient  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent
TASKS_DIR = REPO_ROOT / "tasks"
LOCAL_DIR = REPO_ROOT / "supabase" / "seed" / "local"
ANSWERS_FILE = LOCAL_DIR / "answers.local.json"
REFERENCE_DIR = LOCAL_DIR / "reference"

# Файлы папки задачи, которые не являются данными для Python.
SERVICE_FILES = {"task.yaml", "statement.md"}

SOLUTION_TIMEOUT_SECONDS = 120


class ImportError_(RuntimeError):
    """Ошибка подготовки задачи к импорту."""


def parse_task_yaml(path: Path) -> Dict[str, Any]:
    """Разбирает `task.yaml`.

    Это не полноценный YAML, а ровно то подмножество, которое используется в
    банке задач: строки `ключ: значение` и списки строк вида `  - элемент`.
    Пакета PyYAML в окружении может не быть, а тянуть зависимость ради
    десятка файлов незачем.
    """
    data: Dict[str, Any] = {}
    current_list: Optional[str] = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue

        if line.lstrip().startswith("- "):
            if current_list is None:
                raise ImportError_(f"{path}: элемент списка вне ключа: {line}")
            data[current_list].append(_clean_scalar(line.lstrip()[2:]))
            continue

        if ":" not in line:
            raise ImportError_(f"{path}: непонятная строка: {line}")

        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        if value == "":
            data[key] = []
            current_list = key
        else:
            data[key] = _clean_scalar(value)
            current_list = None

    return data


def _clean_scalar(value: str) -> Any:
    """Снимает кавычки и приводит числа к int."""
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    if value.lstrip("-").isdigit():
        return int(value)
    return value


def load_answers() -> Dict[str, str]:
    """Читает локальный файл с эталонными ответами."""
    if not ANSWERS_FILE.exists():
        raise ImportError_(
            f"Нет файла с ответами: {ANSWERS_FILE}. "
            "Он существует только локально и в git не хранится."
        )
    return json.loads(ANSWERS_FILE.read_text(encoding="utf-8"))


def run_reference_solution(slug: str, task_dir: Path) -> str:
    """Запускает эталонное решение в папке задачи и возвращает его вывод."""
    solution = REFERENCE_DIR / slug / "solution.py"
    if not solution.exists():
        raise ImportError_(f"Нет эталонного решения: {solution}")

    result = subprocess.run(
        [sys.executable, str(solution)],
        cwd=task_dir,
        capture_output=True,
        text=True,
        timeout=SOLUTION_TIMEOUT_SECONDS,
        check=False,
    )
    if result.returncode != 0:
        raise ImportError_(
            f"Эталон {slug} завершился с ошибкой:\n{result.stderr.strip()}"
        )
    return result.stdout.strip()


def collect_task(task_dir: Path, answers: Dict[str, str]) -> Dict[str, Any]:
    """Собирает payload задачи и проверяет его локально."""
    meta = parse_task_yaml(task_dir / "task.yaml")
    slug = meta.get("slug")
    if not slug:
        raise ImportError_(f"{task_dir}: в task.yaml нет slug")

    statement = (task_dir / "statement.md").read_text(encoding="utf-8")

    files: List[Dict[str, str]] = []
    for item in sorted(task_dir.iterdir()):
        if item.is_file() and item.name not in SERVICE_FILES:
            files.append(
                {
                    "filename": item.name,
                    "content": item.read_text(encoding="utf-8"),
                }
            )

    solution = (REFERENCE_DIR / slug / "solution.py").read_text(encoding="utf-8")
    output = run_reference_solution(slug, task_dir)

    expected = answers.get(slug)
    if expected is None:
        raise ImportError_(f"{slug}: ответа нет в {ANSWERS_FILE.name}")
    if output.split() != expected.split():
        raise ImportError_(
            f"{slug}: вывод эталона «{output}» не совпал с сохранённым ответом «{expected}»"
        )

    return {
        "payload": {
            "slug": slug,
            "ege_number": meta["ege_number"],
            "title": meta["title"],
            "statement_md": statement,
            "difficulty": meta["difficulty"],
            "answer_format": meta["answer_format"],
            "answer": output,
            "reference_solution": solution,
            "status": "review",
            "origin": "human",
            "source": meta.get("source"),
            "tags": meta.get("tags", []),
            "files": files,
        },
        "output": output,
    }


def iter_task_dirs(slug: Optional[str]) -> List[Path]:
    """Папки задач банка, отсортированные по номеру ЕГЭ и slug."""
    directories = [
        path
        for path in sorted(TASKS_DIR.glob("*/*"))
        if (path / "task.yaml").exists()
    ]
    if slug:
        directories = [path for path in directories if path.name == slug]
        if not directories:
            raise ImportError_(f"Задача «{slug}» в {TASKS_DIR} не найдена")
    return directories


def main(argv: Optional[list] = None) -> int:
    """Точка входа."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="только собрать и проверить локально, в базу не отправлять",
    )
    parser.add_argument("--slug", help="импортировать одну задачу")
    parser.add_argument(
        "--keep-review",
        action="store_true",
        help="оставить задачи в статусе review, не публиковать",
    )
    args = parser.parse_args(argv)

    try:
        answers = load_answers()
        task_dirs = iter_task_dirs(args.slug)
    except ImportError_ as error:
        print(f"Ошибка: {error}", file=sys.stderr)
        return 1

    prepared = []
    failures = 0
    for task_dir in task_dirs:
        try:
            prepared.append(collect_task(task_dir, answers))
            print(f"проверено: {task_dir.name}")
        except (ImportError_, subprocess.TimeoutExpired) as error:
            failures += 1
            print(f"ПРОПУЩЕНО {task_dir.name}: {error}", file=sys.stderr)

    if args.dry_run:
        total_bytes = sum(
            len(file["content"].encode("utf-8"))
            for item in prepared
            for file in item["payload"]["files"]
        )
        print(
            f"\nГотово к импорту: {len(prepared)}, с ошибками: {failures}, "
            f"файлов всего: {sum(len(i['payload']['files']) for i in prepared)} "
            f"({total_bytes / 1024:.1f} КБ)"
        )
        return 1 if failures else 0

    try:
        client = ContentClient()
    except ContentApiError as error:
        print(f"Ошибка: {error.message}", file=sys.stderr)
        return 1

    imported = 0
    for item in prepared:
        slug = item["payload"]["slug"]
        try:
            result = client.upsert_task(item["payload"])
            verified = client.verify_reference(slug, item["output"])
            if not verified.get("matches"):
                raise ContentApiError(
                    "not_verified", "база не подтвердила совпадение ответа"
                )
            if not args.keep_review:
                client.set_status(slug, "published")
            imported += 1
            state = "review" if args.keep_review else "published"
            action = "создана" if result.get("created") else "обновлена"
            print(f"{slug}: {action}, эталон сверен, статус {state}")
            for warning in result.get("warnings", []):
                print(f"  предупреждение: {warning}")
        except ContentApiError as error:
            failures += 1
            print(f"ОШИБКА {slug}: [{error.code}] {error.message}", file=sys.stderr)

    print(f"\nИмпортировано: {imported}, ошибок: {failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
