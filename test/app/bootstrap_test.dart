import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/bootstrap.dart';
import 'package:yege_wars/app/not_configured_app.dart';
import 'package:yege_wars/core/config/env.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

void main() {
  final l10n = AppLocalizationsRu();

  test('без адреса и ключа bootstrap возвращает понятную ошибку', () async {
    // Пустые значения имитируют сборку с --dart-define=SUPABASE_URL=.
    final result = await bootstrap(url: '', anonKey: '');

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull?.message, contains('SUPABASE_URL'));
  });

  test('по умолчанию адрес и ключ проекта заданы в коде', () {
    expect(Env.isConfigured, isTrue);
    expect(Env.supabaseUrl, startsWith('https://'));
    expect(Env.supabaseAnonKey, isNotEmpty);
  });

  testWidgets('заглушка объясняет, чего не хватает', (tester) async {
    await tester.pumpWidget(const NotConfiguredApp());
    await tester.pumpAndSettle();

    expect(find.text(l10n.configMissingTitle), findsOneWidget);
    expect(find.text(l10n.configMissingBody), findsOneWidget);
  });

  testWidgets('заглушка показывает переданные подробности', (tester) async {
    await tester.pumpWidget(
      const NotConfiguredApp(details: 'Не удалось подключиться к Supabase.'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Не удалось подключиться к Supabase.'),
      findsOneWidget,
    );
    expect(find.text(l10n.configMissingBody), findsNothing);
  });
}
