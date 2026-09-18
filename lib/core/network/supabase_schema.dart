/// Имена таблиц Postgres, к которым обращается клиент.
abstract final class SupabaseTables {
  /// Профили пользователей (1:1 с `auth.users`).
  static const String profiles = 'profiles';

  /// Статьи справочника.
  static const String referenceArticles = 'reference_articles';

  /// Связь «задача — статья справочника».
  static const String taskReferences = 'task_references';
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

/// Имена RPC-функций Supabase.
abstract final class SupabaseRpc {
  /// Открыта ли регистрация (доступна и до входа).
  static const String isRegistrationOpen = 'is_registration_open';
}
