import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_breakpoints.dart';

/// Пункт навигации адаптивного каркаса.
///
/// Описывает только внешний вид пункта; связь с маршрутами
/// остаётся на стороне вызывающего кода.
class AdaptiveDestination {
  /// Создаёт пункт навигации.
  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Иконка невыбранного пункта.
  final IconData icon;

  /// Иконка выбранного пункта.
  final IconData selectedIcon;

  /// Подпись пункта.
  final String label;
}

/// Адаптивный каркас с навигацией.
///
/// На узких экранах (уже [AppBreakpoints.mobileMax]) показывает
/// [NavigationBar] снизу, на широких — [NavigationRail] слева
/// (развёрнутый начиная с [AppBreakpoints.tabletMax]).
///
/// Внутри нет логики маршрутов: только индексы и колбэк
/// [onDestinationSelected].
class AdaptiveNavigationScaffold extends StatelessWidget {
  /// Создаёт адаптивный каркас навигации.
  const AdaptiveNavigationScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    super.key,
  });

  /// Пункты навигации.
  final List<AdaptiveDestination> destinations;

  /// Индекс выбранного пункта.
  final int selectedIndex;

  /// Вызывается при выборе пункта с его индексом.
  final ValueChanged<int> onDestinationSelected;

  /// Содержимое экрана.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < AppBreakpoints.mobileMax) {
          return Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
          );
        }
        final extended = width >= AppBreakpoints.tabletMax;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                extended: extended,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.selected,
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}
