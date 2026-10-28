import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas/color_widgets.dart';
import 'package:jingyao_paint/drawing/canvas/layer_panel.dart';
import 'package:jingyao_paint/drawing/canvas/tool_section.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/widgets/corner_float.dart';

import 'test_helpers.dart';
import 'widget_test.dart' show closeTools, openTools, pumpApp, scrollTools;

/// The app as a new user finds the drawer: sections open or closed as they
/// start (the other tests open them all).
Future<TestApp> pumpAsNew(WidgetTester tester) async => pumpApp(
  tester,
  app: await createTestApp(
    fresh: true,
    prefs: {
      for (final e in testDefaults.entries)
        if (!allSectionsOpen.containsKey(e.key) &&
            !allToolsAdded.containsKey(e.key))
          e.key: e.value,
    },
  ),
);

Finder heading(ToolSection s) => find.byKey(ValueKey('section.${s.name}'));

void main() {
  group('Tools drawer sections', () {
    testWidgets('the everyday ones start open, the level\'s extras closed', (
      tester,
    ) async {
      final app = await pumpAsNew(tester);
      await openTools(tester);
      expect(find.text('钢笔'), findsOneWidget, reason: 'brushes open');
      expect(heading(ToolSection.helpers), findsOneWidget);
      expect(find.text('橡皮擦'), findsOneWidget, reason: 'helpers open');
      await scrollTools(tester, heading(ToolSection.gradient));
      expect(find.text('上亮'), findsNothing, reason: 'gradients closed');
      for (final s in ToolSection.values) {
        expect(s.isOpen(app.settings), s.openAtFirst, reason: s.name);
      }
      expect(
        [
          for (final s in ToolSection.values)
            if (s.openAtFirst) s,
        ],
        [
          ToolSection.brushes,
          ToolSection.helpers,
          ToolSection.colors,
          ToolSection.shapes,
          ToolSection.stamps,
        ],
      );
    });

    testWidgets('a tap opens or closes one, and the drawer remembers', (
      tester,
    ) async {
      final app = await pumpAsNew(tester);
      await openTools(tester);
      await tester.tap(find.text('油漆桶'));
      await tester.pumpAndSettle();
      expect(app.settings.brush, BrushType.bucket);

      // Closed, a heading says what's chosen in it.
      await tester.tap(heading(ToolSection.helpers));
      await tester.pumpAndSettle();
      expect(find.text('油漆桶'), findsNothing);
      expect(find.text('· 油漆桶'), findsOneWidget);
      expect(app.settings.sectionOpen('helpers', byDefault: true), isFalse);

      await closeTools(tester);
      await openTools(tester);
      expect(find.text('· 油漆桶'), findsOneWidget, reason: 'still closed');
      expect(
        tester.getSemantics(heading(ToolSection.helpers)),
        isSemantics(
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('size and opacity sit right under the colors', (tester) async {
      // A tall tablet: the whole drawer at once.
      await pumpApp(tester, screen: const Size(800, 1280));
      await openTools(tester);
      final colors = tester.getRect(heading(ToolSection.colors));
      final lastSwatch = tester.getRect(find.byType(Swatch).last);
      final sliders = find.byType(Slider);
      final size = tester.getRect(sliders.first);
      final opacity = tester.getRect(sliders.at(1));
      final shapes = tester.getRect(heading(ToolSection.shapes));
      expect(colors.top, lessThan(lastSwatch.top));
      expect(size.top, greaterThan(lastSwatch.bottom));
      expect(size.top - lastSwatch.bottom, lessThan(40));
      expect(opacity.top, greaterThan(size.top));
      expect(shapes.top, greaterThan(opacity.bottom));
    });
  });

  group('The layers button', () {
    testWidgets('sits right above the tools button until dragged elsewhere', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      final layers = tester.getRect(find.byType(LayersButton));
      final tools = tester.getRect(find.byKey(CanvasPageState.toolsButtonKey));
      expect(layers.right, closeTo(tools.right, 1));
      expect(tools.top - layers.bottom, closeTo(10, 1));

      // It goes along when the tools button moves, until it's dragged.
      app.settings.toolsCorner = Corner.bottomLeft;
      await tester.pumpAndSettle();
      final left = tester.getRect(find.byType(LayersButton));
      final toolsLeft = tester.getRect(
        find.byKey(CanvasPageState.toolsButtonKey),
      );
      expect(left.left, closeTo(toolsLeft.left, 1));
      expect(left.bottom, lessThan(toolsLeft.top));

      // Dragged to the top, it stays there; not onto undo's corner.
      await tester.drag(find.byType(LayersButton), const Offset(250, -600));
      await tester.pumpAndSettle();
      expect(app.settings.undoCorner, Corner.topRight);
      expect(
        app.settings.layersCorner,
        Corner.topLeft,
        reason: 'top right is taken by undo',
      );
      app.settings.toolsCorner = Corner.bottomRight;
      await tester.pumpAndSettle();
      expect(app.settings.layersCorner, Corner.topLeft);
      expect(tester.getRect(find.byType(LayersButton)).top, lessThan(100));
    });

    testWidgets('a tap opens the layers', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(LayersButton));
      await tester.pumpAndSettle();
      expect(find.byType(LayerSheet), findsOneWidget);
    });
  });
}
