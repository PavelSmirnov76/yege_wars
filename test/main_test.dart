import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';
import 'package:yege_wars/main.dart' as app;

void main() {
  testWidgets(
    'UC-12-P-02: без параметров сборки приложение показывает экран '
    '«не сконфигурировано» с причиной',
    (tester) async {
      // Запуск — в настоящем async: с параметрами сборки bootstrap ждёт
      // ввода-вывода Supabase, и в поддельном времени теста он бы завис.
      await tester.runAsync(app.main);
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsRu();
      expect(find.text(l10n.configMissingTitle), findsOneWidget);
      expect(
        find.text(
          'Не заданы SUPABASE_URL и SUPABASE_ANON_KEY. '
          'Соберите приложение с параметрами --dart-define.',
        ),
        findsOneWidget,
      );
    },
  );
}
