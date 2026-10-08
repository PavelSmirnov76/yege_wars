import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';

/// Реализация [TasksRemoteDataSource] поверх [SupabaseClient].
///
/// Реализует UC-14 и UC-27.
final class SupabaseTasksRemoteDataSource implements TasksRemoteDataSource {
  /// Создаёт datasource поверх клиента [SupabaseClient].
  const SupabaseTasksRemoteDataSource(this._client);

  /// Колонки карточки задачи: условие в каталог не тянем, оно тяжёлое.
  static const String _briefColumns =
      '${TaskColumns.id}, ${TaskColumns.slug}, ${TaskColumns.egeNumber}, '
      '${TaskColumns.title}, ${TaskColumns.difficulty}, ${TaskColumns.tags}';

  /// Колонки задачи целиком.
  static const String _fullColumns =
      '$_briefColumns, ${TaskColumns.statementMd}, '
      '${TaskColumns.answerFormat}, ${TaskColumns.source}';

  /// Колонки карточки статьи справочника: одни и те же для ручных связей
  /// и для статей по темам.
  static const String _articleBriefColumns =
      '${ArticleColumns.slug}, ${ArticleColumns.title}, '
      '${ArticleColumns.summary}, ${ArticleColumns.level}, '
      '${ArticleColumns.readingMinutes}, ${ArticleColumns.egeNumbers}, '
      '${ArticleColumns.tags}';

  /// Вложенная выборка статьи справочника вместе с ручной связью.
  static const String _articleLinkColumns =
      '${TaskReferenceColumns.relevance}, ${TaskReferenceColumns.sortOrder}, '
      '${SupabaseTables.referenceArticles}($_articleBriefColumns)';

  /// Символы, ломающие синтаксис фильтра PostgREST.
  static final RegExp _unsafeSearchChars = RegExp(r'[,()*%\\"\x27]');

  final SupabaseClient _client;

  /// Готовит строку поиска к подстановке в фильтр.
  static String escapeSearch(String query) =>
      query.trim().replaceAll(_unsafeSearchChars, ' ').trim();

  @override
  Future<List<Map<String, dynamic>>> fetchTasks(TaskFilter filter) async {
    var query = _client.from(SupabaseTables.tasksPublic).select(_briefColumns);

    final egeNumber = filter.egeNumber;
    if (egeNumber != null) {
      query = query.eq(TaskColumns.egeNumber, egeNumber);
    }
    final difficulty = filter.difficulty;
    if (difficulty != null) {
      query = query.eq(TaskColumns.difficulty, difficulty.value);
    }
    final search = escapeSearch(filter.query);
    if (search.isNotEmpty) {
      query = query.ilike(TaskColumns.title, '%$search%');
    }

    // В postgrest `order()` по умолчанию сортирует по убыванию.
    return query
        .order(TaskColumns.egeNumber, ascending: true)
        .order(TaskColumns.title, ascending: true);
  }

  @override
  Future<Map<String, dynamic>?> fetchTask(String slug) => _client
      .from(SupabaseTables.tasksPublic)
      .select(_fullColumns)
      .eq(TaskColumns.slug, slug)
      .maybeSingle();

  @override
  Future<List<Map<String, dynamic>>> fetchFiles(String taskId) => _client
      .from(SupabaseTables.taskFiles)
      .select(
        '${TaskFileColumns.filename}, ${TaskFileColumns.content}, '
        '${TaskFileColumns.sizeBytes}',
      )
      .eq(TaskFileColumns.taskId, taskId)
      .order(TaskFileColumns.sortOrder, ascending: true);

  @override
  Future<List<Map<String, dynamic>>> fetchArticleLinks(String taskId) => _client
      .from(SupabaseTables.taskReferences)
      .select(_articleLinkColumns)
      .eq(TaskReferenceColumns.taskId, taskId)
      // Главные первыми ставит слияние справки, здесь — только порядок связей.
      .order(TaskReferenceColumns.sortOrder, ascending: true);

  // Встроить reference_articles в выборку из представления нельзя: у
  // представления нет внешнего ключа, и PostgREST отвечает PGRST200.
  // Поэтому статьи по темам читаются двумя запросами.
  @override
  Future<List<Map<String, dynamic>>> fetchThemeArticles(String taskId) =>
      _client
          .from(SupabaseTables.taskArticles)
          .select(
            '${TaskArticleColumns.articleId}, ${TaskArticleColumns.sortOrder}',
          )
          .eq(TaskArticleColumns.taskId, taskId)
          .order(TaskArticleColumns.sortOrder, ascending: true);

  @override
  Future<List<Map<String, dynamic>>> fetchArticles(List<String> articleIds) =>
      _client
          .from(SupabaseTables.referenceArticles)
          .select('${ArticleColumns.id}, $_articleBriefColumns')
          .inFilter(ArticleColumns.id, articleIds);

  @override
  Future<List<Map<String, dynamic>>> fetchMyAttempts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }
    // Явный фильтр по себе: политика доступа пускает ещё и к чужим
    // опубликованным решениям, а прогресс считается только по своим.
    return _client
        .from(SupabaseTables.submissions)
        .select('${SubmissionColumns.taskId}, ${SubmissionColumns.isCorrect}')
        .eq(SubmissionColumns.userId, userId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEgeNumbers() => _client
      .from(SupabaseTables.tasksPublic)
      .select(TaskColumns.egeNumber)
      .order(TaskColumns.egeNumber, ascending: true);

  @override
  Future<List<Map<String, dynamic>>> fetchStats() =>
      _client.rpc<List<Map<String, dynamic>>>(SupabaseRpc.getTaskStats);
}
