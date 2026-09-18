import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/markdown/python_highlighter.dart';

/// Собирает текст фрагментов обратно — он обязан совпасть с исходным кодом.
String joined(List<CodeToken> tokens) => tokens.map((t) => t.text).join();

/// Фрагменты указанной роли.
List<String> ofKind(List<CodeToken> tokens, CodeTokenKind kind) =>
    tokens.where((t) => t.kind == kind).map((t) => t.text).toList();

void main() {
  group('PythonHighlighter', () {
    test('разбор ничего не теряет', () {
      const code = '''
# считаем длину
with open('24.txt') as f:
    data = f.read().strip()
print(len(data), 3.14, 0xFF)
''';
      expect(joined(PythonHighlighter.highlight(code)), code);
    });

    test('ключевые слова и встроенные функции', () {
      final tokens = PythonHighlighter.highlight(
        'for x in range(10): print(x)',
      );

      expect(ofKind(tokens, CodeTokenKind.keyword), ['for', 'in']);
      expect(ofKind(tokens, CodeTokenKind.builtin), ['range', 'print']);
    });

    test('имя, похожее на ключевое слово, не подсвечивается', () {
      final tokens = PythonHighlighter.highlight('formula = information');

      expect(ofKind(tokens, CodeTokenKind.keyword), isEmpty);
      expect(ofKind(tokens, CodeTokenKind.builtin), isEmpty);
    });

    test('строки: одинарные, двойные и тройные', () {
      final tokens = PythonHighlighter.highlight(
        'a = "текст" + \'ещё\' + """много\nстрок"""',
      );

      expect(ofKind(tokens, CodeTokenKind.string), [
        '"текст"',
        "'ещё'",
        '"""много\nстрок"""',
      ]);
    });

    test('экранированная кавычка не закрывает строку', () {
      final tokens = PythonHighlighter.highlight(r"s = 'не \' конец'");

      expect(ofKind(tokens, CodeTokenKind.string), [r"'не \' конец'"]);
    });

    test('незакрытая строка не ломает разбор', () {
      const code = "s = 'оборвалась";
      final tokens = PythonHighlighter.highlight(code);

      expect(joined(tokens), code);
      expect(ofKind(tokens, CodeTokenKind.string), ["'оборвалась"]);
    });

    test('одинарная строка не переносится на следующую строку', () {
      final tokens = PythonHighlighter.highlight("s = 'a\nb = 2");

      expect(ofKind(tokens, CodeTokenKind.string), ["'a"]);
    });

    test('комментарий идёт до конца строки', () {
      final tokens = PythonHighlighter.highlight('x = 1  # это x\ny = 2');

      expect(ofKind(tokens, CodeTokenKind.comment), ['# это x']);
      expect(ofKind(tokens, CodeTokenKind.number), ['1', '2']);
    });

    test('числа: целые, дробные, шестнадцатеричные', () {
      final tokens = PythonHighlighter.highlight('a = 10 + 3.5 + 0xFF + 1e3');

      expect(ofKind(tokens, CodeTokenKind.number), [
        '10',
        '3.5',
        '0xFF',
        '1e3',
      ]);
    });

    test('цифра внутри имени числом не считается', () {
      final tokens = PythonHighlighter.highlight('task24 = 1');

      expect(ofKind(tokens, CodeTokenKind.number), ['1']);
    });

    test('пустой код даёт пустой разбор', () {
      expect(PythonHighlighter.highlight(''), isEmpty);
    });
  });
}
