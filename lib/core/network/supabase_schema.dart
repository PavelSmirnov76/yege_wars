/// Имена таблиц Postgres, к которым обращается клиент.
abstract final class SupabaseTables {
  /// Профили пользователей (1:1 с `auth.users`).
  static const String profiles = 'profiles';

  /// Статьи справочника.
  static const String referenceArticles = 'reference_articles';

  /// Связь «задача — статья справочника».
  static const String taskReferences = 'task_references';

  /// Опубликованные задачи без эталона и разбора — то, что видит ученик.
  static const String tasksPublic = 'tasks_public';

  /// Файлы данных задач.
  static const String taskFiles = 'task_files';

  /// Попытки решения.
  static const String submissions = 'submissions';
}

/// Колонки таблицы [SupabaseTables.profiles].
abstract final class ProfileColumns {
  /// Идентификатор пользователя.
  static const String id = 'id';

  /// Логин.
  static const String username = 'username';

  /// Роль: `student` или `admin`.
  static const String role = 'role';
}

/// Колонки таблицы [SupabaseTables.referenceArticles].
abstract final class ArticleColumns {
  /// Человекочитаемый идентификатор статьи.
  static const String slug = 'slug';

  /// Заголовок.
  static const String title = 'title';

  /// Одно предложение для карточки.
  static const String summary = 'summary';

  /// Текст статьи в markdown.
  static const String contentMd = 'content_md';

  /// Номера заданий ЕГЭ.
  static const String egeNumbers = 'ege_numbers';

  /// Теги.
  static const String tags = 'tags';

  /// Уровень сложности (1–3).
  static const String level = 'level';

  /// Оценка времени чтения в минутах.
  static const String readingMinutes = 'reading_minutes';
}

/// Колонки представления [SupabaseTables.tasksPublic].
abstract final class TaskColumns {
  /// Идентификатор задачи.
  static const String id = 'id';

  /// Человекочитаемый идентификатор.
  static const String slug = 'slug';

  /// Номер задания ЕГЭ.
  static const String egeNumber = 'ege_number';

  /// Название.
  static const String title = 'title';

  /// Условие в markdown.
  static const String statementMd = 'statement_md';

  /// Сложность (1–3).
  static const String difficulty = 'difficulty';

  /// Формат ответа.
  static const String answerFormat = 'answer_format';

  /// Теги.
  static const String tags = 'tags';

  /// Источник задачи.
  static const String source = 'source';
}

/// Колонки таблицы [SupabaseTables.taskFiles].
abstract final class TaskFileColumns {
  /// Задача, которой принадлежит файл.
  static const String taskId = 'task_id';

  /// Имя файла.
  static const String filename = 'filename';

  /// Содержимое.
  static const String content = 'content';

  /// Размер в байтах.
  static const String sizeBytes = 'size_bytes';

  /// Порядок показа.
  static const String sortOrder = 'sort_order';
}

/// Колонки таблицы [SupabaseTables.taskReferences].
abstract final class TaskReferenceColumns {
  /// Задача.
  static const String taskId = 'task_id';

  /// Значимость статьи: primary или related.
  static const String relevance = 'relevance';

  /// Порядок показа.
  static const String sortOrder = 'sort_order';
}

/// Колонки таблицы [SupabaseTables.submissions].
abstract final class SubmissionColumns {
  /// Автор попытки.
  static const String userId = 'user_id';

  /// Задача.
  static const String taskId = 'task_id';

  /// Верна ли попытка.
  static const String isCorrect = 'is_correct';
}

/// Поля результата функции `get_task_stats`.
abstract final class TaskStatsColumns {
  /// Задача.
  static const String taskId = 'task_id';

  /// Сколько учеников пробовали.
  static const String attemptedStudents = 'attempted_students';

  /// Сколько решили.
  static const String solvedStudents = 'solved_students';

  /// Доля решивших, проценты.
  static const String solvedPercent = 'solved_percent';
}

/// Имена RPC-функций Supabase.
abstract final class SupabaseRpc {
  /// Открыта ли регистрация (доступна и до входа).
  static const String isRegistrationOpen = 'is_registration_open';

  /// Статистика решений по опубликованным задачам.
  static const String getTaskStats = 'get_task_stats';
}
