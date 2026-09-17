import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/presentation/screens/login_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/catalog_screen.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  /// Заполняет форму входа.
  Future<void> fillForm(
    WidgetTester tester, {
    String username = 'student',
    String password = 'password1',
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, username);
    await tester.enterText(fields.last, password);
  }

  testWidgets('не отправляет форму с некорректным вводом', (tester) async {
    await pumpApp(tester, repository: repository);
    expect(find.byType(LoginScreen), findsOneWidget);

    await fillForm(tester, username: 'ab', password: 'short');
    await tester.tap(find.text(l10n.authSignInButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.authUsernameInvalid), findsOneWidget);
    expect(find.text(l10n.authPasswordInvalid), findsOneWidget);
    expect(repository.lastUsername, isNull);
  });

  testWidgets('показывает ошибку сервера', (tester) async {
    repository.signInResult = const Err(
      AuthFailure(message: 'Неверный логин или пароль.'),
    );
    await pumpApp(tester, repository: repository);

    await fillForm(tester, password: 'wrongpassword');
    await tester.tap(find.text(l10n.authSignInButton));
    await tester.pumpAndSettle();

    expect(find.text('Неверный логин или пароль.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('показывает индикатор на время отправки', (tester) async {
    repository.gate = Completer<void>();
    await pumpApp(tester, repository: repository);

    await fillForm(tester);
    await tester.tap(find.text(l10n.authSignInButton));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.authSignInButton), findsNothing);

    repository.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('успешный вход ведёт в каталог', (tester) async {
    await pumpApp(tester, repository: repository);

    await fillForm(tester);
    await tester.tap(find.text(l10n.authSignInButton));
    await tester.pumpAndSettle();

    expect(repository.lastUsername, 'student');
    expect(repository.lastPassword, 'password1');
    expect(find.byType(CatalogScreen), findsOneWidget);
  });

  testWidgets('показывает ошибку восстановления сессии', (tester) async {
    repository.currentProfileResult = const Err(
      DatabaseFailure(message: 'Профиль пользователя не найден.'),
    );
    await pumpApp(tester, repository: repository, initialUserId: 'student-id');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Профиль пользователя не найден.'), findsOneWidget);
  });
}
