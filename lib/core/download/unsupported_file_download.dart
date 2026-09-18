/// Скачивание файла вне браузера не поддерживается.
///
/// Заглушка нужна тестам на виртуальной машине Dart: они собирают те же
/// экраны, но браузерных API там нет. Возвращает `false` — файл не отдан.
bool downloadTextFile({required String filename, required String content}) =>
    false;
