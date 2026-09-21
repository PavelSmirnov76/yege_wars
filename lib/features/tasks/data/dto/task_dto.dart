import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_brief.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_file.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_stats.dart';

/// Разбор строк задач, файлов, связей со справочником и статистики.
///
/// Ошибка формата — расхождение контракта с базой, поэтому наружу летит
/// [FormatException], а репозиторий превращает её в понятное сообщение.
abstract final class TaskDto {
  /// Карточка задачи из представления `tasks_public`.
  static TaskBrief toBrief(Map<String, dynamic> json) {
    final id = json[TaskColumns.id];
    final slug = json[TaskColumns.slug];
    final title = json[TaskColumns.title];
    final egeNumber = json[TaskColumns.egeNumber];
    if (id is! String || slug is! String || title is! String) {
      throw FormatException('Некорректная строка задачи', json);
    }
    return TaskBrief(
      id: id,
      slug: slug,
      egeNumber: egeNumber is num ? egeNumber.toInt() : null,
      title: title,
      difficulty: TaskDifficulty.fromValue(
        (json[TaskColumns.difficulty] as num?)?.toInt(),
      ),
      tags: _stringList(json[TaskColumns.tags]),
    );
  }

  /// Задача целиком.
  static TaskDetail toDetail(
    Map<String, dynamic> json, {
    required List<TaskFile> files,
    required List<TaskArticleLink> articles,
  }) => TaskDetail(
    brief: toBrief(json),
    statementMd: json[TaskColumns.statementMd] as String? ?? '',
    answerFormat: json[TaskColumns.answerFormat] as String? ?? 'single',
    files: files,
    articles: articles,
    source: json[TaskColumns.source] as String?,
  );

  /// Файл данных задачи.
  static TaskFile toFile(Map<String, dynamic> json) {
    final filename = json[TaskFileColumns.filename];
    if (filename is! String) {
      throw FormatException('Некорректная строка файла задачи', json);
    }
    final content = json[TaskFileColumns.content] as String? ?? '';
    return TaskFile(
      filename: filename,
      content: content,
      sizeBytes:
          (json[TaskFileColumns.sizeBytes] as num?)?.toInt() ?? content.length,
    );
  }

  /// Связь со статьёй справочника (вложенная выборка).
  static TaskArticleLink? toArticleLink(Map<String, dynamic> json) {
    final article = json[SupabaseTables.referenceArticles];
    if (article is! Map<String, dynamic>) {
      return null;
    }
    final slug = article[ArticleColumns.slug];
    final title = article[ArticleColumns.title];
    if (slug is! String || title is! String) {
      return null;
    }
    return TaskArticleLink(
      article: ArticleBrief(
        slug: slug,
        title: title,
        summary: article[ArticleColumns.summary] as String? ?? '',
        level: ArticleLevel.fromValue(
          (article[ArticleColumns.level] as num?)?.toInt(),
        ),
        readingMinutes:
            (article[ArticleColumns.readingMinutes] as num?)?.toInt() ?? 0,
        egeNumbers: _intList(article[ArticleColumns.egeNumbers]),
        tags: _stringList(article[ArticleColumns.tags]),
      ),
      relevance: ArticleRelevance.fromValue(
        json[TaskReferenceColumns.relevance] as String?,
      ),
    );
  }

  /// Статистика задачи из `get_task_stats`.
  static MapEntry<String, TaskStats>? toStatsEntry(Map<String, dynamic> json) {
    final taskId = json[TaskStatsColumns.taskId];
    if (taskId is! String) {
      return null;
    }
    return MapEntry(
      taskId,
      TaskStats(
        attemptedStudents:
            (json[TaskStatsColumns.attemptedStudents] as num?)?.toInt() ?? 0,
        solvedStudents:
            (json[TaskStatsColumns.solvedStudents] as num?)?.toInt() ?? 0,
        solvedPercent:
            (json[TaskStatsColumns.solvedPercent] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  /// Числа из массива jsonb.
  static List<int> _intList(Object? value) => value is List
      ? value.whereType<num>().map((item) => item.toInt()).toList()
      : const [];

  /// Строки из массива jsonb.
  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}
