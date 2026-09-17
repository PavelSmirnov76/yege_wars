import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/app.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/widgets/not_found_screen.dart';
import 'package:yege_wars/core/widgets/splash_screen.dart';
import 'package:yege_wars/features/admin/presentation/screens/admin_screen.dart';
import 'package:yege_wars/features/auth/auth_providers.dart';
import 'package:yege_wars/features/auth/presentation/screens/login_screen.dart';
import 'package:yege_wars/features/profile/presentation/screens/profile_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/catalog_screen.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

/// Заведомо несуществующий путь для проверки экрана 404.
const String _unknownPath = '/no-such-page';

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  /// Собирает приложение, не эмитируя событие сессии.
  Future<void> pumpWithUnknownSession(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const YegeWarsApp(),
      ),
    );
    await tester.pump();
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

  testWidgets('адрес, открытый до проверки сессии, восстанавливается', (
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

  testWidgets('без авторизации любой путь ведёт на вход', (tester) async {
    await pumpApp(tester, repository: repository);
    expect(find.byType(LoginScreen), findsOneWidget);

    containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('после входа открывается каталог, после выхода — вход', (
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

  testWidgets('ученика не пускает в админку и прячет пункт меню', (
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

  testWidgets('админ открывает админку и видит пункт меню', (tester) async {
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
}
