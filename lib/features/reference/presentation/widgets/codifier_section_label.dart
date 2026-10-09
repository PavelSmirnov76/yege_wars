import 'package:yege_wars/features/reference/domain/entities/codifier_section.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Подпись раздела кодификатора: номер и название.
///
/// Реализует UC-39.
String codifierSectionLabel(
  CodifierSection section,
  AppLocalizations l10n,
) => switch (section) {
  CodifierSection.digitalLiteracy => l10n.referenceSection1,
  CodifierSection.theory => l10n.referenceSection2,
  CodifierSection.algorithms => l10n.referenceSection3,
  CodifierSection.technologies => l10n.referenceSection4,
};
