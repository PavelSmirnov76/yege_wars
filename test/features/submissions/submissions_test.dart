import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/submissions/data/datasources/submissions_remote_data_source.dart';
import 'package:yege_wars/features/submissions/data/repositories/submissions_repository_impl.dart';
import 'package:yege_wars/features/submissions/domain/use_cases/submit_answer_use_case.dart';
import 'package:yege_wars/features/submissions/presentation/controllers/submissions_controllers.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/attempts_list.dart';
import 'package:yege_wars/features/submissions/submissions_providers.dart';

import '../../helpers/fake_submissions_repository.dart';

class _MockDataSource extends Mock implements SubmissionsRemoteDataSource {}

void main() {
  group('SubmissionsRepositoryImpl', () {
    late _MockDataSource dataSource;
    late SubmissionsRepositoryImpl repository;

    setUp(() {
      dataSource = _MockDataSource();
      repository = SubmissionsRepositoryImpl(dataSource);
    });

    test('вердикт приходит из базы', () async {
      when(
        () => dataSource.submit(
          taskId: 'task-24',
          answer: '446',
          code: 'print(446)',
        ),
      ).thenAnswer(
        (_) async => {'is_correct': true, 'submission_id': 'attempt-1'},
      );

      final result = await repository.submit(
        taskId: 'task-24',
        answer: '446',
        code: 'print(446)',
      );

      expect(result.valueOrNull?.isCorrect, isTrue);
      expect(result.valueOrNull?.submissionId, 'attempt-1');
    });

    test('ошибка базы с кодом превращается в понятный текст', () async {
      when(
        () => dataSource.submit(
          taskId: 'task-24',
          answer: '446',
          code: '',
        ),
      ).thenThrow(
        const PostgrestException(
          message: '[rate_limit] Слишком много отправок, подождите минуту.',
        ),
      );

      final result = await repository.submit(taskId: 'task-24', answer: '446');

      expect(
        result.failureOrNull?.message,
        'Слишком много отправок, подождите минуту.',
      );
    });

    test('свои попытки разбираются вместе с датой', () async {
      when(() => dataSource.fetchMyAttempts('task-24')).thenAnswer(
        (_) async => [
          {
            'id': 'attempt-1',
            'answer': '446',
            'code': 'print(446)',
            'is_correct': true,
            'is_published': false,
            'created_at': '2026-09-18T07:30:00+00:00',
          },
        ],
      );

      final attempts = (await repository.myAttempts('task-24')).valueOrNull!;

      expect(attempts.single.isCorrect, isTrue);
      expect(attempts.single.canPublish, isTrue);
      expect(attempts.single.createdAt.isUtc, isFalse);
    });

    test('у чужого решения виден логин автора', () async {
      when(() => dataSource.fetchPublishedSolutions('task-24')).thenAnswer(
        (_) async => [
          {
            'id': 'solution-1',
            'answer': '446',
            'code': 'print(446)',
            'is_correct': true,
            'is_published': true,
            'created_at': '2026-09-18T07:30:00+00:00',
            'profiles': {'username': 'masha'},
          },
        ],
      );

      final solutions = (await repository.publishedSolutions(
        'task-24',
      )).valueOrNull!;

      expect(solutions.single.authorUsername, 'masha');
    });

    test('публикация доходит до RPC', () async {
      when(
        () => dataSource.setPublished(
          submissionId: 'attempt-1',
          isPublished: true,
        ),
      ).thenAnswer((_) async {});

      final result = await repository.setPublished(
        submissionId: 'attempt-1',
        isPublished: true,
      );

      expect(result.isOk, isTrue);
      verify(
        () => dataSource.setPublished(
          submissionId: 'attempt-1',
          isPublished: true,
        ),
      ).called(1);
    });
  });

  group('SubmitAnswerUseCase', () {
    late FakeSubmissionsRepository repository;

    setUp(() => repository = FakeSubmissionsRepository());

    test('пустой ответ до сервера не доходит', () async {
      final result = await SubmitAnswerUseCase(repository)(
        taskId: 'task-24',
        answer: '   ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.submitCalls, 0);
    });

    test('непустой ответ уходит в репозиторий', () async {
      await SubmitAnswerUseCase(repository)(
        taskId: 'task-24',
        answer: '446',
        code: 'print(446)',
      );

      expect(repository.submitCalls, 1);
      expect(repository.lastAnswer, '446');
      expect(repository.lastCode, 'print(446)');
    });

    test('ответ уходит без пробельных краёв, включая переводы строк', () async {
      await SubmitAnswerUseCase(repository)(
        taskId: 'task-25',
        answer: ' \t108 54 136 68\r\n\n',
      );

      expect(repository.lastAnswer, '108 54 136 68');
    });

    test('ответ из одних переводов строк считается пустым', () async {
      final result = await SubmitAnswerUseCase(repository)(
        taskId: 'task-24',
        answer: '\n\r\n\t',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.submitCalls, 0);
    });
  });

  group('SubmitController', () {
    late FakeSubmissionsRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeSubmissionsRepository();
      container = ProviderContainer(
        overrides: [
          submissionsRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('успешная отправка кладёт вердикт в состояние', () async {
      await container
          .read(submitControllerProvider('task-24').notifier)
          .submit(answer: '446', code: 'print(446)');

      final state = container.read(submitControllerProvider('task-24'));
      expect(state.result?.isCorrect, isTrue);
      expect(state.isSubmitting, isFalse);
    });

    test('ошибка отправки видна в состоянии', () async {
      repository.submitResult = const Err(
        DatabaseFailure(message: 'Слишком много отправок, подождите минуту.'),
      );

      await container
          .read(submitControllerProvider('task-24').notifier)
          .submit(answer: '446');

      expect(
        container.read(submitControllerProvider('task-24')).failure?.message,
        'Слишком много отправок, подождите минуту.',
      );
    });

    test('сброс убирает вердикт', () async {
      final notifier = container.read(
        submitControllerProvider('task-24').notifier,
      );
      await notifier.submit(answer: '446');

      notifier.reset();

      expect(
        container.read(submitControllerProvider('task-24')).result,
        isNull,
      );
    });

    test('публикация зовёт репозиторий', () async {
      await container
          .read(publishControllerProvider('task-24').notifier)
          .setPublished(submissionId: 'attempt-ok', isPublished: true);

      expect(repository.lastPublishedId, 'attempt-ok');
      expect(repository.lastPublishedValue, isTrue);
    });
  });

  test('время попытки выводится коротко', () {
    expect(attemptTimeLabel(DateTime(2026, 9, 18, 7, 5)), '18.09 07:05');
  });
}
