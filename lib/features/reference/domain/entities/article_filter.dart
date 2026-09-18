import 'package:meta/meta.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';

/// Условия отбора статей в списке справочника.
///
/// Пустой фильтр означает «показать всё»; отбор считает база, а не клиент.
@immutable
final class ArticleFilter {
  /// Создаёт фильтр.
  const ArticleFilter({
    this.egeNumber,
    this.tag,
    this.level,
    this.query = '',
  });

  /// Номер задания ЕГЭ.
  final int? egeNumber;

  /// Тег статьи.
  final String? tag;

  /// Уровень сложности.
  final ArticleLevel? level;

  /// Строка поиска по заголовку и описанию.
  final String query;

  /// `true`, если не задано ни одного условия.
  bool get isEmpty =>
      egeNumber == null && tag == null && level == null && query.isEmpty;

  /// Копия фильтра с изменёнными полями.
  ///
  /// Значения-признаки `clearEgeNumber`, `clearTag` и `clearLevel` нужны,
  /// чтобы отличить «не меняем» от «сбрасываем в null».
  ArticleFilter copyWith({
    int? egeNumber,
    String? tag,
    ArticleLevel? level,
    String? query,
    bool clearEgeNumber = false,
    bool clearTag = false,
    bool clearLevel = false,
  }) => ArticleFilter(
    egeNumber: clearEgeNumber ? null : egeNumber ?? this.egeNumber,
    tag: clearTag ? null : tag ?? this.tag,
    level: clearLevel ? null : level ?? this.level,
    query: query ?? this.query,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleFilter &&
          other.egeNumber == egeNumber &&
          other.tag == tag &&
          other.level == level &&
          other.query == query;

  @override
  int get hashCode => Object.hash(egeNumber, tag, level, query);
}
