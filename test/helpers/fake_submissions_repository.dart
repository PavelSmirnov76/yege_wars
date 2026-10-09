import 'dart:async';

import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/submissions/domain/entities/submission.dart';
import 'package:yege_wars/features/submissions/domain/entities/submit_result.dart';
import 'package:yege_wars/features/submissions/domain/repositories/submissions_repository.dart';

/// Верная попытка для тестов.
final Submission testCorrectAttempt = Submission(
  id: 'attempt-ok',
  answer: '446',
  code: 'print(446)',
  isCorrect: true,
  createdAt: DateTime(2026, 9, 18, 10, 30),
);

/// Чужое опубликованное решение.
final Submission testOtherSolution = Submission(
  id: 'solution-other',
  answer: '446',
  code: 'print(446)  # чужое решение',
  isCorrect: true,
  isPublished: true,
  createdAt: DateTime(2026, 9, 18, 9),
  authorUsername: 'masha',
);

/// Репозиторий попыток для тестов.
final class FakeSubmissionsRepository implements SubmissionsRepository {
  /// Что вернёт [submit].
  Result<SubmitResult> submitResult = const Ok(
    SubmitResult(isCorrect: true, submissionId: 'attempt-ok'),
  );

  /// Что вернёт [myAttempts].
  Result<List<Submission>> attemptsResult = const Ok([]);

  /// Что вернёт [publishedSolutions].
  Result<List<Submission>> solutionsResult = const Ok([]);

  /// Что вернёт [setPublished].
  Result<void> publishResult = const Ok<void>(null);

  /// Ответ последней отправки.
  String? lastAnswer;

  /// Код последней отправки.
  String? lastCode;

  /// Сколько раз отправляли ответ.
  int submitCalls = 0;

  /// Идентификатор попытки, которую публиковали последней.
  String? lastPublishedId;

  /// Значение последней публикации.
  bool? lastPublishedValue;

  /// Пока не завершён, [setPublished] не отвечает: так база отвечает не
  /// сразу, а через несколько кадров.
  Completer<void>? publishGate;

  /// Пока не завершён, [submit] не отвечает: проверка ответа ещё идёт.
  Completer<void>? submitGate;

  /// Сколько раз запрашивались мои попытки.
  int attemptsCalls = 0;

  /// Сколько раз запрашивались решения других.
  int solutionsCalls = 0;

  @override
  FutureResult<SubmitResult> submit({
    required String taskId,
    required String answer,
    String code = '',
  }) async {
    submitCalls++;
    lastAnswer = answer;
    lastCode = code;
    await submitGate?.future;
    return submitResult;
  }

  @override
  FutureResult<List<Submission>> myAttempts(String taskId) async {
    attemptsCalls++;
    return attemptsResult;
  }

  @override
  FutureResult<List<Submission>> publishedSolutions(String taskId) async {
    solutionsCalls++;
    return solutionsResult;
  }

  @override
  FutureResult<void> setPublished({
    required String submissionId,
    required bool isPublished,
  }) async {
    lastPublishedId = submissionId;
    lastPublishedValue = isPublished;
    await publishGate?.future;
    return publishResult;
  }
}
