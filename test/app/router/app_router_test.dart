import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/app.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/widgets/not_found_screen.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';
import 'package:yege_wars/features/auth/presentation/screens/login_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/catalog_screen.dart';

/// Заведомо несуществующий путь для проверки экрана 404.
const String _unknownPath = '/no-such-page';

void main() {
  testWidgets('guard: редиректы по статусу авторизации', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: YegeWarsApp()));
    await tester.pumpAndSettle();

    // Не авторизован: любой путь ведёт на экран входа.
    expect(find.byType(LoginScreen), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(YegeWarsApp)),
      listen: false,
    );

    // Вход: guard уводит с /login на каталог.
    container.read(authControllerProvider.notifier).signIn();
    await tester.pumpAndSettle();
    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    // Выход: снова экран входа.
    container.read(authControllerProvider.notifier).signOut();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CatalogScreen), findsNothing);

    // Авторизован и путь не существует: экран 404.
    container.read(authControllerProvider.notifier).signIn();
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(_unknownPath);
    await tester.pumpAndSettle();
    expect(find.byType(NotFoundScreen), findsOneWidget);
  });
}
