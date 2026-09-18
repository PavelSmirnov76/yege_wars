import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/submissions/domain/entities/submission.dart';
import 'package:yege_wars/features/submissions/domain/entities/submit_result.dart';

/// Разбор строк попыток и ответа RPC отправки.
abstract final class SubmissionDto {
  /// Попытка из строки таблицы `submissions`.
  ///
  /// Логин автора приходит вложенной выборкой и есть только у чужих
  /// опубликованных решений.
  static Submission toSubmission(Map<String, dynamic> json) {
    final id = json[SubmissionColumns.id];
    final createdAt = json[SubmissionColumns.createdAt];
    if (id is! String || createdAt is! String) {
      throw FormatException('Некорректная строка попытки', json);
    }
    final profile = json[SupabaseTables.profiles];
    return Submission(
      id: id,
      answer: json[SubmissionColumns.answer] as String? ?? '',
      code: json[SubmissionColumns.code] as String? ?? '',
      isCorrect: json[SubmissionColumns.isCorrect] == true,
      isPublished: json[SubmissionColumns.isPublished] == true,
      createdAt: DateTime.parse(createdAt).toLocal(),
      authorUsername: profile is Map<String, dynamic>
          ? profile[ProfileColumns.username] as String?
          : null,
    );
  }

  /// Итог отправки из ответа RPC `submit_solution`.
  static SubmitResult toSubmitResult(Map<String, dynamic> json) {
    final submissionId = json['submission_id'];
    if (submissionId is! String) {
      throw FormatException('Некорректный ответ проверки', json);
    }
    return SubmitResult(
      isCorrect: json['is_correct'] == true,
      submissionId: submissionId,
    );
  }
}
