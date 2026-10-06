#!/usr/bin/env python3
"""Тонкий клиент Content API платформы YEGE Wars.

Нужен ИИ-агенту и человеку, чтобы создавать задачи и статьи справочника,
не собирая HTTP-запросы руками. Полное описание API — в docs/content-api.md.

Зависимостей нет: только стандартная библиотека Python 3.9+.

Доступы берутся из переменных окружения и никогда не из кода:

    SUPABASE_URL          https://<ref>.supabase.co
    SUPABASE_ANON_KEY     публичный ключ проекта
    CONTENT_API_LOGIN     логин сервисного аккаунта (например ai_author)
    CONTENT_API_PASSWORD  его пароль

Примеры:

    python3 tools/content_client.py list --status review
    python3 tools/content_client.py upsert-task task.json
    python3 tools/content_client.py verify ege24-demo-01 --output-file out.txt
    python3 tools/content_client.py publish ege24-demo-01
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Optional

# Домен технической почты: Supabase Auth умеет входить только по email,
# логин превращается в <логин>@ege.local (см. docs/content-api.md).
EMAIL_DOMAIN = "ege.local"

TIMEOUT_SECONDS = 60


class ContentApiError(RuntimeError):
    """Ошибка Content API.

    Функции базы сообщают об ошибках сообщением вида `[код] Русский текст`:
    код нужен программе, текст можно показать человеку.
    """

    def __init__(self, code: str, message: str, status: int = 0) -> None:
        super().__init__(f"[{code}] {message}")
        self.code = code
        self.message = message
        self.status = status


def _parse_error(status: int, body: str) -> ContentApiError:
    """Разбирает тело ответа PostgREST или GoTrue в ContentApiError."""
    message = body
    try:
        payload = json.loads(body)
        message = (
            payload.get("message")
            or payload.get("error_description")
            or payload.get("msg")
            or body
        )
    except json.JSONDecodeError:
        pass

    code = "http_error"
    text = message
    if message.startswith("["):
        end = message.find("]")
        if end > 1:
            code = message[1:end]
            text = message[end + 1:].strip()
    return ContentApiError(code, text, status)


class ContentClient:
    """Клиент Content API: вход по логину и вызовы admin_* функций."""

    def __init__(
        self,
        url: Optional[str] = None,
        anon_key: Optional[str] = None,
        login: Optional[str] = None,
        password: Optional[str] = None,
    ) -> None:
        self.url = (url or os.environ.get("SUPABASE_URL", "")).rstrip("/")
        self.anon_key = anon_key or os.environ.get("SUPABASE_ANON_KEY", "")
        self.login = login or os.environ.get("CONTENT_API_LOGIN", "")
        self.password = password or os.environ.get("CONTENT_API_PASSWORD", "")
        self._token: Optional[str] = None

        missing = [
            name
            for name, value in (
                ("SUPABASE_URL", self.url),
                ("SUPABASE_ANON_KEY", self.anon_key),
                ("CONTENT_API_LOGIN", self.login),
                ("CONTENT_API_PASSWORD", self.password),
            )
            if not value
        ]
        if missing:
            raise ContentApiError(
                "no_credentials",
                "Не заданы переменные окружения: " + ", ".join(missing),
            )

    # -- низкий уровень ----------------------------------------------------

    def _request(
        self,
        path: str,
        payload: Dict[str, Any],
        *,
        authorized: bool,
        query: Optional[Dict[str, str]] = None,
    ) -> Any:
        """Выполняет POST и возвращает разобранный JSON."""
        target = f"{self.url}{path}"
        if query:
            target = f"{target}?{urllib.parse.urlencode(query)}"

        headers = {
            "apikey": self.anon_key,
            "Content-Type": "application/json",
        }
        if authorized:
            headers["Authorization"] = f"Bearer {self.token}"

        request = urllib.request.Request(
            target,
            data=json.dumps(payload).encode("utf-8"),
            headers=headers,
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
                body = response.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            raise _parse_error(error.code, error.read().decode("utf-8")) from error
        except urllib.error.URLError as error:
            raise ContentApiError("network", f"Нет связи с сервером: {error.reason}") from error

        return json.loads(body) if body else None

    @property
    def token(self) -> str:
        """Токен доступа; при первом обращении выполняется вход."""
        if self._token is None:
            self._token = self._sign_in()
        return self._token

    def _sign_in(self) -> str:
        """Вход сервисного аккаунта по логину и паролю."""
        data = self._request(
            "/auth/v1/token",
            {
                "email": f"{self.login.lower()}@{EMAIL_DOMAIN}",
                "password": self.password,
            },
            authorized=False,
            query={"grant_type": "password"},
        )
        token = (data or {}).get("access_token")
        if not token:
            raise ContentApiError("no_token", "Сервер не вернул токен доступа.")
        return token

    def rpc(self, function: str, arguments: Dict[str, Any]) -> Any:
        """Вызывает RPC-функцию Supabase."""
        return self._request(f"/rest/v1/rpc/{function}", arguments, authorized=True)

    # -- задачи ------------------------------------------------------------

    def check_slug(self, slug: str) -> Any:
        """Свободен ли slug задачи."""
        return self.rpc("admin_check_slug_available", {"p_slug": slug})

    def upsert_task(self, payload: Dict[str, Any]) -> Any:
        """Создаёт или полностью обновляет задачу."""
        return self.rpc("admin_upsert_task", {"payload": payload})

    def set_answer(self, payload: Dict[str, Any]) -> Any:
        """Задаёт ответ, формат и эталон, не трогая файлы, темы и условие."""
        return self.rpc("admin_set_task_answer", {"payload": payload})

    def verify_reference(self, slug: str, output: str) -> Any:
        """Сверяет вывод эталонного решения с сохранённым ответом."""
        return self.rpc(
            "admin_verify_reference", {"p_slug": slug, "p_output": output}
        )

    def set_status(self, slug: str, status: str) -> Any:
        """Меняет статус задачи: draft, review или published."""
        return self.rpc(
            "admin_set_task_status", {"p_slug": slug, "p_status": status}
        )

    def delete_task(self, slug: str) -> Any:
        """Удаляет задачу вместе с файлами, ответом и связями."""
        return self.rpc("admin_delete_task", {"p_slug": slug})

    def list_tasks(self, **filters: Any) -> Any:
        """Список задач с фильтрами status, ege_number, origin, search."""
        clean = {key: value for key, value in filters.items() if value is not None}
        return self.rpc("admin_list_tasks", {"filters": clean})

    def get_task(self, slug: str) -> Any:
        """Задача целиком: с эталоном, ответом, файлами и связями."""
        return self.rpc("admin_get_task", {"p_slug": slug})

    # -- справочник --------------------------------------------------------

    def upsert_article(self, payload: Dict[str, Any]) -> Any:
        """Создаёт или обновляет статью справочника."""
        return self.rpc("admin_upsert_article", {"payload": payload})


def _load_json(path: str) -> Dict[str, Any]:
    """Читает JSON из файла или из stdin, если путь равен «-»."""
    if path == "-":
        return json.load(sys.stdin)
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def _print(value: Any) -> None:
    """Печатает результат читаемым JSON."""
    print(json.dumps(value, ensure_ascii=False, indent=2))


def _build_parser() -> argparse.ArgumentParser:
    """Собирает разбор аргументов командной строки."""
    parser = argparse.ArgumentParser(
        description="Клиент Content API YEGE Wars (см. docs/content-api.md)",
    )
    commands = parser.add_subparsers(dest="command", required=True)

    listing = commands.add_parser("list", help="список задач")
    listing.add_argument("--status", choices=["draft", "review", "published"])
    listing.add_argument("--ege-number", type=int)
    listing.add_argument("--origin", choices=["human", "ai"])
    listing.add_argument("--search")
    listing.add_argument("--limit", type=int)

    get = commands.add_parser("get", help="задача целиком")
    get.add_argument("slug")

    upsert_task = commands.add_parser("upsert-task", help="создать или обновить задачу")
    upsert_task.add_argument("payload", help="путь к JSON или «-» для stdin")

    upsert_article = commands.add_parser(
        "upsert-article", help="создать или обновить статью справочника"
    )
    upsert_article.add_argument("payload", help="путь к JSON или «-» для stdin")

    verify = commands.add_parser("verify", help="сверить вывод эталона с ответом")
    verify.add_argument("slug")
    group = verify.add_mutually_exclusive_group(required=True)
    group.add_argument("--output", help="вывод эталонного решения")
    group.add_argument("--output-file", help="файл с выводом эталонного решения")

    status = commands.add_parser("status", help="сменить статус задачи")
    status.add_argument("slug")
    status.add_argument("value", choices=["draft", "review", "published"])

    publish = commands.add_parser("publish", help="опубликовать задачу")
    publish.add_argument("slug")

    delete = commands.add_parser("delete", help="удалить задачу")
    delete.add_argument("slug")

    check = commands.add_parser("check-slug", help="свободен ли slug")
    check.add_argument("slug")

    return parser


def main(argv: Optional[list] = None) -> int:
    """Точка входа командной строки."""
    args = _build_parser().parse_args(argv)

    try:
        client = ContentClient()

        if args.command == "list":
            _print(
                client.list_tasks(
                    status=args.status,
                    ege_number=args.ege_number,
                    origin=args.origin,
                    search=args.search,
                    limit=args.limit,
                )
            )
        elif args.command == "get":
            _print(client.get_task(args.slug))
        elif args.command == "upsert-task":
            _print(client.upsert_task(_load_json(args.payload)))
        elif args.command == "upsert-article":
            _print(client.upsert_article(_load_json(args.payload)))
        elif args.command == "verify":
            output = args.output
            if output is None:
                with open(args.output_file, encoding="utf-8") as handle:
                    output = handle.read()
            _print(client.verify_reference(args.slug, output))
        elif args.command == "status":
            _print(client.set_status(args.slug, args.value))
        elif args.command == "publish":
            _print(client.set_status(args.slug, "published"))
        elif args.command == "delete":
            _print(client.delete_task(args.slug))
        elif args.command == "check-slug":
            _print(client.check_slug(args.slug))
    except ContentApiError as error:
        print(f"Ошибка {error.code}: {error.message}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
