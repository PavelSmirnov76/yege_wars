/// Хранилище черновиков кода.
///
/// Черновик привязан к задаче и живёт только на устройстве ученика: в базе
/// хранятся отправленные попытки, а не каждое нажатие клавиши.
///
/// Реализует UC-16.
abstract interface class DraftStorage {
  /// Читает черновик задачи; `null`, если его нет.
  Future<String?> read(String taskSlug);

  /// Сохраняет черновик задачи.
  Future<void> write(String taskSlug, String code);
}
