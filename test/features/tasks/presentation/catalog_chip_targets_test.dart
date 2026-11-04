import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';
import 'package:yege_wars/features/tasks/presentation/controllers/catalog_controllers.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/catalog_filters_bar.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../../helpers/button_height.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_tasks_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final l10n = AppLocalizationsRu();
  final labels = [
    l10n.referenceEgeNumber(17),
    l10n.referenceEgeNumber(24),
    l10n.difficultyEasy,
    l10n.difficultyMedium,
    l10n.difficultyHard,
    l10n.progressNotStarted,
    l10n.progressAttempted,
    l10n.progressSolved,
  ];
  const platforms = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.android,
    TargetPlatform.iOS,
  });

  testWidgets('UC-14-P-02 TOKEN-6: области чипов и краевые нажатия', (
    tester,
  ) async {
    final desktop =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    await tester.binding.setSurfaceSize(
      desktop ? const Size(1440, 900) : const Size(360, 800),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final tasks = FakeTasksRepository();
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      tasks: tasks,
    );

    for (var i = 0; i < labels.length; i++) {
      final chip = find.widgetWithText(FilterChip, labels[i]);
      Rect rect() => tester.getRect(chip);
      void size() {
        expect(
          rect().width,
          greaterThanOrEqualTo(minTapTarget),
          reason: labels[i],
        );
        expect(
          rect().height,
          greaterThanOrEqualTo(minTapTarget),
          reason: labels[i],
        );
      }

      Future<void> edge({required bool top}) async {
        final bounds = rect();
        await tester.tapAt(
          Offset(bounds.center.dx, top ? bounds.top + 1 : bounds.bottom - 1),
        );
        await tester.pumpAndSettle();
      }

      size();
      for (final top in [true, false]) {
        await edge(top: top);
        expect(
          tester.widget<FilterChip>(chip).selected,
          isTrue,
          reason: labels[i],
        );
        final filter = tasks.lastFilter!;
        if (i < 2) expect(filter.egeNumber, [17, 24][i]);
        if (i >= 2 && i < 5) {
          expect(filter.difficulty, TaskDifficulty.values[i - 2]);
        }
        if (i >= 5) expect(filter.progress, TaskProgress.values[i - 5]);
        size();
        await edge(top: top);
        expect(
          tester.widget<FilterChip>(chip).selected,
          isFalse,
          reason: labels[i],
        );
        expect(tasks.lastFilter!.isEmpty, isTrue);
      }
    }
    expect(tester.takeException(), isNull);
  }, variant: platforms);

  testWidgets('UC-14-P-02: сочетание, замена, сброс и прокрутка номеров', (
    tester,
  ) async {
    final desktop =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    await tester.binding.setSurfaceSize(
      desktop ? const Size(1440, 900) : const Size(360, 800),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final tasks = FakeTasksRepository()
      ..egeNumbersResult = Ok(List.generate(30, (i) => i + 1));
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      tasks: tasks,
    );
    Future<void> tap(String label) async {
      await tester.tap(find.widgetWithText(FilterChip, label));
      await tester.pumpAndSettle();
    }

    await tap(l10n.referenceEgeNumber(1));
    await tap(l10n.referenceEgeNumber(2));
    expect(tasks.lastFilter!.egeNumber, 2);
    await tap(l10n.difficultyEasy);
    await tap(l10n.difficultyHard);
    expect(tasks.lastFilter!.difficulty, TaskDifficulty.hard);
    await tap(l10n.progressNotStarted);
    await tap(l10n.progressSolved);
    expect(tasks.lastFilter!.progress, TaskProgress.solved);
    expect(tasks.lastFilter!.egeNumber, 2);
    final reset = find.text(l10n.catalogResetFilters);
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(tasks.lastFilter!.isEmpty, isTrue);
    final scroll = find.descendant(
      of: find.byType(CatalogFiltersBar),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(scroll, const Offset(-3000, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .getRect(find.widgetWithText(FilterChip, l10n.referenceEgeNumber(30)))
          .right,
      lessThanOrEqualTo(tester.getRect(scroll).right),
    );
    expect(
      containerOf(tester).read(taskFilterControllerProvider).isEmpty,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, variant: platforms);
}
