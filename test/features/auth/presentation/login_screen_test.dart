import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/domain/entities/test_account.dart';
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

  /// Кнопка «Тестовый вход».
  final testSignInButton = find.widgetWithText(
    OutlinedButton,
    l10n.authTestSignInButton,
  );

  /// Текст поля формы [field].
  String fieldText(WidgetTester tester, Finder field) =>
      tester.widget<TextFormField>(field).controller!.text;

  /// Доступна ли кнопка [button].
  bool isEnabled<T extends ButtonStyleButton>(
    WidgetTester tester,
    Finder button,
  ) => tester.widget<T>(button).enabled;

  testWidgets('UC-10-P-03: не отправляет форму с некорректным вводом', (
    tester,
  ) async {
    await pumpApp(tester, repository: repository);
    expect(find.byType(LoginScreen), findsOneWidget);

    await fillForm(tester, username: 'ab', password: 'short');
    await tester.tap(find.text(l10n.authSignInButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.authUsernameInvalid), findsOneWidget);
    expect(find.text(l10n.authPasswordInvalid), findsOneWidget);
    expect(repository.lastUsername, isNull);
  });

  testWidgets('UC-10-P-02: показывает ошибку сервера', (tester) async {
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

  testWidgets('UC-10-P-04: сбой связи показывается сообщением', (
    tester,
  ) async {
    repository.signInResult = const Err(NetworkFailure());
    await pumpApp(tester, repository: repository);

    await fillForm(tester);
    await tester.tap(find.text(l10n.authSignInButton));
    await tester.pumpAndSettle();

    expect(find.text(const NetworkFailure().message), findsOneWidget);
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

  testWidgets('UC-10-P-01: успешный вход ведёт в каталог', (tester) async {
    await pumpApp(tester, repository: repository);

    await fillForm(tester);
    await tester.tap(find.text(l10n.authSignInButton));
    await tester.pumpAndSettle();

    expect(repository.lastUsername, 'student');
    expect(repository.lastPassword, 'password1');
    expect(find.byType(CatalogScreen), findsOneWidget);
  });

  testWidgets('UC-10-P-06: показывает ошибку восстановления сессии', (
    tester,
  ) async {
    repository.currentProfileResult = const Err(
      DatabaseFailure(message: 'Профиль пользователя не найден.'),
    );
    await pumpApp(tester, repository: repository, initialUserId: 'student-id');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Профиль пользователя не найден.'), findsOneWidget);
  });

  testWidgets(
    'UC-38-P-01: «Тестовый вход» подставляет логин и пароль и входит; пока '
    'идёт отправка, обе кнопки недоступны',
    (tester) async {
      repository.gate = Completer<void>();
      await pumpApp(
        tester,
        repository: repository,
        testAccount: fakeTestAccount,
      );
      expect(isEnabled<OutlinedButton>(tester, testSignInButton), isTrue);

      await tester.tap(testSignInButton);
      await tester.pump();

      final fields = find.byType(TextFormField);
      expect(fieldText(tester, fields.first), fakeTestAccount.username);
      expect(fieldText(tester, fields.last), fakeTestAccount.password);
      expect(repository.lastUsername, fakeTestAccount.username);
      expect(repository.lastPassword, fakeTestAccount.password);
      expect(isEnabled<OutlinedButton>(tester, testSignInButton), isFalse);
      expect(
        isEnabled<FilledButton>(tester, find.byType(FilledButton)),
        isFalse,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(l10n.authSignInButton), findsNothing);
      expect(
        isEnabled<TextButton>(
          tester,
          find.widgetWithText(TextButton, l10n.authNoAccountLink),
        ),
        isFalse,
      );

      repository.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CatalogScreen), findsOneWidget);
    },
  );

  testWidgets('UC-38-P-01: пока отправляет «Войти», «Тестовый вход» '
      'недоступна', (tester) async {
    repository.gate = Completer<void>();
    await pumpApp(tester, repository: repository, testAccount: fakeTestAccount);

    await fillForm(tester);
    await tester.tap(find.text(l10n.authSignInButton));
    await tester.pump();

    expect(repository.lastUsername, 'student');
    expect(isEnabled<OutlinedButton>(tester, testSignInButton), isFalse);

    repository.gate!.complete();
    await tester.pumpAndSettle();
  });

  for (final (what, username, password) in [
    ('не заданы логин и пароль', '', ''),
    ('задан только логин', fakeTestAccount.username, ''),
    ('задан только пароль', '', fakeTestAccount.password),
  ]) {
    testWidgets('UC-38-P-02: $what — кнопки «Тестовый вход» нет', (
      tester,
    ) async {
      await pumpApp(
        tester,
        repository: repository,
        testAccount: TestAccount.fromBuild(
          username: username,
          password: password,
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text(l10n.authTestSignInButton), findsNothing);
      expect(find.text(l10n.authSignInButton), findsOneWidget);
      expect(find.text(l10n.authNoAccountLink), findsOneWidget);
    });
  }

  testWidgets('UC-38-P-03: тестовый вход отклонён — сообщение над формой, в '
      'полях подставленные значения', (tester) async {
    repository.signInResult = const Err(
      AuthFailure(message: 'Неверный логин или пароль.'),
    );
    await pumpApp(tester, repository: repository, testAccount: fakeTestAccount);

    await tester.tap(testSignInButton);
    await tester.pumpAndSettle();

    expect(repository.lastUsername, fakeTestAccount.username);
    expect(find.text('Неверный логин или пароль.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    final fields = find.byType(TextFormField);
    expect(fieldText(tester, fields.first), fakeTestAccount.username);
    expect(fieldText(tester, fields.last), fakeTestAccount.password);
  });

  testWidgets('тестовый вход с логином и паролем не по правилам — ошибки у '
      'полей, запрос не отправлен', (tester) async {
    await pumpApp(
      tester,
      repository: repository,
      testAccount: const TestAccount(username: 'ab', password: 'short'),
    );

    await tester.tap(testSignInButton);
    await tester.pumpAndSettle();

    expect(find.text(l10n.authUsernameInvalid), findsOneWidget);
    expect(find.text(l10n.authPasswordInvalid), findsOneWidget);
    expect(repository.lastUsername, isNull);
  });
}
