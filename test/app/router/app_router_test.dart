import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/app.dart';
import 'package:yege_wars/app/provider_retry.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/widgets/not_found_screen.dart';
import 'package:yege_wars/core/widgets/splash_screen.dart';
import 'package:yege_wars/features/admin/presentation/screens/admin_screen.dart';
import 'package:yege_wars/features/auth/auth_providers.dart';
import 'package:yege_wars/features/auth/presentation/screens/login_screen.dart';
import 'package:yege_wars/features/auth/presentation/screens/register_screen.dart';
import 'package:yege_wars/features/profile/presentation/screens/profile_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/catalog_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/task_screen.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_tasks_repository.dart';
import '../../helpers/pump_app.dart';

/// Заведомо несуществующий путь для проверки экрана 404.
const String _unknownPath = '/no-such-page';

/// Ссылка на задачу из тестового репозитория.
final String _taskPath = '/task/${testTask24.slug}';

/// Адрес экрана [path] с сохранённым адресом [from].
String _withFrom(String path, String from) => Uri(
  path: path,
  queryParameters: {AppRoutes.fromQueryParam: from},
).toString();

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  /// Собирает приложение, не эмитируя событие сессии.
  Future<void> pumpWithUnknownSession(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const YegeWarsApp(),
      ),
    );
    await tester.pump();
  }

  /// Входит учеником через форму на экране входа.
  Future<void> signInWithForm(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'student');
    await tester.enterText(fields.last, 'password1');
    await tester.tap(find.text(l10n.authSignInButton));
    await tester.pumpAndSettle();
  }

  testWidgets('пока сессия не проверена, показывается заставка', (
    tester,
  ) async {
    await pumpWithUnknownSession(tester);

    expect(find.byType(SplashScreen), findsOneWidget);

    repository.emitUserId(null);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('UC-10-P-05: адрес, открытый до проверки сессии, '
      'восстанавливается', (
    tester,
  ) async {
    await pumpWithUnknownSession(tester);
    containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    repository.emitUserId(testStudent.id);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('UC-10-P-01: без авторизации любой путь ведёт на вход', (
    tester,
  ) async {
    await pumpApp(tester, repository: repository);
    expect(find.byType(LoginScreen), findsOneWidget);

    containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('UC-10-P-05, UC-13-P-03: после входа открывается каталог, '
      'после выхода — вход', (
    tester,
  ) async {
    await pumpApp(
      tester,
      repository: repository,
      initialUserId: testStudent.id,
    );
    expect(find.byType(CatalogScreen), findsOneWidget);

    repository.emitUserId(null);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('UC-10-P-05: вошедшего с /login и /register уводит на главную', (
    tester,
  ) async {
    await pumpApp(
      tester,
      repository: repository,
      initialUserId: testStudent.id,
    );
    final router = containerOf(tester).read(appRouterProvider);

    for (final path in [AppRoutes.login, AppRoutes.register]) {
      router.go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      router.go(path);
      await tester.pumpAndSettle();

      expect(find.byType(CatalogScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(RegisterScreen), findsNothing);
    }
  });

  testWidgets('UC-5-P-02: ученика не пускает в админку и прячет пункт меню', (
    tester,
  ) async {
    await pumpApp(
      tester,
      repository: repository,
      initialUserId: testStudent.id,
    );

    expect(find.text(l10n.navAdmin), findsNothing);

    containerOf(tester).read(appRouterProvider).go(AppRoutes.admin);
    await tester.pumpAndSettle();

    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(find.byType(AdminScreen), findsNothing);
  });

  testWidgets('UC-5-P-01: админ открывает админку и видит пункт меню', (
    tester,
  ) async {
    repository.currentProfileResult = const Ok(testAdmin);
    await pumpApp(tester, repository: repository, initialUserId: testAdmin.id);

    expect(find.text(l10n.navAdmin), findsOneWidget);

    containerOf(tester).read(appRouterProvider).go(AppRoutes.admin);
    await tester.pumpAndSettle();

    expect(find.byType(AdminScreen), findsOneWidget);
  });

  testWidgets('неизвестный путь показывает экран 404', (tester) async {
    await pumpApp(
      tester,
      repository: repository,
      initialUserId: testStudent.id,
    );

    containerOf(tester).read(appRouterProvider).go(_unknownPath);
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  group('адрес после входа', () {
    testWidgets('UC-10-P-01: адрес, открытый без входа, открывается после '
        'входа', (tester) async {
      await pumpApp(tester, repository: repository);
      containerOf(tester).read(appRouterProvider).go(_taskPath);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(currentLocation(tester), _withFrom(AppRoutes.login, _taskPath));

      await signInWithForm(tester);

      expect(currentLocation(tester), _taskPath);
      expect(find.byType(TaskScreen), findsOneWidget);
    });

    testWidgets('UC-10-P-01: адрес, открытый до проверки сессии, когда '
        'сессии нет, открывается после входа', (tester) async {
      await pumpWithUnknownSession(tester);
      containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      repository.emitUserId(null);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        currentLocation(tester),
        _withFrom(AppRoutes.login, AppRoutes.profile),
      );

      await signInWithForm(tester);

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('UC-10-P-01: путь с параметрами запроса сохраняется '
        'целиком', (tester) async {
      final location = '$_taskPath?tab=files&line=2';
      await pumpApp(tester, repository: repository);
      containerOf(tester).read(appRouterProvider).go(location);
      await tester.pumpAndSettle();

      expect(currentLocation(tester), _withFrom(AppRoutes.login, location));

      await signInWithForm(tester);

      expect(currentLocation(tester), location);
      expect(find.byType(TaskScreen), findsOneWidget);
    });

    testWidgets('UC-10-P-01: без входа на главной вход получает её адрес', (
      tester,
    ) async {
      await pumpApp(tester, repository: repository);

      expect(
        currentLocation(tester),
        _withFrom(AppRoutes.login, AppRoutes.catalog),
      );

      await signInWithForm(tester);

      expect(currentLocation(tester), AppRoutes.catalog);
      expect(find.byType(CatalogScreen), findsOneWidget);
    });

    testWidgets('UC-10-P-01: негодные адреса после входа ведут на главную', (
      tester,
    ) async {
      await pumpApp(tester, repository: repository);
      final router = containerOf(tester).read(appRouterProvider);

      for (final from in ['//example.com', r'/\example.com', AppRoutes.login]) {
        router.go(_withFrom(AppRoutes.login, from));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget, reason: from);

        await signInWithForm(tester);

        expect(currentLocation(tester), AppRoutes.catalog, reason: from);
        expect(find.byType(CatalogScreen), findsOneWidget, reason: from);

        // Сессия кончается, чтобы проверить следующий адрес.
        repository.emitUserId(null);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('UC-10-P-01: адрес переживает перезагрузку страницы входа', (
      tester,
    ) async {
      final login = _withFrom(AppRoutes.login, AppRoutes.profile);
      await pumpWithUnknownSession(tester);
      containerOf(tester).read(appRouterProvider).go(login);
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      repository.emitUserId(null);
      await tester.pumpAndSettle();

      expect(currentLocation(tester), login);

      await signInWithForm(tester);

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('UC-1-P-01: адрес переживает перезагрузку страницы '
        'регистрации', (tester) async {
      final register = _withFrom(AppRoutes.register, AppRoutes.profile);
      await pumpWithUnknownSession(tester);
      containerOf(tester).read(appRouterProvider).go(register);
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      repository.emitUserId(null);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(currentLocation(tester), register);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'newbie');
      await tester.enterText(fields.last, 'password1');
      await tester.tap(find.text(l10n.authSignUpButton));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('UC-10-P-01, UC-5-P-02: ученик с адресом админки после входа '
        'попадает в каталог', (tester) async {
      await pumpApp(tester, repository: repository);
      containerOf(tester).read(appRouterProvider).go(AppRoutes.admin);
      await tester.pumpAndSettle();

      expect(
        currentLocation(tester),
        _withFrom(AppRoutes.login, AppRoutes.admin),
      );

      await signInWithForm(tester);

      expect(find.byType(CatalogScreen), findsOneWidget);
      expect(find.byType(AdminScreen), findsNothing);
    });
  });

  group('адрес после конца сессии', () {
    testWidgets('UC-13-P-03: сессия закончилась на открытой странице — адрес '
        'не запоминается, следующий вход открывает главную', (tester) async {
      await pumpApp(
        tester,
        repository: repository,
        initialUserId: testStudent.id,
      );
      containerOf(tester).read(appRouterProvider).go(_taskPath);
      await tester.pumpAndSettle();
      expect(find.byType(TaskScreen), findsOneWidget);

      repository.emitUserId(null);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(currentLocation(tester), AppRoutes.login);

      await signInWithForm(tester);

      expect(find.byType(CatalogScreen), findsOneWidget);
    });

    testWidgets('UC-10-P-01: после конца сессии адрес, открытый заново без '
        'входа, запоминается', (tester) async {
      await pumpApp(
        tester,
        repository: repository,
        initialUserId: testStudent.id,
      );
      final router = containerOf(tester).read(appRouterProvider)..go(_taskPath);
      await tester.pumpAndSettle();
      repository.emitUserId(null);
      await tester.pumpAndSettle();
      expect(currentLocation(tester), AppRoutes.login);

      router.go(_taskPath);
      await tester.pumpAndSettle();

      expect(currentLocation(tester), _withFrom(AppRoutes.login, _taskPath));

      await signInWithForm(tester);

      expect(find.byType(TaskScreen), findsOneWidget);
    });
  });
}
