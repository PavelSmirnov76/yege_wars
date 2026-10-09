import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/reference/presentation/controllers/reference_controllers.dart';

void main() {
  group('ArticleFilter', () {
    test('пустой фильтр не задаёт условий', () {
      expect(const ArticleFilter().isEmpty, isTrue);
      expect(const ArticleFilter(query: 'окно').isEmpty, isFalse);
    });

    test('copyWith меняет одно поле и сбрасывает по признаку', () {
      const filter = ArticleFilter(egeNumber: 24, tag: 'regex', query: 'окно');

      expect(filter.copyWith(query: 'файл').egeNumber, 24);
      expect(filter.copyWith(clearEgeNumber: true).egeNumber, isNull);
      expect(filter.copyWith(clearTag: true).tag, isNull);
      expect(filter.copyWith(clearTag: true).query, 'окно');
    });
  });

  group('ArticleFilterController', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    ArticleFilter read() => container.read(articleFilterControllerProvider);
    ArticleFilterController notifier() =>
        container.read(articleFilterControllerProvider.notifier);

    test('UC-39-P-02: повторный выбор снимает условие', () {
      notifier().toggleLevel(ArticleLevel.medium);
      expect(read().level, ArticleLevel.medium);

      notifier().toggleLevel(ArticleLevel.medium);
      expect(read().level, isNull);
    });

    test('UC-39-P-02: выбор другого значения заменяет прежнее', () {
      notifier()
        ..toggleEgeNumber(24)
        ..toggleEgeNumber(17);

      expect(read().egeNumber, 17);
    });

    test('UC-39-P-02: сброс очищает все условия', () {
      notifier()
        ..toggleEgeNumber(24)
        ..toggleTag('regex')
        ..setQuery('окно')
        ..reset();

      expect(read().isEmpty, isTrue);
    });
  });
}
