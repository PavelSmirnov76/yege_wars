import 'package:meta/meta.dart';

/// Файл данных задачи.
///
/// Содержимое хранится в базе: на экзамене программа открывает файл по
/// имени, поэтому имя важно так же, как и текст.
@immutable
final class TaskFile {
  /// Создаёт файл.
  const TaskFile({
    required this.filename,
    required this.content,
    required this.sizeBytes,
  });

  /// Имя файла, например `24.txt`.
  final String filename;

  /// Содержимое файла.
  final String content;

  /// Размер в байтах.
  final int sizeBytes;
}
