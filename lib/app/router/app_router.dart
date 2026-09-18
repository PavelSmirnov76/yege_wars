import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/router/app_shell.dart';
import 'package:yege_wars/core/widgets/not_found_screen.dart';
import 'package:yege_wars/core/widgets/splash_screen.dart';
import 'package:yege_wars/features/admin/presentation/screens/admin_screen.dart';
import 'package:yege_wars/features/auth/domain/auth_state.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';
import 'package:yege_wars/features/auth/presentation/screens/login_screen.dart';
import 'package:yege_wars/features/auth/presentation/screens/register_screen.dart';
import 'package:yege_wars/features/profile/presentation/screens/profile_screen.dart';
import 'package:yege_wars/features/reference/presentation/screens/article_screen.dart';
import 'package:yege_wars/features/reference/presentation/screens/reference_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/catalog_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/task_screen.dart';

part 'app_router.g.dart';

/// Роутер приложения: оболочка с навигацией, экраны авторизации
/// и guard'ы по состоянию [AuthState].
@riverpod
GoRouter appRouter(Ref ref) {
  // Реактивность guard'ов: любое изменение состояния авторизации
  // инкрементирует счётчик, и GoRouter пересчитывает redirect.
  final refreshNotifier = ValueNotifier<int>(0);
  ref
    ..listen(authControllerProvider, (_, _) => refreshNotifier.value++)
    ..onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    refreshListenable: refreshNotifier,
    redirect: (context, state) =>
        _guard(ref.read(authControllerProvider), state),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
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
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                name: AppRoutes.catalogName,
                builder: (context, state) => const CatalogScreen(),
                routes: [
                  GoRoute(
                    path: 'task/:${AppRoutes.slugParam}',
                    name: AppRoutes.taskName,
                    builder: (context, state) => TaskScreen(
                      slug: state.pathParameters[AppRoutes.slugParam]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reference,
                name: AppRoutes.referenceName,
                builder: (context, state) => const ReferenceScreen(),
                routes: [
                  GoRoute(
                    path: ':${AppRoutes.slugParam}',
                    name: AppRoutes.referenceArticleName,
                    builder: (context, state) => ArticleScreen(
                      slug: state.pathParameters[AppRoutes.slugParam]!,
                    ),
                  ),
                ],
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
          // Ветка админки последняя: её пункт скрывается у учеников,
          // не сдвигая индексы остальных (см. AppShell).
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

/// Правила доступа к маршрутам.
///
/// Пока состояние неизвестно, показывается заставка, а адрес, на который
/// шёл пользователь, сохраняется в параметре [AppRoutes.fromQueryParam]
/// и восстанавливается после проверки сессии (иначе при перезагрузке
/// страницы терялась бы глубокая ссылка).
String? _guard(AuthState auth, GoRouterState state) {
  final path = state.matchedLocation;
  final isAuthPath = path == AppRoutes.login || path == AppRoutes.register;

  switch (auth) {
    case AuthUnknown():
      return path == AppRoutes.splash
          ? null
          : _splashLocation(state.uri.toString());
    case AuthUnauthenticated():
      return isAuthPath ? null : AppRoutes.login;
    case AuthAuthenticated(:final profile):
      if (isAuthPath || path == AppRoutes.splash) {
        return _restoredLocation(state) ?? AppRoutes.catalog;
      }
      if (path == AppRoutes.admin && !profile.isAdmin) {
        return AppRoutes.catalog;
      }
      return null;
  }
}

/// Адрес заставки с сохранённым адресом [from].
String _splashLocation(String from) => Uri(
  path: AppRoutes.splash,
  queryParameters: {AppRoutes.fromQueryParam: from},
).toString();

/// Адрес, сохранённый перед показом заставки, если он пригоден
/// для перехода.
String? _restoredLocation(GoRouterState state) {
  final from = state.uri.queryParameters[AppRoutes.fromQueryParam];
  if (from == null || !from.startsWith('/')) {
    return null;
  }
  final path = Uri.parse(from).path;
  final isServicePath =
      path == AppRoutes.splash ||
      path == AppRoutes.login ||
      path == AppRoutes.register;
  return isServicePath ? null : from;
}
