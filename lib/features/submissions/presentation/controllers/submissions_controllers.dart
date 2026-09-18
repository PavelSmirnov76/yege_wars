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
@riverpod
class PublishController extends _$PublishController {
  @override
  Failure? build(String taskId) => null;

  /// Публикует или снимает с публикации попытку [submissionId].
  Future<void> setPublished({
    required String submissionId,
    required bool isPublished,
  }) async {
    final result = await ref
        .read(submissionsRepositoryProvider)
        .setPublished(submissionId: submissionId, isPublished: isPublished);
    if (!ref.mounted) {
      return;
    }
    state = result.failureOrNull;
    if (result.isOk) {
      ref.invalidate(myAttemptsProvider(taskId));
    }
  }
}
