import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas/tool_catalog.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/l10n.dart';
import 'package:jingyao_paint/skill_level.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'test_helpers.dart';
import 'widget_test.dart' show openTools, pumpApp, scrollTools;

/// The app as a kid finds it before adding anything (every drawer section
/// open, so all groups can be seen).
Future<TestApp> pumpWithBasics(
  WidgetTester tester, {
  String level = 'advanced',
}) async => pumpApp(
  tester,
  screen: const Size(800, 1280),
  app: await createTestApp(
    fresh: true,
    prefs: {
      for (final e in testDefaults.entries)
        if (!allToolsAdded.containsKey(e.key)) e.key: e.value,
      'flutter.level': level,
    },
  ),
);

Finder chip(String label) => find.descendant(
  of: find.byKey(CanvasPageState.toolsListKey),
  matching: find.text(label),
);

Future<void> tapInSheet(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    target,
    120,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('addToolsList')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(target);
  await tester.pump();
}

void main() {
  group('Adding tools', () {
    testWidgets('a kid starts with the basic options and an 添加 in each '
        'group', (tester) async {
      await pumpWithBasics(tester);
      await openTools(tester);
      for (final basic in ['自由画', '直线', '矩形', '圆形', '填充']) {
        expect(chip(basic), findsOneWidget, reason: basic);
      }
      for (final more in ['星形', '云朵', '五边形', '自由形状']) {
        expect(chip(more), findsNothing, reason: more);
      }
      await scrollTools(tester, find.byKey(const ValueKey('addTo.textures')));
      expect(chip('纸纹'), findsOneWidget);
      expect(chip('炭笔'), findsNothing);
      expect(chip('柔光'), findsNothing);
      for (final g in ['shapes', 'gradients', 'blends', 'textures']) {
        expect(find.byKey(ValueKey('addTo.$g')), findsOneWidget, reason: g);
      }
    });

    testWidgets('several picked at once go to their own groups; unpicked '
        'ones go away', (tester) async {
      final app = await pumpWithBasics(tester);
      await openTools(tester);
      await tester.tap(find.byKey(const ValueKey('addTo.shapes')));
      await tester.pumpAndSettle();
      expect(find.text('添加工具'), findsWidgets);
      await tapInSheet(tester, 'add.shapes.star');
      await tapInSheet(tester, 'add.shapes.cloud');
      await tapInSheet(tester, 'add.textures.wood');
      await tester.tap(find.byKey(const ValueKey('addToolsDone')));
      await tester.pumpAndSettle();
      expect(app.settings.addedTools, {
        'shapes.star',
        'shapes.cloud',
        'textures.wood',
      });
      expect(chip('星形'), findsOneWidget);
      expect(chip('云朵'), findsOneWidget);
      await scrollTools(tester, chip('木纹'));
      expect(chip('木纹'), findsOneWidget);

      // Taken out again from the button at the bottom; 取消 changes nothing.
      await scrollTools(tester, find.byKey(const ValueKey('addToolsButton')));
      await tester.tap(find.byKey(const ValueKey('addToolsButton')));
      await tester.pumpAndSettle();
      await tapInSheet(tester, 'add.shapes.star');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(app.settings.addedTools, contains('shapes.star'));
      await tester.tap(find.byKey(const ValueKey('addToolsButton')));
      await tester.pumpAndSettle();
      await tapInSheet(tester, 'add.shapes.star');
      await tester.tap(find.byKey(const ValueKey('addToolsDone')));
      await tester.pumpAndSettle();
      expect(app.settings.addedTools, {'shapes.cloud', 'textures.wood'});
      expect(chip('星形'), findsNothing);
    });

    testWidgets('picking a shape from the drawer after adding it draws it', (
      tester,
    ) async {
      final app = await pumpWithBasics(tester);
      app.settings.addedTools = {'shapes.lightning'};
      await openTools(tester);
      await tester.tap(
        find.ancestor(of: chip('闪电'), matching: find.byType(ChoiceChip)),
      );
      await tester.pump();
      expect(app.settings.shape, ShapeKind.lightning);
    });

    test('beginners can add the simple shapes and the stamps; the other '
        'groups come with the levels', () async {
      final app = await createTestApp(prefs: {'flutter.level': 'beginner'});
      final s = app.settings;
      String keysOf(ToolGroup g) => [
        for (final o in ToolCatalog.options(g, s, const S('zh')))
          if (!o.basic) o.name,
      ].join(',');
      expect(
        keysOf(ToolGroup.shapes),
        'arrow,triangle,star,heart,cloud,moon,drop,arc,wave',
      );
      expect(keysOf(ToolGroup.stamps), 'sun,leaf,paw,note');
      expect(
        [
          for (final g in ToolGroup.values)
            if (g.allowedAt(s.level)) g,
        ],
        [ToolGroup.shapes, ToolGroup.stamps],
      );
      s.level = SkillLevel.intermediate;
      expect(keysOf(ToolGroup.shapes), contains('free,arrow'));
      expect(keysOf(ToolGroup.shapes), contains('pentagon'));
      expect(ToolGroup.gradients.allowedAt(s.level), isTrue);
      expect(ToolGroup.textures.allowedAt(s.level), isFalse);
    });

    testWidgets('a chosen option stays in sight even if it was never added', (
      tester,
    ) async {
      final app = await pumpWithBasics(tester);
      app.settings.texture = StrokeTexture.wood;
      await openTools(tester);
      await scrollTools(tester, chip('木纹'));
      expect(chip('木纹'), findsOneWidget);
    });
  });

  group('New shapes', () {
    test('every shape fits its box; the closed ones close; a wave runs along '
        'the drag, even a flat one', () {
      const a = Offset(10, 10), b = Offset(110, 90);
      final box = Rect.fromPoints(a, b).inflate(2);
      for (final k in ShapeKind.values) {
        final path = k.path(a, b);
        final bounds = path.getBounds();
        expect(bounds.isEmpty, isFalse, reason: k.name);
        // A wave swings a twelfth of its length to either side of the drag.
        final room = k == ShapeKind.wave ? box.inflate((b - a).distance / 12) : box;
        expect(
          room.contains(bounds.topLeft) && room.contains(bounds.bottomRight),
          isTrue,
          reason: '${k.name} $bounds',
        );
        if (k.closed) {
          expect(
            path.computeMetrics().every((m) => m.isClosed),
            isTrue,
            reason: k.name,
          );
        }
      }
      final flat = ShapeKind.wave.path(const Offset(0, 50), const Offset(120, 50));
      expect(flat.getBounds().height, closeTo(20, 1), reason: 'waves up and down');
      expect(
        ShapeKind.arc.path(a, b).getBounds(),
        isA<Rect>()
            .having((r) => r.top, 'top', closeTo(10, 0.5))
            .having((r) => r.bottom, 'bottom', closeTo(90, 0.5)),
        reason: 'from the bottom corners up to the top middle',
      );
    });

    test('new shapes save their outline, so older versions draw it', () {
      for (final k in ShapeKind.values) {
        final s = Stroke.shape(
          shape: k,
          from: const Offset(10, 10),
          to: const Offset(110, 90),
          brush: BrushType.pen,
          color: Colors.black,
          size: 4,
          fill: true,
          isComplete: true,
        );
        final json = s.toJson();
        final points = json['points']! as List;
        expect(points.isNotEmpty, k.savesOutline, reason: k.name);
        final back = Stroke.fromJson(json);
        expect(back.shape, k);
        expect(back.bounds, s.bounds);
        if (k.savesOutline) {
          // An older version: the shape's name means nothing to it.
          final old = Stroke.fromJson({...json, 'shape': 'unknown'});
          expect(old.shape, isNull);
          expect(old.points.length, points.length ~/ 3);
          expect(old.bounds.overlaps(s.bounds), isTrue);
        }
      }
    });
  });

  group('New stamps, gradients and light', () {
    test('every stamp paints', () async {
      for (final st in StampShape.values) {
        final s = Stroke(
          brush: BrushType.stamp,
          color: Colors.black,
          size: 20,
          usesRealPressure: false,
          stamp: st,
          seed: 1,
          isComplete: true,
          points: [const PointVector(30, 30, 0.5)],
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)
          ..drawRect(
            const Rect.fromLTWH(0, 0, 60, 60),
            Paint()..color = Colors.white,
          );
        s.paint(canvas);
        final image = await recorder.endRecording().toImage(60, 60);
        final data = (await image.toByteData())!;
        var inked = 0;
        for (var i = 0; i < data.lengthInBytes; i += 4) {
          if (data.getUint8(i) < 128) inked++;
        }
        expect(inked, greaterThan(150), reason: st.name);
      }
    });

    test('every gradient but none mixes colors; the rainbow goes round the '
        'color wheel even from black', () {
      for (final g in GradientStyle.values.skip(1)) {
        expect(
          g.forColor(Colors.blue)!.colors.length,
          greaterThanOrEqualTo(2),
          reason: g.name,
        );
      }
      final rainbow = GradientStyle.rainbow.forColor(Colors.black)!.colors;
      expect(rainbow, hasLength(6));
      expect({
        for (final c in rainbow) HSLColor.fromColor(c).hue.round() ~/ 30,
      }, hasLength(6));
      final red = const Color(0xFFE53935);
      final opposite = GradientStyle.contrast.forColor(red)!.colors.last;
      expect(
        (HSLColor.fromColor(opposite).hue - HSLColor.fromColor(red).hue)
            .abs()
            .round(),
        inInclusiveRange(178, 182),
      );
    });

    test('the new light & shadow modes and textures are saved', () {
      for (final b in StrokeBlend.values) {
        final s = Stroke(
          brush: BrushType.pen,
          color: Colors.black,
          size: 4,
          usesRealPressure: false,
          blend: b,
          texture: StrokeTexture.values[b.index % StrokeTexture.values.length],
          isComplete: true,
          points: [const PointVector(1, 1, 0.5), const PointVector(9, 9, 0.5)],
        );
        final back = Stroke.fromJson(s.toJson());
        expect(back.blend, b);
        expect(back.texture, s.texture);
      }
    });
  });
}
