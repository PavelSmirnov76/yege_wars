import 'package:yege_wars/core/error/result.dart';

/// Черновики кода в базе: у пользователя по задаче — один.
///
/// Черновик видит и меняет только его автор; в браузере он не хранится.
///
/// Реализует UC-31.
abstract interface class DraftRepository {
  /// Черновик своей задачи [taskId]; `null`, если черновика нет.
  FutureResult<String?> load(String taskId);

  /// Записывает [code] черновиком задачи [taskId] поверх прежнего.
  FutureResult<void> save(String taskId, String code);

  /// Удаляет черновик задачи [taskId].
  FutureResult<void> delete(String taskId);
}
