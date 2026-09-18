import 'package:meta/meta.dart';

/// Доступные значения фильтров справочника.
///
/// Считаются по всему справочнику, а не по отфильтрованному списку:
/// иначе выбранный фильтр прятал бы остальные варианты.
@immutable
final class ArticleFacets {
  /// Создаёт набор значений.
  const ArticleFacets({this.egeNumbers = const [], this.tags = const []});

  /// Номера заданий ЕГЭ, встречающиеся в статьях.
  final List<int> egeNumbers;

  /// Теги, встречающиеся в статьях.
  final List<String> tags;
}
