import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Подпись группы по номеру задания ЕГЭ.
///
/// У части заданий банка ФИПИ номера нет: они не отнесены ни к одному номеру
/// действующей структуры КИМ и доступны только через темы. Такие задания
/// собираются в отдельную группу, а не приписываются к несуществующему
/// «заданию 0».
String egeGroupLabel(AppLocalizations l10n, int? egeNumber) => egeNumber == null
    ? l10n.catalogEgeGroupNone
    : l10n.catalogEgeGroup(egeNumber);
