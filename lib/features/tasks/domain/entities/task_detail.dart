import 'package:meta/meta.dart';
import 'package:yege_wars/features/tasks/domain/entities/answer_format.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_brief.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_file.dart';

/// Задача целиком: условие, файлы и справка.
@immutable
final class TaskDetail {
  /// Создаёт задачу.
  const TaskDetail({
    required this.brief,
    required this.statementMd,
    required this.answerFormat,
    this.files = const [],
    this.articles = const [],
    this.source,
  });

  /// Карточка задачи.
  final TaskBrief brief;

  /// Условие в markdown.
  final String statementMd;

  /// Формат ответа.
  final AnswerFormat answerFormat;

  /// Файлы данных.
  final List<TaskFile> files;

  /// Статьи справочника: сначала главные по теме.
  final List<TaskArticleLink> articles;

  /// Источник задачи.
  final String? source;

  /// Главные по теме статьи.
  List<TaskArticleLink> get primaryArticles =>
      articles.where((link) => link.isPrimary).toList();
}
