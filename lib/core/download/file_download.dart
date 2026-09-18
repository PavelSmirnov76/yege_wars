/// Скачивание текстового файла.
///
/// Реализация выбирается на этапе сборки: в браузере — через Blob,
/// в тестах на виртуальной машине Dart — заглушка, возвращающая `false`.
library;

export 'unsupported_file_download.dart'
    if (dart.library.js_interop) 'web_file_download.dart';
