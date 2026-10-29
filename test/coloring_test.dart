import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/drawing_controller.dart';
import 'package:jingyao_paint/drawing/render/flood_fill.dart';
import 'package:jingyao_paint/drawing/render/pixel_sampler.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/coloring_pages.dart';
import 'package:jingyao_paint/l10n.dart';
import 'package:jingyao_paint/skill_level.dart';

import 'widget_test.dart' show openTab, pumpApp;

/// A spot inside a closed area of each page.
const _inside = {
  ColoringPage.cat: Offset(400, 300),
  ColoringPage.house: Offset(400, 760),
  ColoringPage.flower: Offset(400, 270),
  ColoringPage.fish: Offset(300, 520),
  ColoringPage.rocket: Offset(400, 550),
  ColoringPage.butterfly: Offset(610, 310),
  ColoringPage.car: Offset(240, 700),
  ColoringPage.tree: Offset(300, 330),
  ColoringPage.lighthouse: Offset(520, 520),
  ColoringPage.castle: Offset(400, 520),
  ColoringPage.underwater: Offset(440, 430),
  ColoringPage.balloons: Offset(305, 340),
  ColoringPage.owl: Offset(400, 340),
  ColoringPage.panda: Offset(400, 262),
  ColoringPage.mandala: Offset(400, 500),
  ColoringPage.koi: Offset(680, 360),
  ColoringPage.pavilion: Offset(660, 130),
  ColoringPage.peacock: Offset(290, 440),
  ColoringPage.teaset: Offset(690, 530),
  ColoringPage.street: Offset(400, 60),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every page: lines on a locked top layer, coloring goes below', () async {
    for (final page in ColoringPage.values) {
      final doc = await page.load(const S('zh'));
      expect(doc.meta.name, startsWith('涂色：'));
      expect(doc.layers.last, ColoringPage.linesLayer, reason: page.name);
      expect(doc.strokes, isNotEmpty);
      expect(doc.strokes.every((s) => s.layerId == 'lines'), isTrue);
      final d = DrawingController()
        ..load(doc.strokes, paperSize: doc.paperSize, layers: doc.layers);
      expect(d.activeLayer, PaintingLayer.baseId, reason: 'not the lines');
      expect(d.hitStroke(doc.strokes.first.points.first), isNull,
          reason: 'the lines are never picked up');
    }
  });

  test('every page has closed areas the paint bucket fills without leaking',
      () async {
    for (final page in ColoringPage.values) {
      final doc = await page.load(const S('zh'));
      final pixels = await paperPixels(
          size: doc.paperSize!,
          paper: Colors.white,
          strokes: doc.strokes,
          layers: doc.layers,
          maxSide: 1000);
      final at = _inside[page]!;
      final loops = fillOutlines(FillRequest(
        rgba: pixels.rgba,
        width: pixels.width,
        height: pixels.height,
        x: (at.dx * pixels.ratio).floor(),
        y: (at.dy * pixels.ratio).floor(),
        gap: 2,
      ));
      expect(loops, isNotEmpty, reason: page.name);
      final box = loops
          .expand((l) => l)
          .fold<Rect?>(null,
              (r, p) => r == null ? Rect.fromLTWH(p.dx, p.dy, 0, 0) : r.expandToInclude(Rect.fromLTWH(p.dx, p.dy, 0, 0)))!;
      expect(box.width, lessThan(pixels.width * 0.9),
          reason: '${page.name}: the fill stayed inside its lines');
    }
  });

  test('each level has its own pages, the higher ones more detailed', () async {
    expect(ColoringPage.of(SkillLevel.beginner), hasLength(8));
    expect(ColoringPage.of(SkillLevel.intermediate), hasLength(6));
    expect(ColoringPage.of(SkillLevel.advanced), hasLength(6));
    Future<double> lines(SkillLevel level) async {
      var points = 0;
      for (final page in ColoringPage.of(level)) {
        final doc = await page.load(const S('zh'));
        points += doc.strokes.fold(0, (n, s) => n + s.points.length);
      }
      return points / ColoringPage.of(level).length;
    }

    final beginner = await lines(SkillLevel.beginner);
    final intermediate = await lines(SkillLevel.intermediate);
    final advanced = await lines(SkillLevel.advanced);
    expect(intermediate, greaterThan(beginner * 1.5));
    expect(advanced, greaterThan(intermediate * 1.3));
    for (final page in ColoringPage.values) {
      expect(const S('zh').coloringName(page), isNot(page.name));
      expect(const S('en').coloringName(page), isNot(page.name));
    }
  });

  testWidgets('My Paintings → 涂色本: the kid\'s level first, any level '
      'can be picked, a page opens as a new painting', (tester) async {
    final app = await pumpApp(tester);
    await openTab(tester, 1);
    await tester.tap(find.text('涂色本'));
    await tester.pumpAndSettle();
    expect(find.text('曼陀罗花纹'), findsOneWidget, reason: 'advanced first');
    expect(find.text('小猫'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, '中级'));
    await tester.pumpAndSettle();
    expect(find.text('海边灯塔'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '初级'));
    await tester.pumpAndSettle();
    for (final name in ['小猫', '小房子']) {
      expect(find.text(name), findsOneWidget);
    }
    await tester.tap(find.text('小猫'));
    await tester.pumpAndSettle();
    expect(app.session.name, '涂色：小猫');
    expect(app.session.drawing.layers, hasLength(2));
    expect(app.session.drawing.activeLayer, PaintingLayer.baseId);
    await tester.pump(const Duration(seconds: 1));
  });
}
