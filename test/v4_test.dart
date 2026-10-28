import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/app_theme.dart' show kThemeIds;
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/drawing_controller.dart';
import 'package:jingyao_paint/drawing/render/render_image.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/level_samples.dart';
import 'package:jingyao_paint/l10n.dart';
import 'package:jingyao_paint/onboarding_page.dart';
import 'package:jingyao_paint/settings.dart';
import 'package:jingyao_paint/settings_page.dart'
    show SkillLevelCard, TextSizeCard;
import 'package:jingyao_paint/skill_level.dart';
import 'package:jingyao_paint/widgets/menu_button.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';
import 'v3_test.dart' show b8, box, g8, pixel, r8;
import 'widget_test.dart'
    show
        closeTools,
        drawStroke,
        leaveSettings,
        openSettings,
        openTab,
        openTools,
        pumpApp,
        scrollTools;

/// A straight line across the paper, a point every 2px.
Stroke line(Offset from, Offset to,
        {BrushType brush = BrushType.marker,
        Color color = const Color(0xFF8B3A1A),
        double size = 10,
        double opacity = 1,
        StrokeTexture texture = StrokeTexture.none}) =>
    Stroke(
      brush: brush,
      color: color,
      size: size,
      opacity: opacity,
      usesRealPressure: false,
      seed: 5,
      texture: texture,
      isComplete: true,
      points: [
        for (var t = 0.0; t <= 1; t += 2 / (to - from).distance)
          PointVector(Offset.lerp(from, to, t)!.dx,
              Offset.lerp(from, to, t)!.dy, 0.5),
      ],
    );

/// Red on the left half of a 60×40 paper, blue on the right.
List<Stroke> redBlue() => [
      box(const Rect.fromLTWH(0, 0, 30, 40), const Color(0xFFFF0000)),
      box(const Rect.fromLTWH(30, 0, 30, 40), const Color(0xFF0000FF)),
    ];

Stroke blender({double opacity = 1}) => line(
    const Offset(30, 2), const Offset(30, 38),
    brush: BrushType.smudge, size: 6, opacity: opacity);

const _wide = Size(60, 40);

void main() {
  group('Textures', () {
    test('a texture lets the paper show through the paint', () async {
      for (final t in StrokeTexture.values) {
        final s = line(const Offset(4, 20), const Offset(196, 20),
            size: 20, texture: t);
        final raw =
            await renderRgba([s], const Size(200, 40), 1);
        // The red channel over the middle of the line: solid paint is
        // 0x8B everywhere; grain makes it lighter in places.
        final reds = [
          for (var x = 20; x < 180; x++) raw.rgba[(20 * raw.width + x) * 4],
        ];
        final lighter = reds.where((r) => r > 0x8B + 12).length;
        if (t == StrokeTexture.none) {
          expect(lighter, 0, reason: 'plain paint is solid');
        } else {
          expect(lighter, greaterThan(8), reason: t.name);
          expect(reds.where((r) => r < 0x8B + 12), isNotEmpty,
              reason: '${t.name} still paints');
        }
      }
    });

    test('textures are saved and look the same when reopened', () async {
      for (final t in StrokeTexture.values) {
        final s = line(const Offset(4, 20), const Offset(56, 20),
            size: 20, texture: t);
        final back = Stroke.fromJson(s.toJson());
        expect(back.texture, t);
        final a = await renderRgba([s], _wide, 1);
        final b = await renderRgba([back], _wide, 1);
        expect(a.rgba, b.rgba, reason: t.name);
      }
      expect(line(Offset.zero, const Offset(9, 9)).toJson(),
          isNot(contains('texture')),
          reason: 'plain strokes keep their old file format');
    });

    test('filled shapes and moved strokes keep their texture', () {
      final s = box(const Rect.fromLTWH(0, 0, 20, 20), Colors.green);
      final textured = Stroke.shape(
        shape: ShapeKind.ellipse,
        from: Offset.zero,
        to: const Offset(20, 20),
        brush: BrushType.pen,
        color: Colors.green,
        size: 2,
        fill: true,
        texture: StrokeTexture.canvas,
        isComplete: true,
      );
      expect(s.texture, StrokeTexture.none);
      expect(textured.moved(const Offset(5, 5)).texture, StrokeTexture.canvas);
      expect(textured.copyWith(color: Colors.red).texture,
          StrokeTexture.canvas);
      expect(Stroke.fromJson(textured.toJson()).texture, StrokeTexture.canvas);
    });
  });

  group('Blender', () {
    test('mixes the colors under it, and nothing else', () async {
      final strokes = [...redBlue(), blender()];
      final mid = await pixel(strokes, 30, 20, size: _wide);
      expect(r8(mid), inInclusiveRange(60, 200), reason: 'some red');
      expect(b8(mid), inInclusiveRange(60, 200), reason: 'some blue');
      final away = await pixel(strokes, 4, 20, size: _wide);
      expect(r8(away), 255, reason: 'far from it, red stays red');
      expect(b8(away), 0);
    });

    test('paints nothing on blank paper', () async {
      final px = await pixel([blender()], 30, 20, size: _wide);
      expect(px.toARGB32(), 0xFFFFFFFF);
    });

    test('opacity sets how much it mixes', () async {
      final strong = await pixel([...redBlue(), blender()], 28, 20, size: _wide);
      final weak = await pixel(
          [...redBlue(), blender(opacity: 0.3)], 28, 20, size: _wide);
      expect(b8(strong), greaterThan(b8(weak)));
      expect(b8(weak), greaterThan(0));
    });

    test('follows what is under it when that moves', () async {
      final drawing = DrawingController()..load([...redBlue(), blender()]);
      Future<Color> mid() async {
        final recorder = ui.PictureRecorder();
        drawing.paintFinished(Canvas(recorder), _wide);
        final image = await recorder.endRecording().toImage(60, 40);
        final data = await image.toByteData();
        final i = (20 * 60 + 30) * 4;
        return Color.fromARGB(255, data!.getUint8(i), data.getUint8(i + 1),
            data.getUint8(i + 2));
      }

      final before = await mid();
      expect(g8(before), lessThan(20), reason: 'red and blue');
      // The blue moves away: now red and the white paper are mixed there.
      final blue = drawing.strokes[1];
      drawing.replace(blue, blue.moved(const Offset(40, 0)));
      final after = await mid();
      expect(g8(after), greaterThan(60));
      expect(r8(after), greaterThan(200));
    });

    test('is saved, and is never picked up or selected', () {
      final s = blender(opacity: 0.6);
      final back = Stroke.fromJson(s.toJson());
      expect(back.brush, BrushType.smudge);
      expect(back.opacity, 0.6);
      final drawing = DrawingController()..load([s]);
      expect(drawing.hitStroke(const Offset(30, 20)), isNull);
      expect(drawing.strokesIn(const Rect.fromLTWH(0, 0, 60, 40)), isEmpty);
      expect(BrushType.smudge.usesColor, isFalse);
      expect(BrushType.smudge.usesTexture, isFalse);
      expect(BrushType.smudge.isEffect, isTrue);
    });

    test('shows the blend while it is being drawn', () async {
      final drawing = DrawingController()..load(redBlue());
      drawing.begin(
          Stroke(
              brush: BrushType.smudge,
              color: Colors.black,
              size: 6,
              usesRealPressure: false),
          const PointVector(30, 2, 0.5));
      for (var y = 4.0; y <= 38; y += 2) {
        drawing.extend(PointVector(30, y, 0.5));
      }
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawRect(Offset.zero & _wide, Paint()..color = Colors.white);
      drawing
        ..paintFinished(canvas, _wide)
        ..paintCurrent(canvas, _wide);
      final image = await recorder.endRecording().toImage(60, 40);
      final data = await image.toByteData();
      final i = (20 * 60 + 28) * 4;
      expect(data!.getUint8(i + 2), greaterThan(40), reason: 'blue mixed in');
      drawing.end();
      expect(drawing.strokes.last.brush, BrushType.smudge);
    });
  });

  group('Levels', () {
    test('each level shows more; beginners get the simple tools', () {
      expect(SkillLevel.beginner.brushes, [
        BrushType.pen, BrushType.pencil, BrushType.marker, BrushType.spray,
        BrushType.rainbow, BrushType.stamp, BrushType.bucket, BrushType.text,
        BrushType.eraser,
      ]);
      expect(SkillLevel.intermediate.brushes,
          containsAll([BrushType.highlighter, BrushType.soft, BrushType.move]));
      expect(SkillLevel.intermediate.brushes, isNot(contains(BrushType.smudge)));
      expect(SkillLevel.advanced.brushes, BrushType.values);
      for (final level in SkillLevel.values) {
        expect(level.brushes, containsAll(SkillLevel.beginner.brushes));
      }
      expect(SkillLevel.beginner.opacity, isFalse);
      expect(SkillLevel.intermediate.gradients, isTrue);
      expect(SkillLevel.intermediate.textures, isFalse);
      expect(SkillLevel.advanced.lightAndShadow, isTrue);
    });

    test('a new install starts at beginner; the level is remembered',
        () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.load();
      expect(settings.level, SkillLevel.beginner);
      settings.level = SkillLevel.intermediate;
      expect((await AppSettings.load()).level, SkillLevel.intermediate);
      await settings.resetAll();
      expect(settings.level, SkillLevel.beginner);
    });

    test('hidden options read as plain ones and come back later', () async {
      final app = await createTestApp();
      final settings = app.settings
        ..brush = BrushType.smudge
        ..texture = StrokeTexture.paper
        ..gradient = GradientStyle.glow
        ..blend = StrokeBlend.multiply
        ..freeShape = true;
      settings.opacity = 0.4;

      settings.level = SkillLevel.beginner;
      expect(settings.brush, BrushType.pen, reason: 'the blender is hidden');
      expect(settings.texture, StrokeTexture.none);
      expect(settings.gradient, GradientStyle.none);
      expect(settings.blend, StrokeBlend.normal);
      expect(settings.freeShape, isFalse);
      expect(settings.opacity, 1);

      settings.level = SkillLevel.advanced;
      expect(settings.brush, BrushType.smudge);
      expect(settings.texture, StrokeTexture.paper);
      expect(settings.gradient, GradientStyle.glow);
      expect(settings.blend, StrokeBlend.multiply);
      expect(settings.freeShape, isTrue);
      expect(settings.opacity, closeTo(0.4, 1e-9));
    });

    testWidgets('beginners see the simple tools only', (tester) async {
      await pumpApp(tester,
          app: await createTestApp(prefs: {'flutter.level': 'beginner'}));
      await openTools(tester);
      expect(find.text('钢笔'), findsOneWidget);
      expect(find.text('柔边笔'), findsNothing);
      expect(find.text('晕染笔'), findsNothing);
      expect(find.text('选择移动'), findsNothing);
      await scrollTools(tester, find.byIcon(Icons.line_weight_rounded));
      for (final hidden in ['自由形状', '渐变', '光影', '纹理']) {
        expect(find.text(hidden, skipOffstage: false), findsNothing,
            reason: hidden);
      }
      expect(find.byIcon(Icons.opacity_rounded, skipOffstage: false),
          findsNothing);
    });

    testWidgets('advanced shows the blender and textures; a texture goes on '
        'the next stroke', (tester) async {
      final app = await pumpApp(tester);
      await openTools(tester);
      await tester.tap(find.text('晕染笔'));
      await tester.pumpAndSettle();
      expect(find.textContaining('颜色会晕开'), findsOneWidget,
          reason: 'what the blender does');

      app.settings.brush = BrushType.pencil;
      await tester.pumpAndSettle();
      final chip = find.widgetWithText(ChoiceChip, '炭笔');
      await scrollTools(tester, chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(app.settings.texture, StrokeTexture.charcoal);
      await closeTools(tester);
      await drawStroke(tester);
      expect(app.session.drawing.strokes.single.texture,
          StrokeTexture.charcoal);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the level is changed in Settings', (tester) async {
      final app = await pumpApp(tester,
          app: await createTestApp(prefs: {'flutter.level': 'beginner'}));
      await openSettings(tester);
      final tile = find.byKey(SkillLevelCard.tileKey(SkillLevel.advanced));
      await tester.scrollUntilVisible(tile, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(app.settings.level, SkillLevel.advanced);
      expect(
          find.descendant(
              of: tile, matching: find.byIcon(Icons.check_circle_rounded)),
          findsOneWidget);
    });

    testWidgets('the first start asks for a level', (tester) async {
      final app = await createTestApp(fresh: true);
      await pumpApp(tester, app: app);
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('Drawing level'), findsOneWidget);
      final tile = find.byKey(SkillLevelCard.tileKey(SkillLevel.intermediate));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(app.settings.level, SkillLevel.intermediate);
      await tester.ensureVisible(find.byKey(OnboardingPage.startKey));
      await tester.tap(find.byKey(OnboardingPage.startKey));
      await tester.pumpAndSettle();
      expect(find.byType(CanvasPage), findsOneWidget);
      expect(app.settings.level, SkillLevel.intermediate);
    });

    for (final id in kThemeIds) {
      testWidgets('theme $id: textures and levels meet accessibility '
          'guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester,
            app: await createTestApp(prefs: {'flutter.theme': id}),
            screen: const Size(393, 1200));
        await openTools(tester);
        await scrollTools(tester, find.widgetWithText(ChoiceChip, '笔刷痕'));
        await expectLater(tester, meetsGuideline(textContrastGuideline),
            reason: '$id text contrast');
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline),
            reason: '$id tap targets');
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline),
            reason: '$id labels');
        await closeTools(tester);

        await openSettings(tester);
        final card = find.byType(SkillLevelCard);
        await tester.scrollUntilVisible(card, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline),
            reason: '$id settings text contrast');
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline),
            reason: '$id settings tap targets');
        handle.dispose();
      });
    }
  });

  group('Menu button', () {
    testWidgets('stands out on both pages and opens the menu', (tester) async {
      await pumpApp(tester);
      expect(find.byIcon(MenuButton.icon), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
      final size = tester.getSize(find.byType(MenuButton));
      expect(size.height, greaterThanOrEqualTo(48), reason: 'easy to tap');
      await tester.tap(find.byIcon(MenuButton.icon));
      await tester.pumpAndSettle();
      expect(find.widgetWithIcon(ListTile, Icons.settings_rounded),
          findsOneWidget);
      await tester.tapAt(const Offset(5, 600));
      await tester.pumpAndSettle();

      await openTab(tester, 1);
      expect(find.byIcon(MenuButton.icon), findsOneWidget,
          reason: 'My Paintings has the same button');
    });
  });

  group('Text size', () {
    test('is remembered, kept in range and reset', () async {
      final app = await createTestApp();
      final settings = app.settings;
      expect(settings.textScale.value, 1);
      settings.textSize = 1.3;
      expect((await AppSettings.load()).textScale.value, closeTo(1.3, 1e-9));
      settings.textSize = 9;
      expect(settings.textScale.value, AppSettings.maxTextScale);
      settings.textSize = 0.1;
      expect(settings.textScale.value, AppSettings.minTextScale);
      await settings.resetAll();
      expect(settings.textScale.value, 1);
    });

    testWidgets('the buttons and the slider make all text bigger',
        (tester) async {
      final app = await pumpApp(tester);
      await openSettings(tester);
      final larger = find.byTooltip('文字大一点');
      await tester.scrollUntilVisible(larger, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(larger);
      await tester.pumpAndSettle();
      await tester.tap(larger);
      await tester.pumpAndSettle();
      expect(app.settings.textScale.value, closeTo(1.1, 1e-9));
      expect(
          MediaQuery.textScalerOf(tester.element(find.byType(TextSizeCard)))
              .scale(10),
          closeTo(11, 0.01),
          reason: 'every page gets the bigger text');

      await tester.drag(
          find.byKey(TextSizeCard.sliderKey), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(app.settings.textScale.value, AppSettings.maxTextScale);
      final smaller = find.byTooltip('文字小一点');
      await tester.ensureVisible(smaller);
      await tester.pumpAndSettle();
      await tester.tap(smaller);
      await tester.pumpAndSettle();
      expect(app.settings.textScale.value, closeTo(1.4, 1e-9));
      await leaveSettings(tester);
    });

    for (final language in ['zh', 'en']) {
      testWidgets('the largest text still fits a small phone ($language)',
          (tester) async {
        final app = await createTestApp(prefs: {
          'flutter.language': language,
          'flutter.textScale': AppSettings.maxTextScale,
        });
        await pumpApp(tester, app: app, screen: const Size(360, 640));
        app.settings.brush = BrushType.stamp;
        await tester.pumpAndSettle();
        await openTools(tester);
        expect(tester.takeException(), isNull, reason: 'tools');
        await tester.tap(find.byTooltip(
            language == 'zh' ? '收起画笔和颜色' : 'Close brushes and colors'));
        await tester.pumpAndSettle();
        for (final tab in [1, 0]) {
          await openTab(tester, tab);
          expect(tester.takeException(), isNull, reason: 'tab $tab');
        }
        await openSettings(tester);
        await tester.scrollUntilVisible(
            find.byIcon(Icons.info_outline_rounded), 300,
            scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull, reason: 'settings');
        await leaveSettings(tester);
      });
    }

    for (final id in kThemeIds) {
      testWidgets('theme $id: the text size controls meet accessibility '
          'guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester,
            app: await createTestApp(prefs: {'flutter.theme': id}),
            screen: const Size(393, 1200));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline),
            reason: '$id menu button label');
        await openSettings(tester);
        final card = find.byType(TextSizeCard);
        await tester.scrollUntilVisible(card, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline),
            reason: '$id text contrast');
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline),
            reason: '$id tap targets');
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline),
            reason: '$id labels');
        handle.dispose();
      });
    }
  });

  group('Sample paintings for each level', () {
    testWidgets('each opens at its own size and uses its level\'s tools',
        (tester) async {
      for (final level in SkillLevel.values) {
        final doc = (await tester
            .runAsync(() => LevelSamples.load(level, const S('zh'))))!;
        expect(doc.paperSize, const Size(1200, 800), reason: level.name);
        expect(doc.strokes.length, greaterThan(50), reason: level.name);
        final brushes = doc.strokes.map((s) => s.brush).toSet();
        expect(brushes.every(level.allows), isTrue,
            reason: '${level.name} uses only its own brushes: $brushes');
        final textures = doc.strokes.any((s) => s.texture != StrokeTexture.none);
        final blends = doc.strokes.any((s) => s.blend != StrokeBlend.normal);
        final gradients = doc.strokes.any((s) => s.gradient != null);
        switch (level) {
          case SkillLevel.beginner:
            expect([textures, blends], [false, false]);
          case SkillLevel.intermediate:
            expect([textures, blends, gradients], [false, false, true]);
          case SkillLevel.advanced:
            expect([textures, blends], [true, true]);
            expect(brushes, contains(BrushType.smudge));
        }
      }
    });

    testWidgets('names and the sun\'s greeting follow the language',
        (tester) async {
      final en = (await tester.runAsync(
          () => LevelSamples.load(SkillLevel.beginner, const S('en'))))!;
      expect(en.meta.name, 'A Happy Day');
      final words = en.strokes.map((s) => s.text?.text).whereType<String>();
      expect(words, contains('Hello!'));
      expect(words, isNot(contains('你好呀！')));
      final lake = (await tester.runAsync(
          () => LevelSamples.load(SkillLevel.advanced, const S('zh'))))!;
      expect(lake.meta.name, '湖畔晨光');
    });

    testWidgets('a kid gets their level\'s sample once, and another when '
        'they pick another level', (tester) async {
      final app = await createTestApp(prefs: {
        'flutter.level': 'advanced',
        'flutter.samplesAdded': <String>[],
      });
      await app.session.addSampleOnce();
      await app.session.addSampleOnce();
      var list = await app.store.list();
      expect([for (final m in list) m.name], ['湖畔晨光'], reason: 'once');

      app.settings.level = SkillLevel.intermediate;
      await app.session.addSampleOnce();
      list = await app.store.list();
      expect({for (final m in list) m.name}, {'湖畔晨光', '海边的晚霞'});
      expect(app.settings.sampleAddedFor(SkillLevel.beginner), isFalse);
    });

    testWidgets('picking another level in the app brings its sample',
        (tester) async {
      final app = await createTestApp(prefs: {
        'flutter.level': 'beginner',
        'flutter.samplesAdded': <String>['beginner'],
      });
      await pumpApp(tester, app: app);
      app.settings.level = SkillLevel.advanced;
      for (var i = 0; i < 5; i++) {
        await tester.pumpAndSettle();
      }
      final list = await app.store.list();
      expect([for (final m in list) m.name], contains('湖畔晨光'));
      expect(app.settings.sampleAddedFor(SkillLevel.advanced), isTrue);
    });

    test('kids from before v4 count as having the beginner sample', () async {
      SharedPreferences.setMockInitialValues({'flutter.sampleAdded': true});
      final settings = await AppSettings.load();
      expect(settings.sampleAddedFor(SkillLevel.beginner), isTrue);
      expect(settings.sampleAddedFor(SkillLevel.advanced), isFalse);
    });
  });
}
