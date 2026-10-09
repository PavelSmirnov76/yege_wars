/// Раздел кодификатора КЕГЭ — верхний уровень тем.
///
/// У статьи справочника раздел — её тег с номером раздела, например `1`;
/// темы внутри раздела — теги вида `1.1`.
///
/// Реализует UC-39.
enum CodifierSection {
  /// 1 — цифровая грамотность.
  digitalLiteracy('1'),

  /// 2 — теоретические основы информатики.
  theory('2'),

  /// 3 — алгоритмы и программирование.
  algorithms('3'),

  /// 4 — информационные технологии.
  technologies('4')
  ;

  const CodifierSection(this.tag);

  /// Тег статьи, которым отмечен раздел.
  final String tag;

  /// Раздел по тегу статьи; тег темы или любой другой — `null`.
  static CodifierSection? fromTag(String tag) {
    for (final section in values) {
      if (section.tag == tag) {
        return section;
      }
    }
    return null;
  }
}
