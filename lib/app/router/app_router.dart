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
    // Открытая страница — текущая конфигурация роутера: пока redirect
    // разбирает новый адрес, она ещё не сменилась.
    redirect: (context, state) => _guard(
      ref.read(authControllerProvider),
      state,
      openLocation: GoRouter.of(
        context,
      ).routerDelegate.currentConfiguration.uri,
    ),
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
        builder: (context, state) => LoginScreen(
          from: state.uri.queryParameters[AppRoutes.fromQueryParam],
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => RegisterScreen(
          from: state.uri.queryParameters[AppRoutes.fromQueryParam],
        ),
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

/// Служебные пути: их не открывают как адрес из
/// [AppRoutes.fromQueryParam].
const Set<String> _servicePaths = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
};

/// Правила доступа к маршрутам.
///
/// Адрес, на который шёл пользователь, хранится в параметре
/// [AppRoutes.fromQueryParam]: пока состояние неизвестно — у заставки
/// (иначе при перезагрузке страницы терялась бы глубокая ссылка), без
/// входа — у экранов входа и регистрации. После проверки сессии, входа или
/// регистрации он открывается, если годен ([_restoredLocation]), иначе
/// открывается главная.
///
/// Адрес не запоминается, если сессия закончилась на открытой странице
/// [openLocation] — «Выйти» в этой вкладке или в другой, сессия кончилась
/// сама: открытую страницу роутер перепроверяет при смене состояния входа,
/// и проверяемый адрес совпадает с открытым.
///
/// Реализует UC-1, UC-5, UC-10 и UC-13.
String? _guard(
  AuthState auth,
  GoRouterState state, {
  required Uri openLocation,
}) {
  final path = state.matchedLocation;
  final isAuthPath = path == AppRoutes.login || path == AppRoutes.register;

  switch (auth) {
    case AuthUnknown():
      return path == AppRoutes.splash
          ? null
          : _locationWithFrom(AppRoutes.splash, state.uri.toString());
    case AuthUnauthenticated():
      if (isAuthPath) {
        return null;
      }
      if (path == AppRoutes.splash) {
        return _signInLocationAfterSplash(state);
      }
      // Открытая страница без входа: сессия закончилась на ней.
      if (state.uri == openLocation) {
        return AppRoutes.login;
      }
      return _locationWithFrom(AppRoutes.login, state.uri.toString());
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

/// Адрес [path] с адресом [from] в параметре [AppRoutes.fromQueryParam].
String _locationWithFrom(String path, String from) => Uri(
  path: path,
  queryParameters: {AppRoutes.fromQueryParam: from},
).toString();

/// Куда уводит заставка, когда входа нет.
///
/// Сохранённую страницу входа или регистрации открывает как есть, со своим
/// адресом в [AppRoutes.fromQueryParam]: так адрес переживает перезагрузку
/// этих страниц. Любой другой сохранённый адрес без изменений передаёт
/// экрану входа.
String _signInLocationAfterSplash(GoRouterState state) {
  final from = state.uri.queryParameters[AppRoutes.fromQueryParam];
  if (from == null) {
    return AppRoutes.login;
  }
  final path = _internalUri(from)?.path;
  if (path == AppRoutes.login || path == AppRoutes.register) {
    return from;
  }
  return _locationWithFrom(AppRoutes.login, from);
}

/// Адрес из [AppRoutes.fromQueryParam], если его можно открыть: путь внутри
/// приложения, не служебный. Возвращается целиком, с параметрами запроса.
String? _restoredLocation(GoRouterState state) {
  final from = state.uri.queryParameters[AppRoutes.fromQueryParam];
  final path = from == null ? null : _internalUri(from)?.path;
  if (path == null || _servicePaths.contains(path)) {
    return null;
  }
  return from;
}

/// Разобранный [location], если это путь внутри приложения: без схемы и
/// хоста, начинается с `/`.
///
/// Адреса `//хост…` и `/\хост…` Dart разбирает с хостом — они не проходят.
Uri? _internalUri(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/')) {
    return null;
  }
  return uri;
}
