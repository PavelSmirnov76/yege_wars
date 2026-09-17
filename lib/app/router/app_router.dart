import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/core/widgets/adaptive_navigation_scaffold.dart';
import 'package:yege_wars/core/widgets/not_found_screen.dart';
import 'package:yege_wars/features/admin/presentation/screens/admin_screen.dart';
import 'package:yege_wars/features/auth/domain/auth_status.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';
import 'package:yege_wars/features/auth/presentation/screens/login_screen.dart';
import 'package:yege_wars/features/auth/presentation/screens/register_screen.dart';
import 'package:yege_wars/features/profile/presentation/screens/profile_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/catalog_screen.dart';

part 'app_router.g.dart';

/// Роутер приложения: оболочка с навигацией, экраны авторизации
/// и guard'ы по статусу [AuthStatus].
@riverpod
GoRouter appRouter(Ref ref) {
  // Реактивность guard'ов: любое изменение статуса авторизации
  // инкрементирует счётчик, и GoRouter пересчитывает redirect.
  final refreshNotifier = ValueNotifier<int>(0);
  ref
    ..listen(authControllerProvider, (_, _) => refreshNotifier.value++)
    ..onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthLocation =
          location == AppRoutes.login || location == AppRoutes.register;
      if (status == AuthStatus.unauthenticated && !isAuthLocation) {
        return AppRoutes.login;
      }
      if (status == AuthStatus.authenticated && isAuthLocation) {
        return AppRoutes.catalog;
      }
      return null;
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final l10n = context.l10n;
          return AdaptiveNavigationScaffold(
            destinations: [
              AdaptiveDestination(
                icon: Icons.list_alt_outlined,
                selectedIcon: Icons.list_alt,
                label: l10n.navCatalog,
              ),
              AdaptiveDestination(
                icon: Icons.person_outlined,
                selectedIcon: Icons.person,
                label: l10n.navProfile,
              ),
              AdaptiveDestination(
                icon: Icons.admin_panel_settings_outlined,
                selectedIcon: Icons.admin_panel_settings,
                label: l10n.navAdmin,
              ),
            ],
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: navigationShell.goBranch,
            body: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                name: AppRoutes.catalogName,
                builder: (context, state) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.admin,
                name: AppRoutes.adminName,
                builder: (context, state) => const AdminScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
