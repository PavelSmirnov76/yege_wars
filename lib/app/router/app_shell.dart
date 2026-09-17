import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/core/widgets/adaptive_navigation_scaffold.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';

/// Оболочка приложения с адаптивной навигацией.
///
/// Пункт «Админка» виден только администратору. Ветки
/// [StatefulShellRoute] при этом не меняются: админская ветка идёт
/// последней, поэтому индексы видимых пунктов совпадают с индексами
/// веток, и скрытие пункта не ломает навигацию.
class AppShell extends ConsumerWidget {
  /// Создаёт оболочку вокруг [navigationShell].
  const AppShell({required this.navigationShell, super.key});

  /// Навигационная оболочка go_router с ветками разделов.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isAdmin = ref.watch(authControllerProvider).isAdmin;

    final destinations = [
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
      if (isAdmin)
        AdaptiveDestination(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: l10n.navAdmin,
        ),
    ];

    // Ученик на ветке админки оказаться не должен (его уводит guard),
    // но в момент смены роли индекс может оказаться вне диапазона —
    // ограничиваем его, чтобы NavigationBar не упал.
    final selectedIndex = math.min(
      navigationShell.currentIndex,
      destinations.length - 1,
    );

    return AdaptiveNavigationScaffold(
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: navigationShell.goBranch,
      body: navigationShell,
    );
  }
}
