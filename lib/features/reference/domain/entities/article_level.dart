/// Уровень сложности статьи справочника.
enum ArticleLevel {
  /// Базовый: нужен всем.
  basic(1),

  /// Средний: пригодится после освоения базы.
  medium(2),

  /// Продвинутый: тонкости и оптимизации.
  advanced(3)
  ;

  const ArticleLevel(this.value);

  /// Значение уровня в базе данных (колонка `level`).
  final int value;

  /// Уровень по значению из базы; неизвестное значение — [basic].
  static ArticleLevel fromValue(int? value) => ArticleLevel.values.firstWhere(
    (level) => level.value == value,
    orElse: () => ArticleLevel.basic,
  );
}
