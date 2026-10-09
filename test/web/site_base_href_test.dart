import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Подстановка `flutter build` для `--base-href` в `web/index.html`.
const String _baseHrefPlaceholder = r'$FLUTTER_BASE_HREF';

/// Файлы, которых в `web/` нет: их пишет `flutter build web`.
const Set<String> _builtFiles = {'flutter_bootstrap.js'};

/// Адрес относительный: без `/` в начале и без схемы. Такой адрес
/// разрешается от `<base href>` страницы, то есть от адреса сайта.
bool _isRelative(String url) =>
    !url.startsWith('/') && !RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(url);

/// Проверяет, что [url] относительный и ведёт на файл из `web/`.
void _expectSiteFile(String url) {
  expect(_isRelative(url), isTrue, reason: url);
  if (!_builtFiles.contains(url)) {
    expect(File('web/$url').existsSync(), isTrue, reason: url);
  }
}

void main() {
  late String html;

  setUpAll(() => html = File('web/index.html').readAsStringSync());

  test(
    'UC-30-P-01: <base href> в web/index.html — из параметра сборки '
    '--base-href',
    () {
      final bases = RegExp(r'<base\s+href="([^"]*)"').allMatches(html);

      expect(bases.map((match) => match.group(1)), [_baseHrefPlaceholder]);
    },
  );

  test(
    'UC-30-P-01: адреса в web/index.html относительные и ведут в web/',
    () {
      // Значение атрибута — в двойных или одинарных кавычках.
      final urls = RegExp(r"""\s(?:href|src)=(["'])(.*?)\1""")
          .allMatches(html)
          .map((match) => match.group(2)!)
          .where((url) => url != _baseHrefPlaceholder)
          .toList();

      expect(urls, isNotEmpty);
      urls.forEach(_expectSiteFile);
    },
  );

  test(
    'UC-30-P-01: адреса в web/manifest.json относительные и ведут в web/',
    () {
      final manifest =
          jsonDecode(File('web/manifest.json').readAsStringSync())
              as Map<String, Object?>;

      for (final key in ['start_url', 'scope']) {
        final url = manifest[key];
        if (url != null) {
          expect(_isRelative(url as String), isTrue, reason: '$key: $url');
        }
      }
      final icons = (manifest['icons']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(icons, isNotEmpty);
      for (final icon in icons) {
        _expectSiteFile(icon['src']! as String);
      }
    },
  );

  test(
    'UC-30-P-01: воркер Python грузится с адреса сайта — адрес '
    'относительный',
    () {
      // PyodideRuntime на VM не импортируется (dart:js_interop), поэтому
      // значение берётся из исходника.
      final source = File(
        'lib/core/python_runtime/pyodide_runtime.dart',
      ).readAsStringSync();
      final match = RegExp(
        r"defaultWorkerUrl\s*=\s*'([^']*)'",
      ).firstMatch(source);

      expect(match, isNotNull);
      _expectSiteFile(match!.group(1)!);
    },
  );
}
