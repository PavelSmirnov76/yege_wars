import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/presentation/screens/login_screen.dart';
import 'package:yege_wars/features/profile/presentation/screens/profile_screen.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  /// Открывает профиль вошедшего пользователя.
  Future<void> openProfile(WidgetTester tester) async {
    await pumpApp(
      tester,
      repository: repository,
      initialUserId: testStudent.id,
    );
    containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  }

  testWidgets('UC-4-P-01: показывает логин и роль', (tester) async {
    await openProfile(tester);

    expect(find.text(testStudent.username), findsOneWidget);
    expect(
      find.text('${l10n.profileRoleLabel}: ${l10n.profileRoleStudent}'),
      findsOneWidget,
    );
  });

  testWidgets('UC-4-P-01: показывает роль администратора', (tester) async {
    repository.currentProfileResult = const Ok(testAdmin);
    await pumpApp(tester, repository: repository, initialUserId: testAdmin.id);
    containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text(testAdmin.username), findsOneWidget);
    expect(
      find.text('${l10n.profileRoleLabel}: ${l10n.profileRoleAdmin}'),
      findsOneWidget,
    );
  });

  testWidgets('UC-11-P-01: кнопка «Выйти» возвращает на экран входа', (
    tester,
  ) async {
    await openProfile(tester);

    await tester.tap(find.text(l10n.profileSignOut));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('UC-11-P-02: ошибка выхода показывается сообщением', (
    tester,
  ) async {
    repository.signOutResult = const Err<void>(NetworkFailure());
    await openProfile(tester);

    await tester.tap(find.text(l10n.profileSignOut));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(
      find.text('Нет соединения с сервером. Проверьте интернет.'),
      findsOneWidget,
    );
  });
}
