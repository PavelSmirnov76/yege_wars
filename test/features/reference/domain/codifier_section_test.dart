import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/reference/domain/entities/codifier_section.dart';
import 'package:yege_wars/features/reference/presentation/widgets/codifier_section_label.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

void main() {
  group('CodifierSection', () {
    test('UC-39-P-02: раздел — тег с номером раздела, тема и чужой тег — '
        'не раздел', () {
      expect(CodifierSection.fromTag('1'), CodifierSection.digitalLiteracy);
      expect(CodifierSection.fromTag('2'), CodifierSection.theory);
      expect(CodifierSection.fromTag('3'), CodifierSection.algorithms);
      expect(CodifierSection.fromTag('4'), CodifierSection.technologies);
      expect(CodifierSection.fromTag('1.1'), isNull);
      expect(CodifierSection.fromTag('5'), isNull);
      expect(CodifierSection.fromTag('regex'), isNull);
    });

    test('UC-39-P-02: подпись раздела — номер и название', () {
      final l10n = AppLocalizationsRu();

      expect(
        [
          for (final section in CodifierSection.values)
            codifierSectionLabel(section, l10n),
        ],
        [
          '1 · Цифровая грамотность',
          '2 · Теоретические основы информатики',
          '3 · Алгоритмы и программирование',
          '4 · Информационные технологии',
        ],
      );
    });
  });
}
