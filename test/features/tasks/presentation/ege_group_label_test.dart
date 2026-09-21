import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/tasks/presentation/ege_group_label.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

void main() {
  final l10n = AppLocalizationsRu();

  test('номер задания подписывается номером', () {
    expect(egeGroupLabel(l10n, 24), l10n.catalogEgeGroup(24));
  });

  test('задание без номера КИМ попадает в группу «Без номера»', () {
    expect(egeGroupLabel(l10n, null), l10n.catalogEgeGroupNone);
    expect(egeGroupLabel(l10n, null), isNot(contains('0')));
  });
}
