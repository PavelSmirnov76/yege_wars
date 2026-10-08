import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/app/bootstrap.dart';
import 'package:yege_wars/app/not_configured_app.dart';
import 'package:yege_wars/core/config/env.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

void main() {
  final l10n = AppLocalizationsRu();

  // Supabase.initialize сразу открывает хранилище сессии на
  // SharedPreferences, а плагина в тестах нет — подставляется пустое.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'UC-12-P-02: без адреса и ключа bootstrap возвращает понятную ошибку',
    () async {
      // Без параметров сборки значения Env пусты.
      final result = await bootstrap();

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('SUPABASE_URL'));
    },
  );

  test('UC-12-P-02: без параметров сборки адреса и ключа проекта нет', () {
    expect(Env.supabaseUrl, isEmpty);
    expect(Env.supabaseAnonKey, isEmpty);
    expect(Env.isConfigured, isFalse);
  });

  test(
    'UC-12-P-03: Supabase не поднялся — bootstrap возвращает ошибку '
    'подключения',
    () async {
      // Адрес не разбирается как URI: Supabase.initialize падает до первого
      // обращения к проекту, сеть тесту не нужна.
      final result = await bootstrap(url: 'https://[', anonKey: 'ключ');

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(
        result.failureOrNull?.message,
        'Не удалось подключиться к Supabase. '
        'Проверьте SUPABASE_URL и SUPABASE_ANON_KEY.',
      );
    },
  );

  test(
    'UC-12-P-01: с адресом и ключом bootstrap поднимает Supabase',
    () async {
      // Без сохранённой сессии Supabase.initialize в сеть не ходит, а домен
      // .invalid не разрешается никогда (RFC 2606).
      final result = await bootstrap(
        url: 'https://project.invalid',
        anonKey: 'publishable-key',
      );
      addTearDown(Supabase.instance.dispose);

      expect(result, isA<Ok<void>>());
      expect(
        Supabase.instance.client.rest.url,
        startsWith('https://project.invalid'),
      );
    },
  );

  testWidgets('UC-12-P-02: заглушка объясняет, чего не хватает', (
    tester,
  ) async {
    await tester.pumpWidget(const NotConfiguredApp());
    await tester.pumpAndSettle();

    expect(find.text(l10n.configMissingTitle), findsOneWidget);
    expect(find.text(l10n.configMissingBody), findsOneWidget);
  });

  testWidgets('UC-12-P-03: заглушка показывает переданные подробности', (
    tester,
  ) async {
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
