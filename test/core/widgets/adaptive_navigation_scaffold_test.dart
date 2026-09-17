import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/widgets/adaptive_navigation_scaffold.dart';

void main() {
  const catalogLabel = 'Каталог';
  const profileLabel = 'Профиль';

  const destinations = [
    AdaptiveDestination(
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
      label: catalogLabel,
    ),
    AdaptiveDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: profileLabel,
    ),
  ];

  Future<void> pumpScaffold(
    WidgetTester tester, {
    required double width,
    ValueChanged<int>? onDestinationSelected,
  }) async {
    tester.view
      ..physicalSize = Size(width, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveNavigationScaffold(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: onDestinationSelected ?? (_) {},
          body: const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets(
    'при ширине 400 показывается NavigationBar без NavigationRail',
    (tester) async {
      await pumpScaffold(tester, width: 400);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    },
  );

  testWidgets(
    'при ширине 1280 показывается развёрнутый NavigationRail '
    'без NavigationBar',
    (tester) async {
      await pumpScaffold(tester, width: 1280);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    },
  );

  testWidgets(
    'тап по пункту NavigationBar вызывает onDestinationSelected '
    'с верным индексом',
    (tester) async {
      int? tappedIndex;
      await pumpScaffold(
        tester,
        width: 400,
        onDestinationSelected: (index) => tappedIndex = index,
      );

      await tester.tap(find.text(profileLabel));

      expect(tappedIndex, 1);
    },
  );

  testWidgets(
    'тап по пункту NavigationRail вызывает onDestinationSelected '
    'с верным индексом',
    (tester) async {
      int? tappedIndex;
      await pumpScaffold(
        tester,
        width: 1280,
        onDestinationSelected: (index) => tappedIndex = index,
      );

      await tester.tap(find.text(profileLabel));

      expect(tappedIndex, 1);
    },
  );
}
