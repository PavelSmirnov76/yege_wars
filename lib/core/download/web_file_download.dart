import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Отдаёт файл на скачивание браузеру.
///
/// Содержимое уже в памяти (оно пришло из базы вместе с задачей), поэтому
/// файл собирается на месте, а не запрашивается заново.
bool downloadTextFile({required String filename, required String content}) {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: 'text/plain;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  (web.document.createElement('a') as web.HTMLAnchorElement)
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
  return true;
}
