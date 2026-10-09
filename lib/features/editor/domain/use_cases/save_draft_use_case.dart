import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/editor/domain/repositories/draft_repository.dart';

/// Сохранение черновика кода.
///
/// Код из одних пробельных символов не хранится: черновик удаляется, и при
/// следующем открытии задачи поле кода пустое.
///
/// Реализует UC-31.
final class SaveDraftUseCase {
  /// Создаёт use case поверх [DraftRepository].
  const SaveDraftUseCase(this._repository);

  final DraftRepository _repository;

  /// Сохраняет [code] черновиком задачи [taskId].
  FutureResult<void> call({required String taskId, required String code}) =>
      code.trim().isEmpty
      ? _repository.delete(taskId)
      : _repository.save(taskId, code);
}
