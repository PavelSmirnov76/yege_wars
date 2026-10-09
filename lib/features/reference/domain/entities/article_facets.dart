import 'package:meta/meta.dart';
import 'package:yege_wars/features/reference/domain/entities/codifier_section.dart';

/// Доступные значения фильтров справочника.
///
/// Считаются по всему справочнику, а не по отфильтрованному списку:
/// иначе выбранный фильтр прятал бы остальные варианты.
@immutable
final class ArticleFacets {
  /// Создаёт набор значений.
  const ArticleFacets({this.egeNumbers = const [], this.sections = const []});

  /// Номера заданий ЕГЭ, встречающиеся в статьях.
  final List<int> egeNumbers;

  /// Разделы кодификатора, встречающиеся в тегах статей, по порядку номера.
  ///
  /// Темы кодификатора — теги вида `1.1` — в отборе не участвуют.
  final List<CodifierSection> sections;
}
