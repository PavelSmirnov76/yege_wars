import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/profile/data/progress_repository.dart';
import 'package:yege_wars/features/profile/domain/progress.dart';

import '../../helpers/recording_supabase_client.dart';

class FakeSource implements ProgressDataSource {
  List<Map<String, dynamic>> numberRows = [];
  List<Map<String, dynamic>> attemptRows = [];
  bool failProgress = false;
  bool failAttempts = false;
  int progressCalls = 0;
  int attemptCalls = 0;
  @override
  SupabaseClient get client => throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> progress(String userId) async {
    progressCalls++;
    if (failProgress) throw const FormatException();
    return numberRows;
  }

  @override
  Future<List<Map<String, dynamic>>> attempts(String userId) async {
    attemptCalls++;
    if (failAttempts) throw const FormatException();
    return attemptRows;
  }
}

void main() {
  test(
    'UC-41-P-01: запросы ограничены текущим автором и опубликованной задачей',
    () async {
      final client = RecordingSupabaseClient();
      addTearDown(client.dispose);
      final source = ProgressDataSource(client.client);
      await source.progress('account-a');
      expect(client.requests.single.body, contains('account-a'));
      await source.attempts('account-a');
      final uri = client.requests.last.url;
      expect(uri.path, '/rest/v1/submissions');
      expect(uri.queryParameters['user_id'], 'eq.account-a');
      expect(uri.queryParameters['task.status'], 'eq.published');
      expect(
        uri.queryParameters['order'],
        'created_at.desc.nullslast,id.desc.nullslast',
      );
      expect(uri.queryParameters['limit'], '10');
      expect(uri.queryParameters['select'], contains('task:tasks!inner('));
    },
  );

  test('UC-41-P-04: ошибка 503 не вызывает автоматический повтор', () async {
    var calls = 0;
    final client = SupabaseClient(
      'http://localhost',
      'test-anon-key',
      httpClient: MockClient((request) async {
        calls++;
        return http.Response('unavailable', 503, request: request);
      }),
    );
    addTearDown(client.dispose);
    await expectLater(
      ProgressDataSource(client).attempts('account-a'),
      throwsA(isA<PostgrestException>()),
    );
    expect(calls, 1);
  });

  test('UC-41-P-01: суммы включают группу без номера', () async {
    final source = FakeSource()
      ..numberRows = [
        {'ege_number': null, 'solved': 0, 'total': 1},
        {'ege_number': 24, 'solved': 1, 'total': 2},
      ];
    final result = await ProgressRepositoryImpl(source).getProgress('a');
    final summary = result.valueOrNull!;
    expect(summary.solved, 1);
    expect(summary.total, 3);
    expect(summary.byNumber.map((e) => e.number), [24, null]);
  });

  test('UC-41-P-03: пустой список даёт нулевые суммы', () async {
    final summary = (await ProgressRepositoryImpl(
      FakeSource(),
    ).getProgress('a')).valueOrNull!;
    expect(summary.solved, 0);
    expect(summary.total, 0);
    expect(summary.attempts, isEmpty);
  });

  for (final progressFails in [true, false]) {
    test(
      'UC-41-P-04 UC-41-P-05: ошибка '
      '${progressFails ? 'RPC' : 'попыток'} и повтор обоих запросов',
      () async {
        final source = FakeSource()
          ..failProgress = progressFails
          ..failAttempts = !progressFails;
        final repository = ProgressRepositoryImpl(source);
        expect(
          (await repository.getProgress('a')).failureOrNull,
          isA<DatabaseFailure>(),
        );
        source
          ..failProgress = false
          ..failAttempts = false;
        expect(await repository.getProgress('a'), isA<Ok<ProgressSummary>>());
        expect(source.progressCalls, 2);
        expect(source.attemptCalls, 2);
      },
    );
  }
}
