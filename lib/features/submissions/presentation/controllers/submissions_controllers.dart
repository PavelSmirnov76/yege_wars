import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/features/submissions/domain/entities/submission.dart';
import 'package:yege_wars/features/submissions/domain/entities/submit_result.dart';
import 'package:yege_wars/features/submissions/submissions_providers.dart';
import 'package:yege_wars/features/tasks/presentation/controllers/catalog_controllers.dart';

part 'submissions_controllers.g.dart';

/// Состояние отправки ответа.
final class SubmitState {
  /// Создаёт состояние.
  const SubmitState({this.isSubmitting = false, this.result, this.failure});

  /// Идёт ли отправка.
  final bool isSubmitting;

  /// Итог последней отправки.
  final SubmitResult? result;

  /// Ошибка отправки (пустой ответ, лимит частоты, сеть).
  final Failure? failure;
}

/// Отправка ответа по задаче.
///
/// Реализует UC-19.
@riverpod
class SubmitController extends _$SubmitController {
  @override
  SubmitState build(String taskId) => const SubmitState();

  /// Отправляет [answer] вместе с кодом [code].
  Future<void> submit({required String answer, String code = ''}) async {
    state = const SubmitState(isSubmitting: true);

    final result = await ref.read(submitAnswerUseCaseProvider)(
      taskId: taskId,
      answer: answer,
      code: code,
    );
    if (!ref.mounted) {
      return;
    }

    state = result.fold(
      onOk: (value) => SubmitState(result: value),
      onErr: (failure) => SubmitState(failure: failure),
    );

    if (result.isOk) {
      // Попытка появилась в базе: список попыток и каталог устарели.
      ref
        ..invalidate(myAttemptsProvider(taskId))
        ..invalidate(publishedSolutionsProvider(taskId))
        ..invalidate(catalogProvider);
    }
  }

  /// Убирает вердикт прошлой отправки.
  void reset() => state = const SubmitState();
}

/// Мои попытки по задаче, сначала свежие.
///
/// Реализует UC-34.
@riverpod
Future<List<Submission>> myAttempts(Ref ref, String taskId) async {
  final result = await ref
      .watch(submissionsRepositoryProvider)
      .myAttempts(taskId);
  return result.fold(
    onOk: (attempts) => attempts,
    onErr: (failure) => throw failure,
  );
}

/// Опубликованные решения других учеников.
///
/// База отдаёт их только тому, кто сам верно решил задачу, поэтому пустой
/// список — обычное дело, а не ошибка.
///
/// Реализует UC-35.
@riverpod
Future<List<Submission>> publishedSolutions(Ref ref, String taskId) async {
  final result = await ref
      .watch(submissionsRepositoryProvider)
      .publishedSolutions(taskId);
  return result.fold(
    onOk: (solutions) => solutions,
    onErr: (failure) => throw failure,
  );
}

/// Публикация своих верных решений.
///
/// Исход отдаётся тому, кто публиковал: блок «Задача решена!» показывает
/// сбой под своими кнопками, переключатель «Опубликовано» — сообщением внизу
/// экрана. Контроллер никто не слушает, поэтому на время запроса он держит
/// себя живым: иначе он исчез бы до ответа и список попыток не обновился бы.
///
/// Реализует UC-33.
@riverpod
class PublishController extends _$PublishController {
  @override
  void build(String taskId) {}

  /// Публикует или снимает с публикации попытку [submissionId]; возвращает
  /// сбой или `null`, если вышло.
  Future<Failure?> setPublished({
    required String submissionId,
    required bool isPublished,
  }) async {
    final keepAlive = ref.keepAlive();
    try {
      final result = await ref
          .read(submissionsRepositoryProvider)
          .setPublished(submissionId: submissionId, isPublished: isPublished);
      if (result.isOk) {
        // Публикация изменилась — список попыток устарел.
        ref.invalidate(myAttemptsProvider(taskId));
      }
      return result.failureOrNull;
    } finally {
      keepAlive.close();
    }
  }
}
