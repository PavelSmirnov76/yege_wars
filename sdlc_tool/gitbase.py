"""База из git: файлы и тексты на коммите, добавленные строки, состояние.

Все вызовы git идут через `git()` с `core.quotepath=off`, чтобы пути не
экранировались. Пути — от корня репозитория, через `/`.

`GitSource` — источник файлов для `model.Repo` на коммите: тот же интерфейс,
что у `model.FsSource` рабочего дерева (`walk_sdlc`, `read`, `exists`,
`is_dir`, `code_files`). Тексты читаются пачкой через `git cat-file --batch`
при первом обращении; переводы строк приводятся к `\\n`, как у файлов
рабочего дерева, прочитанных в текстовом режиме.

Добавленные строки (`added_lines`) — `git diff` рабочего дерева с базой без
контекста, с поиском переносов (`-M`), плюс неотслеживаемые файлы целиком
(`git ls-files --others --exclude-standard`): игнорируемые git файлы не
считаются. Неотслеживаемый файл, побайтно равный файлу базы, которого в
рабочем дереве нет, — перенос, а не новые строки. Перенос с правкой git
узнаёт, только когда он в индексе (`git add`/`git mv`); иначе такой файл
добавлен целиком.
"""

from __future__ import annotations

import hashlib
import os
import re
import subprocess
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

# Папки и расширения кода продукта, где ищутся метки (README скрипта,
# «Метки в коде»). Здесь, а не в model, чтобы gitbase не зависел от model.
CODE_DIRS: Tuple[str, ...] = ('lib', 'test', 'web', 'supabase')
CODE_EXTENSIONS: Tuple[str, ...] = ('.dart', '.sql', '.py', '.js', '.html')

_HUNK_RE = re.compile(r'@@ -[0-9]+(?:,[0-9]+)? \+([0-9]+)(?:,([0-9]+))? @@')


class GitError(Exception):
    """git не смог выполнить команду: нет репозитория, ссылки или файла."""


def git(root: str, *args: str, input_bytes: Optional[bytes] = None) -> str:
    """Выполняет git в корне `root` и возвращает stdout строкой (UTF-8)."""
    return git_bytes(root, *args, input_bytes=input_bytes).decode(
        'utf-8', errors='replace'
    )


def git_bytes(
    root: str, *args: str, input_bytes: Optional[bytes] = None
) -> bytes:
    """Выполняет git в корне `root` и возвращает stdout байтами."""
    command = ['git', '-c', 'core.quotepath=off', '-C', root] + list(args)
    try:
        completed = subprocess.run(
            command,
            input=input_bytes,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except OSError as error:
        raise GitError(f'git не запускается: {error}') from error
    if completed.returncode != 0:
        message = completed.stderr.decode('utf-8', errors='replace').strip()
        raise GitError(message or f'git {" ".join(args)}: код {completed.returncode}')
    return completed.stdout


def is_repo(root: str) -> bool:
    """`root` — рабочее дерево git."""
    try:
        return git(root, 'rev-parse', '--is-inside-work-tree').strip() == 'true'
    except GitError:
        return False


def toplevel(root: str) -> str:
    """Корень рабочего дерева git, в котором лежит `root`."""
    return git(root, 'rev-parse', '--show-toplevel').strip()


def resolve_ref(root: str, ref: str) -> str:
    """Полный хэш коммита `ref`; GitError, если такого коммита нет."""
    try:
        return git(root, 'rev-parse', '--verify', '--quiet',
                   f'{ref}^{{commit}}').strip()
    except GitError as error:
        raise GitError(f'коммита {ref} нет в git') from error


def head_commit(root: str) -> str:
    """Полный хэш HEAD."""
    return resolve_ref(root, 'HEAD')


def short_hash(root: str, ref: str = 'HEAD') -> str:
    """Короткий хэш коммита, как его печатает git (обычно 7 знаков)."""
    return git(root, 'rev-parse', '--short', resolve_ref(root, ref)).strip()


def _split_z(data: bytes) -> List[str]:
    return [
        part.decode('utf-8', errors='surrogateescape')
        for part in data.split(b'\0')
        if part
    ]


def list_files(root: str, ref: str, prefixes: Sequence[str] = ()) -> List[str]:
    """Файлы коммита `ref` (от корня репозитория), отсортированы."""
    args = ['ls-tree', '-r', '-z', '--name-only', ref]
    if prefixes:
        args += ['--'] + list(prefixes)
    return sorted(_split_z(git_bytes(root, *args)))


def worktree_files(root: str, prefixes: Sequence[str] = ()) -> List[str]:
    """Файлы рабочего дерева, которые видит git: отслеживаемые и
    неотслеживаемые, кроме игнорируемых и удалённых с диска."""
    args = ['ls-files', '-z', '--cached', '--others', '--exclude-standard']
    if prefixes:
        args += ['--'] + list(prefixes)
    result = set()
    for path in _split_z(git_bytes(root, *args)):
        if os.path.isfile(os.path.join(root, *path.split('/'))):
            result.add(path)
    return sorted(result)


def untracked_files(root: str, prefixes: Sequence[str] = ()) -> List[str]:
    """Неотслеживаемые файлы, кроме игнорируемых."""
    args = ['ls-files', '-z', '--others', '--exclude-standard']
    if prefixes:
        args += ['--'] + list(prefixes)
    return sorted(_split_z(git_bytes(root, *args)))


def status_entries(
    root: str, prefixes: Sequence[str] = ()
) -> List[Tuple[str, str]]:
    """`git status --porcelain`: пары (код XY, путь), неотслеживаемые — `??`.

    Игнорируемые файлы не входят. У переноса — новый путь.
    """
    args = ['status', '--porcelain=v1', '-z', '--untracked-files=all']
    if prefixes:
        args += ['--'] + list(prefixes)
    parts = git_bytes(root, *args).split(b'\0')
    entries = []
    index = 0
    while index < len(parts):
        part = parts[index]
        index += 1
        if not part:
            continue
        code = part[:2].decode('ascii', errors='replace')
        path = part[3:].decode('utf-8', errors='surrogateescape')
        if code[0] in 'RC':
            # За записью переноса идёт старый путь — пропускаем его.
            index += 1
        entries.append((code, path))
    return sorted(entries, key=lambda entry: (entry[1], entry[0]))


def read_blobs(root: str, ref: str, paths: Iterable[str]) -> Dict[str, bytes]:
    """Содержимое файлов коммита `ref` одним вызовом `git cat-file --batch`.

    Файла нет на коммите — его нет и в ответе.
    """
    wanted = sorted(set(paths))
    if not wanted:
        return {}
    request = ''.join(f'{ref}:{path}\n' for path in wanted).encode('utf-8')
    data = git_bytes(root, 'cat-file', '--batch', input_bytes=request)
    result: Dict[str, bytes] = {}
    offset = 0
    for path in wanted:
        end = data.index(b'\n', offset)
        header = data[offset:end].decode('utf-8', errors='replace')
        offset = end + 1
        if header.endswith((' missing', ' ambiguous')):
            continue
        fields = header.split()
        if len(fields) != 3:
            raise GitError(f'непонятный ответ git cat-file: {header}')
        size = int(fields[2])
        content = data[offset:offset + size]
        offset += size + 1
        if fields[1] == 'blob':
            result[path] = content
    return result


def decode_text(data: bytes) -> str:
    """Текст файла: UTF-8, переводы строк — `\\n`."""
    text = data.decode('utf-8', errors='replace')
    return text.replace('\r\n', '\n').replace('\r', '\n')


def _unquote_path(raw: str) -> str:
    """Путь из заголовка diff: снимает C-кавычки, если git их поставил."""
    if len(raw) >= 2 and raw[0] == '"' and raw[-1] == '"':
        body = raw[1:-1]
        data = bytearray()
        index = 0
        escapes = {'n': 10, 't': 9, '"': 34, '\\': 92, 'a': 7, 'b': 8,
                   'f': 12, 'r': 13, 'v': 11}
        while index < len(body):
            char = body[index]
            if char == '\\' and index + 1 < len(body):
                following = body[index + 1]
                if following in escapes:
                    data.append(escapes[following])
                    index += 2
                    continue
                if body[index + 1:index + 4].isdigit():
                    data.append(int(body[index + 1:index + 4], 8))
                    index += 4
                    continue
            data.extend(char.encode('utf-8'))
            index += 1
        return data.decode('utf-8', errors='surrogateescape')
    return raw


def _count_lines(path: str) -> int:
    with open(path, 'rb') as handle:
        data = handle.read()
    if not data:
        return 0
    return data.count(b'\n') + (0 if data.endswith(b'\n') else 1)


def added_lines(
    root: str, ref: str, prefixes: Sequence[str] = CODE_DIRS
) -> Dict[str, Set[int]]:
    """Добавленные строки рабочего дерева относительно коммита `ref`.

    Ключ — путь от корня репозитория, значение — номера строк (с 1) в файле
    рабочего дерева. Неотслеживаемый файл добавлен целиком.
    """
    args = ['diff', '--no-color', '--no-ext-diff', '--relative', '-M', '--unified=0',
            '--src-prefix=a/', '--dst-prefix=b/', ref]
    if prefixes:
        args += ['--'] + list(prefixes)
    output = git(root, *args)
    result: Dict[str, Set[int]] = {}
    current: Optional[str] = None
    for line in output.split('\n'):
        if line.startswith('+++ '):
            raw = _unquote_path(line[4:].rstrip('\t'))
            current = raw[2:] if raw.startswith('b/') else None
            continue
        if line.startswith('@@') and current is not None:
            match = _HUNK_RE.match(line)
            if match is None:
                continue
            start = int(match.group(1))
            count = int(match.group(2)) if match.group(2) is not None else 1
            if count > 0:
                result.setdefault(current, set()).update(
                    range(start, start + count)
                )
    untracked = untracked_files(root, prefixes)
    moved_blobs = _deleted_blobs(root, ref, prefixes) if untracked else set()
    for path in untracked:
        absolute = os.path.join(root, *path.split('/'))
        if not os.path.isfile(absolute):
            continue
        with open(absolute, 'rb') as handle:
            data = handle.read()
        if _blob_hash(data) in moved_blobs:
            continue  # перенос без правки, ещё не добавленный в индекс
        result[path] = set(range(1, _count_lines(absolute) + 1))
    return result


def _blob_hash(data: bytes) -> str:
    return hashlib.sha1(b'blob %d\0' % len(data) + data).hexdigest()


def _deleted_blobs(root: str, ref: str, prefixes: Sequence[str]) -> Set[str]:
    """Хэши файлов базы, которых нет в рабочем дереве."""
    args = ['diff', '--relative', '--no-renames', '--diff-filter=D', '--name-only', '-z',
            ref]
    if prefixes:
        args += ['--'] + list(prefixes)
    deleted = _split_z(git_bytes(root, *args))
    if not deleted:
        return set()
    listing = git_bytes(root, 'ls-tree', '-r', '-z', ref, '--', *deleted)
    blobs = set()
    for entry in listing.split(b'\0'):
        fields = entry.split(b'\t', 1)[0].split()
        if len(fields) == 3 and fields[1] == b'blob':
            blobs.add(fields[2].decode('ascii'))
    return blobs


def is_code_file(path: str) -> bool:
    """Файл кода, в котором ищутся метки (README скрипта, «Метки в коде»)."""
    if not path.endswith(CODE_EXTENSIONS):
        return False
    if path.endswith('.g.dart') or path.startswith('lib/l10n/gen/'):
        return False
    return path.split('/', 1)[0] in CODE_DIRS


class GitSource:
    """Источник файлов для `model.Repo`: дерево коммита `ref`.

    Папки выводятся из путей файлов: пустых папок в git нет.
    """

    def __init__(self, root: str, ref: str) -> None:
        self.root = os.path.abspath(root)
        self.ref = ref
        self.commit = resolve_ref(self.root, ref)
        self._files = list_files(self.root, self.commit)
        self._file_set = set(self._files)
        dirs: Set[str] = set()
        for path in self._files:
            parent = path.rpartition('/')[0]
            while parent and parent not in dirs:
                dirs.add(parent)
                parent = parent.rpartition('/')[0]
        self._dirs = dirs
        self._texts: Optional[Dict[str, str]] = None

    def walk_sdlc(self) -> Tuple[List[str], List[str]]:
        """Файлы и папки под `sdlc/` (от корня репозитория), отсортированы."""
        files = [path for path in self._files if path.startswith('sdlc/')]
        dirs = sorted(
            path for path in self._dirs
            if path == 'sdlc' or path.startswith('sdlc/')
        )
        return files, dirs

    def _load_texts(self) -> Dict[str, str]:
        if self._texts is None:
            # Пачкой — все .md под sdlc/; прочее читается по одному.
            wanted = [path for path in self._files
                      if path.startswith('sdlc/') and path.endswith('.md')]
            blobs = read_blobs(self.root, self.commit, wanted)
            self._texts = {path: decode_text(data) for path, data in blobs.items()}
        return self._texts

    def read(self, path: str) -> str:
        """Текст файла на коммите; FileNotFoundError, если его нет."""
        texts = self._load_texts()
        if path in texts:
            return texts[path]
        if path not in self._file_set:
            raise FileNotFoundError(path)
        blobs = read_blobs(self.root, self.commit, [path])
        if path not in blobs:
            raise FileNotFoundError(path)
        text = decode_text(blobs[path])
        texts[path] = text
        return text

    def exists(self, path: str) -> bool:
        return path in ('', '.') or path in self._file_set or path in self._dirs

    def is_dir(self, path: str) -> bool:
        return path in ('', '.') or path in self._dirs

    def code_files(self) -> List[str]:
        return [path for path in self._files if is_code_file(path)]
