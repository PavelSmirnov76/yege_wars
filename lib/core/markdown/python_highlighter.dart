import 'package:meta/meta.dart';

/// Роль фрагмента кода при подсветке.
enum CodeTokenKind {
  /// Обычный текст: имена, знаки операций, пробелы.
  plain,

  /// Ключевое слово языка (`for`, `if`, `def`).
  keyword,

  /// Встроенная функция или тип (`print`, `len`, `int`).
  builtin,

  /// Строковый литерал, включая тройные кавычки.
  string,

  /// Комментарий до конца строки.
  comment,

  /// Числовой литерал.
  number,
}

/// Фрагмент кода с ролью [kind].
@immutable
final class CodeToken {
  /// Создаёт фрагмент.
  const CodeToken(this.text, this.kind);

  /// Текст фрагмента.
  final String text;

  /// Роль фрагмента.
  final CodeTokenKind kind;

  @override
  bool operator ==(Object other) =>
      other is CodeToken && other.text == text && other.kind == kind;

  @override
  int get hashCode => Object.hash(text, kind);

  @override
  String toString() => 'CodeToken(${kind.name}, "$text")';
}

/// Разбор кода на Python для подсветки.
///
/// Свой разборщик, а не пакет: язык нужен ровно один, а готовые решения
/// (`flutter_highlight`) давно не обновляются. Разбор приблизительный —
/// он не проверяет синтаксис, а лишь помечает то, что видно глазом.
abstract final class PythonHighlighter {
  /// Ключевые слова Python 3.
  static const Set<String> keywords = {
    'False',
    'None',
    'True',
    'and',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'class',
    'continue',
    'def',
    'del',
    'elif',
    'else',
    'except',
    'finally',
    'for',
    'from',
    'global',
    'if',
    'import',
    'in',
    'is',
    'lambda',
    'match',
    'nonlocal',
    'not',
    'or',
    'pass',
    'raise',
    'return',
    'try',
    'while',
    'with',
    'yield',
  };

  /// Встроенные функции и типы, которые чаще всего встречаются в решениях.
  static const Set<String> builtins = {
    'abs',
    'all',
    'any',
    'bin',
    'bool',
    'chr',
    'dict',
    'divmod',
    'enumerate',
    'filter',
    'float',
    'format',
    'frozenset',
    'hex',
    'input',
    'int',
    'isinstance',
    'len',
    'list',
    'map',
    'max',
    'min',
    'open',
    'ord',
    'pow',
    'print',
    'range',
    'reversed',
    'round',
    'set',
    'sorted',
    'str',
    'sum',
    'tuple',
    'zip',
  };

  /// Разбирает [code] на фрагменты; их склейка равна исходному тексту.
  static List<CodeToken> highlight(String code) {
    final tokens = <CodeToken>[];
    final plain = StringBuffer();
    var index = 0;

    void flushPlain() {
      if (plain.isNotEmpty) {
        tokens.add(CodeToken(plain.toString(), CodeTokenKind.plain));
        plain.clear();
      }
    }

    while (index < code.length) {
      final char = code[index];

      if (char == '#') {
        flushPlain();
        final end = _endOfLine(code, index);
        tokens.add(
          CodeToken(code.substring(index, end), CodeTokenKind.comment),
        );
        index = end;
        continue;
      }

      if (char == "'" || char == '"') {
        flushPlain();
        final end = _endOfString(code, index);
        tokens.add(
          CodeToken(code.substring(index, end), CodeTokenKind.string),
        );
        index = end;
        continue;
      }

      if (_isDigit(char) && !_isWordChar(_charAt(code, index - 1))) {
        flushPlain();
        final end = _endOfNumber(code, index);
        tokens.add(
          CodeToken(code.substring(index, end), CodeTokenKind.number),
        );
        index = end;
        continue;
      }

      if (_isWordStart(char)) {
        final end = _endOfWord(code, index);
        final word = code.substring(index, end);
        final kind = keywords.contains(word)
            ? CodeTokenKind.keyword
            : builtins.contains(word)
            ? CodeTokenKind.builtin
            : CodeTokenKind.plain;
        if (kind == CodeTokenKind.plain) {
          plain.write(word);
        } else {
          flushPlain();
          tokens.add(CodeToken(word, kind));
        }
        index = end;
        continue;
      }

      plain.write(char);
      index++;
    }

    flushPlain();
    return tokens;
  }

  /// Конец строки-комментария.
  static int _endOfLine(String code, int start) {
    final newLine = code.indexOf('\n', start);
    return newLine == -1 ? code.length : newLine;
  }

  /// Конец строкового литерала, начинающегося с [start].
  ///
  /// Незакрытая строка тянется до конца текста: подсветка не должна падать
  /// на оборванном фрагменте.
  static int _endOfString(String code, int start) {
    final quote = code[start];
    final isTriple =
        code.startsWith(quote * 3, start) && start + 3 <= code.length;
    final delimiter = isTriple ? quote * 3 : quote;
    var index = start + delimiter.length;

    while (index < code.length) {
      if (code[index] == r'\') {
        index += 2;
        continue;
      }
      if (code.startsWith(delimiter, index)) {
        return index + delimiter.length;
      }
      // Одинарная строка не переносится на следующую строку.
      if (!isTriple && code[index] == '\n') {
        return index;
      }
      index++;
    }
    return code.length;
  }

  /// Конец числового литерала.
  static int _endOfNumber(String code, int start) {
    var index = start;
    while (index < code.length) {
      final char = code[index];
      final isExponentSign =
          (char == '+' || char == '-') &&
          index > start &&
          (code[index - 1] == 'e' || code[index - 1] == 'E');
      if (_isDigit(char) ||
          char == '.' ||
          char == '_' ||
          isExponentSign ||
          _isHexLetter(char)) {
        index++;
        continue;
      }
      break;
    }
    return index;
  }

  /// Конец слова (имени или ключевого слова).
  static int _endOfWord(String code, int start) {
    var index = start;
    while (index < code.length && _isWordChar(code[index])) {
      index++;
    }
    return index;
  }

  /// Символ по индексу или пустая строка за границей текста.
  static String _charAt(String code, int index) =>
      index >= 0 && index < code.length ? code[index] : '';

  static bool _isDigit(String char) =>
      char.isNotEmpty &&
      char.codeUnitAt(0) >= 0x30 &&
      char.codeUnitAt(0) <= 0x39;

  static bool _isHexLetter(String char) =>
      'abcdefABCDEFxXoObBeE'.contains(char) && char.isNotEmpty;

  static bool _isWordStart(String char) => char == '_' || _isLetter(char);

  static bool _isWordChar(String char) =>
      char == '_' || _isLetter(char) || _isDigit(char);

  static bool _isLetter(String char) {
    if (char.isEmpty) {
      return false;
    }
    final code = char.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
  }
}
