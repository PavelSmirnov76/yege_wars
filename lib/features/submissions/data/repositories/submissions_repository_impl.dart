import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/network/supabase_error_mapper.dart';
import 'package:yege_wars/features/submissions/data/datasources/submissions_remote_data_source.dart';
import 'package:yege_wars/features/submissions/data/dto/submission_dto.dart';
import 'package:yege_wars/features/submissions/domain/entities/submission.dart';
import 'package:yege_wars/features/submissions/domain/entities/submit_result.dart';
import 'package:yege_wars/features/submissions/domain/repositories/submissions_repository.dart';

/// Реализация [SubmissionsRepository] поверх
/// [SubmissionsRemoteDataSource].
///
/// Реализует UC-19.
final class SubmissionsRepositoryImpl implements SubmissionsRepository {
  /// Создаёт репозиторий поверх [SubmissionsRemoteDataSource].
  const SubmissionsRepositoryImpl(this._dataSource);

  final SubmissionsRemoteDataSource _dataSource;

  @override
  FutureResult<SubmitResult> submit({
    required String taskId,
    required String answer,
    String code = '',
  }) async {
    try {
      final json = await _dataSource.submit(
        taskId: taskId,
        answer: answer,
        code: code,
      );
      return Ok<SubmitResult>(SubmissionDto.toSubmitResult(json));
    } on Object catch (error) {
      return Err<SubmitResult>(SupabaseErrorMapper.map(error));
    }
  }

  @override
  FutureResult<List<Submission>> myAttempts(String taskId) =>
      _list(() => _dataSource.fetchMyAttempts(taskId));

  @override
  FutureResult<List<Submission>> publishedSolutions(String taskId) =>
      _list(() => _dataSource.fetchPublishedSolutions(taskId));

  @override
  FutureResult<void> setPublished({
    required String submissionId,
    required bool isPublished,
  }) async {
    try {
      await _dataSource.setPublished(
        submissionId: submissionId,
        isPublished: isPublished,
      );
      return const Ok<void>(null);
    } on Object catch (error) {
      return Err<void>(SupabaseErrorMapper.map(error));
    }
  }

  /// Общая обёртка для списков попыток.
  Future<Result<List<Submission>>> _list(
    Future<List<Map<String, dynamic>>> Function() fetch,
  ) async {
    try {
      final rows = await fetch();
      return Ok<List<Submission>>([
        for (final row in rows) SubmissionDto.toSubmission(row),
      ]);
    } on Object catch (error) {
      return Err<List<Submission>>(SupabaseErrorMapper.map(error));
    }
  }
}
