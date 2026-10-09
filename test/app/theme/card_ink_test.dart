import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_theme.dart';
import 'package:yege_wars/features/reference/presentation/widgets/article_card.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_file.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_card.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_files_panel.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

import '../../helpers/fake_reference_repository.dart';
import '../../helpers/fake_tasks_repository.dart';

/// Ключ границы снимка: верхний левый угол снимка — угол карточки.
const Key _boundaryKey = ValueKey('card-snapshot');

/// Снимок карточки: ширина в пикселях и байты RGBA.
typedef _Snapshot = ({int width, ByteData bytes});

void main() {
  /// Рисует карточку [card] в теме приложения, вне карточки — прозрачно.
  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(key: _boundaryKey, child: card),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Снимает карточку в логических пикселях.
  Future<_Snapshot> snapshot(WidgetTester tester) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData();
      image.dispose();
      return data;
    });
    return (width: boundary.size.width.round(), bytes: bytes!);
  }

  /// Цвет пикселя (x, y) снимка — RGBA одним числом.
  int pixel(_Snapshot snapshot, int x, int y) =>
      snapshot.bytes.getUint32((y * snapshot.width + x) * 4);

  /// Наводит мышь на [target] и нажимает, держа: отклик карточки — внутри
  /// скругления. Угол снимка лежит вне скругления: без обрезки по форме
  /// подсветка закрасила бы его. В поле отступа на высоте [target], где нет
  /// текста, цвет при наведении другой: отклик вообще есть.
  Future<void> expectInkInsideCorners(
    WidgetTester tester,
    Finder target,
  ) async {
    final idle = await snapshot(tester);
    final origin = tester.getTopLeft(find.byKey(_boundaryKey));
    final center = tester.getCenter(target);
    final insideX = (AppSpacing.lg / 2).round();
    final insideY = (center.dy - origin.dy).round();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();

    final hovered = await snapshot(tester);
    expect(pixel(hovered, 1, 1), pixel(idle, 1, 1), reason: 'наведение');
    expect(
      pixel(hovered, insideX, insideY),
      isNot(pixel(idle, insideX, insideY)),
      reason: 'подсветки при наведении нет',
    );

    await gesture.down(center);
    await tester.pump(const Duration(milliseconds: 500));

    final pressed = await snapshot(tester);
    expect(pixel(pressed, 1, 1), pixel(idle, 1, 1), reason: 'нажатие');

    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('COMP-5: отклик карточки задачи не выходит за '
      'скругление', (tester) async {
    await pumpCard(tester, TaskCard(item: testFreshItem, onTap: () {}));

    await expectInkInsideCorners(tester, find.byType(TaskCard));
  });

  testWidgets('COMP-14: отклик карточки статьи не выходит за '
      'скругление', (tester) async {
    await pumpCard(tester, ArticleCard(brief: testFileReading, onTap: () {}));

    await expectInkInsideCorners(tester, find.byType(ArticleCard));
  });

  testWidgets('UC-15-P-01: отклик карточки файла не выходит за '
      'скругление', (tester) async {
    await pumpCard(
      tester,
      const TaskFilesPanel(
        files: [
          TaskFile(filename: '24.txt', content: 'ABCABC\n', sizeBytes: 7),
        ],
      ),
    );

    await expectInkInsideCorners(tester, find.text('24.txt'));
  });
}
