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
        [
          ToolGroup.brushes,
          ToolGroup.helpers,
          ToolGroup.shapes,
          ToolGroup.stamps,
        ],
      );
      expect(keysOf(ToolGroup.brushes), 'rainbow,stamp');
      expect(keysOf(ToolGroup.helpers), '', reason: 'no picker yet');
      s.level = SkillLevel.intermediate;
      expect(keysOf(ToolGroup.shapes), contains('free,arrow'));
      expect(keysOf(ToolGroup.shapes), contains('pentagon'));
      expect(keysOf(ToolGroup.brushes), 'highlighter,soft,rainbow,stamp');
      expect(keysOf(ToolGroup.helpers), 'picker');
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

  group('Brushes and helpers', () {
    testWidgets('four brushes and the basic helpers to start; more are added '
        'the same way; the move tool is at the top', (tester) async {
      final app = await pumpWithBasics(tester);
      await openTools(tester);
      for (final b in ['钢笔', '铅笔', '马克笔', '喷枪', '小帮手', '橡皮擦', '油漆桶', '文字']) {
        expect(chip(b), findsOneWidget, reason: b);
      }
      for (final b in ['荧光笔', '柔边笔', '彩虹笔', '印章', '晕染笔', '吸管', '选择移动']) {
        expect(chip(b), findsNothing, reason: b);
      }
      await tester.tap(find.byKey(const ValueKey('addTo.brushes')));
      await tester.pumpAndSettle();
      await tapInSheet(tester, 'add.brushes.rainbow');
      await tapInSheet(tester, 'add.helpers.picker');
      await tester.tap(find.byKey(const ValueKey('addToolsDone')));
      await tester.pumpAndSettle();
      expect(app.settings.addedTools, {'brushes.rainbow', 'helpers.picker'});
      expect(chip('彩虹笔'), findsOneWidget);
      expect(chip('吸管'), findsOneWidget);
      expect(find.byKey(const ValueKey('moveToolButton')), findsOneWidget);
    });
  });

  group('My brushes', () {
    testWidgets('the brush in use is saved with its settings, picked again in '
        'one tap, and deleted by a long press', (tester) async {
      final app = await pumpWithBasics(tester);
      final s = app.settings
        ..brush = BrushType.marker
        ..color = const Color(0xFFE53935)
        ..size = 24
        ..opacity = 0.6
        ..texture = StrokeTexture.crayon;
      await openTools(tester);
      await tester.tap(find.byKey(const ValueKey('saveBrush')));
      await tester.pumpAndSettle();
      expect(find.text('给这支画笔起个名字'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '我的画笔 1',
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '小红笔',
      );
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(s.brushPresets.single.name, '小红笔');
      expect(chip('小红笔'), findsOneWidget);

      // Something else, then the saved brush again.
      s
        ..brush = BrushType.pen
        ..color = const Color(0xFF1E88E5)
        ..texture = StrokeTexture.none;
      await tester.pump();
      await tester.tap(chip('小红笔'));
      await tester.pump();
      expect(s.brush, BrushType.marker);
      expect(s.color.toARGB32(), 0xFFE53935);
      expect(s.size, 24);
      expect(s.opacity, closeTo(0.6, 0.01));
      expect(s.texture, StrokeTexture.crayon);
      expect(s.isPreset(s.brushPresets.single), isTrue);

      await tester.longPress(chip('小红笔'));
      await tester.pumpAndSettle();
      expect(find.text('删除「小红笔」？'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await tester.pumpAndSettle();
      expect(s.brushPresets, isEmpty);
      expect(chip('小红笔'), findsNothing);
    });

    test('my brushes are saved; a broken entry is skipped', () async {
      final app = await createTestApp(
        prefs: {
          'flutter.brushPresets': <String>['not json'],
        },
      );
      final s = app.settings;
      expect(s.brushPresets, isEmpty);
      s
        ..brush = BrushType.soft
        ..color = const Color(0xFF43A047)
        ..gradient = GradientStyle.rainbow
        ..blend = StrokeBlend.color;
      s.brushPresets = [s.presetNow('a', '彩虹软笔')];
      final back = s.brushPresets.single;
      expect(back.name, '彩虹软笔');
      expect(back.brush, BrushType.soft);
      expect(back.gradient, GradientStyle.rainbow);
      expect(back.blend, StrokeBlend.color);
      expect(back.color.toARGB32(), 0xFF43A047);
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
        final room = k == ShapeKind.wave
            ? box.inflate((b - a).distance / 12)
            : box;
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
      final flat = ShapeKind.wave.path(
        const Offset(0, 50),
        const Offset(120, 50),
      );
      expect(
        flat.getBounds().height,
        closeTo(20, 1),
        reason: 'waves up and down',
      );
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
