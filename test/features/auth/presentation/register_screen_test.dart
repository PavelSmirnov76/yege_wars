import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/presentation/screens/register_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/catalog_screen.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  /// Открывает экран регистрации со стартового экрана входа.
  Future<void> openRegister(WidgetTester tester) async {
    await pumpApp(tester, repository: repository);
    await tester.tap(find.text(l10n.authNoAccountLink));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  }

  testWidgets('успешная регистрация ведёт в каталог', (tester) async {
    await openRegister(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'newbie');
    await tester.enterText(fields.last, 'password1');
    await tester.tap(find.text(l10n.authSignUpButton));
    await tester.pumpAndSettle();

    expect(repository.lastUsername, 'newbie');
    expect(find.byType(CatalogScreen), findsOneWidget);
  });

  testWidgets('UC-1-P-02: не отправляет форму с некорректным вводом', (
    tester,
  ) async {
    await openRegister(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'ab');
    await tester.enterText(fields.last, 'short');
    await tester.tap(find.text(l10n.authSignUpButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.authUsernameInvalid), findsOneWidget);
    expect(find.text(l10n.authPasswordInvalid), findsOneWidget);
    expect(repository.lastUsername, isNull);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('UC-1-P-04: при закрытой регистрации форма заблокирована', (
    tester,
  ) async {
    repository.registrationOpenResult = const Ok(false);
    await openRegister(tester);

    expect(find.text(l10n.authRegistrationClosed), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
      isFalse,
    );
  });

  testWidgets('UC-1-P-05: ошибка проверки регистрации показывается', (
    tester,
  ) async {
    repository.registrationOpenResult = const Err(NetworkFailure());
    await openRegister(tester);

    expect(
      find.text('Нет соединения с сервером. Проверьте интернет.'),
      findsOneWidget,
    );
  });

  testWidgets('UC-1-P-03: ошибка регистрации показывается на экране', (
    tester,
  ) async {
    repository.signUpResult = const Err(
      ValidationFailure(message: 'Логин уже занят, выберите другой.'),
    );
    await openRegister(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'newbie');
    await tester.enterText(fields.last, 'password1');
    await tester.tap(find.text(l10n.authSignUpButton));
    await tester.pumpAndSettle();

    expect(find.text('Логин уже занят, выберите другой.'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
