import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/tasks/domain/entities/answer_format.dart';
import 'package:yege_wars/features/tasks/domain/entities/catalog_item.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_brief.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_file.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_stats.dart';
import 'package:yege_wars/features/tasks/domain/repositories/tasks_repository.dart';

/// Задача 24-го номера для тестов.
const TaskBrief testTask24 = TaskBrief(
  id: 'task-24',
  slug: 'e24-longest-run',
  egeNumber: 24,
  title: 'Наибольший фрагмент без запретного сочетания',
  difficulty: TaskDifficulty.medium,
  tags: ['strings'],
);

/// Задача 17-го номера для тестов.
const TaskBrief testTask17 = TaskBrief(
  id: 'task-17',
  slug: 'e17-pairs-file',
  egeNumber: 17,
  title: 'Пары чисел из файла',
  difficulty: TaskDifficulty.easy,
);

/// Задача банка ФИПИ без номера КИМ.
const TaskBrief testTaskNoNumber = TaskBrief(
  id: 'task-none',
  slug: 'fipi-48f84f',
  egeNumber: null,
  title: 'Задание банка без номера',
  difficulty: TaskDifficulty.hard,
  tags: ['3.13'],
);

/// Строка каталога: решённая задача 17.
const CatalogItem testSolvedItem = CatalogItem(
  task: testTask17,
  progress: TaskProgress.solved,
  stats: TaskStats(attemptedStudents: 4, solvedStudents: 3, solvedPercent: 75),
);

/// Строка каталога: нерешённая задача 24.
const CatalogItem testFreshItem = CatalogItem(task: testTask24);

/// Строка каталога: задача без номера КИМ.
const CatalogItem testNoNumberItem = CatalogItem(task: testTaskNoNumber);

/// Задача целиком с файлом и статьёй справочника.
const TaskDetail testTaskDetail = TaskDetail(
  brief: testTask24,
  statementMd: '## Условие\n\nНайдите наибольший фрагмент.',
  answerFormat: AnswerFormat.single,
  source: 'Оригинальная задача',
  files: [
    TaskFile(filename: '24.txt', content: 'ABCABC\nBBB\n', sizeBytes: 11),
  ],
  articles: [
    TaskArticleLink(
      article: ArticleBrief(
        slug: 'string-scan',
        title: 'Проход по строке окном',
        summary: 'Как посчитать фрагменты за один проход.',
        level: ArticleLevel.basic,
        readingMinutes: 7,
      ),
      relevance: ArticleRelevance.primary,
    ),
  ],
);

/// Репозиторий каталога для тестов.
final class FakeTasksRepository implements TasksRepository {
  /// Что вернёт [listCatalog].
  Result<List<CatalogItem>> catalogResult = const Ok([
    testSolvedItem,
    testFreshItem,
  ]);

  /// Что вернёт [getTask].
  Result<TaskDetail> taskResult = const Ok(testTaskDetail);

  /// Что вернёт [availableEgeNumbers].
  Result<List<int>> egeNumbersResult = const Ok([17, 24]);

  /// Фильтр последнего вызова [listCatalog].
  TaskFilter? lastFilter;

  /// Сколько раз запрашивался каталог.
  int listCalls = 0;

  /// slug последней запрошенной задачи.
  String? lastSlug;

  @override
  FutureResult<List<CatalogItem>> listCatalog(TaskFilter filter) async {
    listCalls++;
    lastFilter = filter;
    return catalogResult;
  }

  @override
  FutureResult<TaskDetail> getTask(String slug) async {
    lastSlug = slug;
    return taskResult;
  }

  @override
  FutureResult<List<int>> availableEgeNumbers() async => egeNumbersResult;
}
