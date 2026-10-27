

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/app_theme.dart' show kThemeIds;
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/drawing_controller.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_file.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/settings.dart';
import 'package:jingyao_paint/share/painting_export.dart';
import 'package:jingyao_paint/share/share_actions.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'test_helpers.dart';
import 'widget_test.dart'
    show closeTools, drawStroke, openTools, pumpApp, scrollTools, tapMenu;

/// Points every 2px around [r], as a finger going round it.
List<PointVector> loop(Rect r) {
  final corners = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft, r.topLeft];
  return [
    for (var i = 0; i + 1 < corners.length; i++)
      for (var t = 0.0; t < 1; t += 2 / (corners[i + 1] - corners[i]).distance)
        PointVector(Offset.lerp(corners[i], corners[i + 1], t)!.dx,
            Offset.lerp(corners[i], corners[i + 1], t)!.dy, 0.5),
  ];
}

Stroke freeShape(Rect r,
        {Color color = const Color(0xFF3366CC),
        StrokeGradient? gradient,
        double blur = 0,
        StrokeBlend blend = StrokeBlend.normal,
        bool fill = true}) =>
    Stroke(
      brush: BrushType.pen,
      color: color,
      size: 2,
      usesRealPressure: false,
      fill: fill,
      gradient: gradient,
      blur: blur,
      blend: blend,
      isComplete: true,
      points: loop(r),
    );

Stroke box(Rect r, Color color,
        {StrokeGradient? gradient,
        double blur = 0,
        StrokeBlend blend = StrokeBlend.normal}) =>
    Stroke.shape(
      shape: ShapeKind.rectangle,
      from: r.topLeft,
      to: r.bottomRight,
      brush: BrushType.pen,
      color: color,
      size: 1,
      fill: true,
      gradient: gradient,
      blur: blur,
      blend: blend,
      isComplete: true,
    );

/// The color at (x, y) once [strokes] are drawn on white paper.
Future<Color> pixel(List<Stroke> strokes, int x, int y,
    {Size size = const Size(40, 40)}) async {
  final raw = await DrawingController.renderRgba(strokes, size, 1);
  final i = (y * raw.width + x) * 4;
  return Color.fromARGB(
      raw.rgba[i + 3], raw.rgba[i], raw.rgba[i + 1], raw.rgba[i + 2]);
}

int r8(Color c) => (c.r * 255).round();
int g8(Color c) => (c.g * 255).round();
int b8(Color c) => (c.b * 255).round();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Painted looks in the file', () {
    test('gradient, blur, blend and free shapes save and reopen', () {
      const blue = Color(0xFF3366CC);
      final strokes = [
        box(const Rect.fromLTWH(0, 0, 40, 30), blue,
            gradient: GradientStyle.rounded.forColor(blue),
            blur: 3,
            blend: StrokeBlend.multiply),
        freeShape(const Rect.fromLTWH(5, 5, 20, 20),
            gradient: GradientStyle.lighter.forColor(blue),
            blend: StrokeBlend.screen),
        sampleStroke(brush: BrushType.soft).copyWith(),
        Stroke(
          brush: BrushType.soft,
          color: blue,
          size: 10,
          usesRealPressure: false,
          blur: 7,
          blend: StrokeBlend.softLight,
          gradient: const StrokeGradient(
            colors: [Color(0xFFFF0000), Color(0x0000FF00), Color(0xFF0000FF)],
            stops: [0, 0.3, 1],
            radial: true,
            from: Offset(0.25, 0.75),
            to: Offset(1, 0),
          ),
          isComplete: true,
          points: const [PointVector(1, 2, 0.5), PointVector(30, 40, 0.5)],
        ),
      ];
      final doc = PaintingDoc(
        meta: PaintingMeta(
          id: 'v23',
          createdAt: DateTime(2026, 10, 27),
          updatedAt: DateTime(2026, 10, 27),
          width: 100,
          height: 100,
          strokeCount: strokes.length,
        ),
        strokes: strokes,
      );
      final back = PaintingFile.decode(PaintingFile.encode(doc)).strokes;
      for (final (i, s) in strokes.indexed) {
        expect(back[i].gradient, s.gradient, reason: 'gradient $i');
        expect(back[i].blur, s.blur, reason: 'blur $i');
        expect(back[i].blend, s.blend, reason: 'blend $i');
        expect(back[i].fill, s.fill, reason: 'fill $i');
        expect(back[i].shape, s.shape, reason: 'shape $i');
      }
      expect(back[1].fill, isTrue, reason: 'a free shape stays filled');
    });

    test('paintings from before v2.3 open with plain looks', () {
      final json = sampleStroke().toJson();
      expect(json.keys, isNot(containsAll(['gradient', 'blur', 'blend'])));
      final s = Stroke.fromJson(json);
      expect(s.gradient, isNull);
      expect(s.blur, 0);
      expect(s.blend, StrokeBlend.normal);
      expect(s.fill, isFalse);
    });

    test('broken gradients are ignored', () {
      for (final bad in [
        'red',
        {'colors': []},
        {'colors': [0xFF000000]},
      ]) {
        final json = {...sampleStroke().toJson(), 'gradient': bad};
        expect(Stroke.fromJson(json).gradient, isNull, reason: '$bad');
      }
    });
  });

  group('Editing painted strokes', () {
    final gradient = GradientStyle.darker.forColor(const Color(0xFF3366CC));
    final shape = freeShape(const Rect.fromLTWH(10, 10, 20, 20),
        gradient: gradient, blur: 2, blend: StrokeBlend.multiply);

    test('moving, turning and fading keep the look', () {
      for (final s in [
        shape.moved(const Offset(5, 7)),
        shape.transformed(StrokeTransform.around(const Offset(20, 20),
            angle: 0.5, scale: 1.5)),
        shape.copyWith(opacity: 0.4),
      ]) {
        expect(s.fill, isTrue);
        expect(s.gradient, gradient);
        expect(s.blur, 2);
        expect(s.blend, StrokeBlend.multiply);
      }
      expect(shape.moved(const Offset(5, 7)).points.first.x,
          shape.points.first.x + 5);
    });

    test('a new color replaces the gradient', () {
      final recolored = shape.copyWith(color: Colors.green);
      expect(recolored.gradient, isNull);
      expect(recolored.color, Colors.green);
      expect(recolored.blend, StrokeBlend.multiply);
    });

    test('a free shape is caught anywhere inside it', () {
      const center = Offset(20, 20);
      expect(shape.hits(center, reach: 0), isTrue);
      expect(freeShape(const Rect.fromLTWH(10, 10, 20, 20), fill: false)
          .hits(center, reach: 0), isFalse, reason: 'just a line around');
      expect(shape.touches(Rect.fromCenter(center: center, width: 2, height: 2)),
          isTrue);
    });

    test('a blurred stroke covers more paper', () {
      final sharp = freeShape(const Rect.fromLTWH(10, 10, 20, 20));
      final soft = freeShape(const Rect.fromLTWH(10, 10, 20, 20), blur: 6);
      expect(soft.bounds.width, sharp.bounds.width + 36);
    });
  });

  group('Painting', () {
    test('a gradient goes from one color to the other', () async {
      final s = box(const Rect.fromLTWH(0, 0, 40, 40), Colors.black,
          gradient: const StrokeGradient(
              colors: [Color(0xFFFF0000), Color(0xFF0000FF)]));
      final top = await pixel([s], 20, 2);
      final bottom = await pixel([s], 20, 37);
      expect(r8(top), greaterThan(200));
      expect(b8(top), lessThan(60));
      expect(b8(bottom), greaterThan(200));
      expect(r8(bottom), lessThan(60));
    });

    test('a gradient shows even when the stroke color is see-through',
        () async {
      final s = Stroke.shape(
        shape: ShapeKind.rectangle,
        from: Offset.zero,
        to: const Offset(40, 40),
        brush: BrushType.pen,
        color: const Color(0x00000000),
        size: 1,
        fill: true,
        gradient: const StrokeGradient(
            colors: [Color(0xFF000000), Color(0x00000000)]),
        isComplete: true,
      );
      expect(r8(await pixel([s], 20, 3)), lessThan(40));
    });

    test('three or more colors paint without stops', () async {
      final s = box(const Rect.fromLTWH(0, 0, 40, 40), Colors.black,
          gradient: const StrokeGradient(colors: [
        Color(0xFFFF0000), Color(0xFF00FF00), Color(0xFF0000FF),
      ]));
      final middle = await pixel([s], 20, 20);
      expect(g8(middle), greaterThan(200), reason: 'green in the middle');
    });

    test('blur softens the edge', () async {
      const r = Rect.fromLTRB(10, 10, 30, 30);
      final sharp = await pixel([box(r, Colors.black)], 33, 20);
      final soft = await pixel([box(r, Colors.black, blur: 4)], 33, 20);
      expect(r8(sharp), 255, reason: 'paper next to a sharp edge');
      expect(r8(soft), lessThan(240), reason: 'a soft edge spreads out');
    });

    test('shadow darkens what is under it, light lightens it', () async {
      const r = Rect.fromLTRB(0, 0, 40, 40);
      final shadow = await pixel([
        box(r, const Color(0xFFFFFF00)),
        box(r, const Color(0xFF00FFFF), blend: StrokeBlend.multiply),
      ], 20, 20);
      expect([r8(shadow), g8(shadow), b8(shadow)], [0, 255, 0],
          reason: 'yellow times cyan is green');
      final light = await pixel([
        box(r, const Color(0xFFFF0000)),
        box(r, const Color(0xFF0000FF), blend: StrokeBlend.screen),
      ], 20, 20);
      expect([r8(light), g8(light), b8(light)], [255, 0, 255],
          reason: 'red screened with blue is magenta');
    });

    test('a free shape fills the area its line goes around', () async {
      const r = Rect.fromLTRB(8, 8, 32, 32);
      final filled = await pixel([freeShape(r, color: Colors.black)], 20, 20);
      final line =
          await pixel([freeShape(r, color: Colors.black, fill: false)], 20, 20);
      expect(r8(filled), lessThan(30));
      expect(r8(line), 255, reason: 'a plain line leaves the middle empty');
    });

    test('the soft brush has blurred edges', () {
      expect(BrushType.soft.blur, greaterThan(0));
      expect(BrushType.soft.kind, BrushKind.outline);
    });
  });

  group('Tools drawer', () {
    testWidgets('the soft brush draws soft, see-through strokes',
        (tester) async {
      final app = await pumpApp(tester);
      await openTools(tester);
      await tester.tap(find.text('柔边笔'));
      await tester.pumpAndSettle();
      await closeTools(tester);
      await drawStroke(tester);

      final s = app.session.drawing.strokes.single;
      expect(s.brush, BrushType.soft);
      expect(s.blur, closeTo(BrushType.soft.blur * s.width, 0.01));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('free shape fills what is drawn around; freehand stops it',
        (tester) async {
      final app = await pumpApp(tester);
      await openTools(tester);
      final free = find.widgetWithText(ChoiceChip, '自由形状');
      await scrollTools(tester, free);
      await tester.tap(free);
      await tester.pumpAndSettle();
      expect(app.settings.freeShape, isTrue);
      expect(app.settings.shape, isNull);
      await closeTools(tester);

      final g = await tester.startGesture(const Offset(100, 200));
      for (final p in const [
        Offset(200, 200), Offset(200, 300), Offset(100, 300), Offset(100, 205),
      ]) {
        await g.moveTo(p);
        await tester.pump();
      }
      await g.up();
      await tester.pump();
      final s = app.session.drawing.strokes.single;
      expect(s.fill, isTrue);
      expect(s.shape, isNull);

      await openTools(tester);
      final freehand = find.widgetWithText(ChoiceChip, '自由画');
      await scrollTools(tester, freehand);
      await tester.tap(freehand);
      await tester.pumpAndSettle();
      expect(app.settings.freeShape, isFalse);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('gradient and light & shadow apply to new strokes',
        (tester) async {
      final app = await pumpApp(tester);
      await openTools(tester);
      for (final label in ['下暗', '阴影']) {
        final chip = find.widgetWithText(ChoiceChip, label);
        await scrollTools(tester, chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }
      await closeTools(tester);
      await drawStroke(tester);

      final s = app.session.drawing.strokes.single;
      expect(s.gradient, GradientStyle.darker.forColor(app.settings.color));
      expect(s.blend, StrokeBlend.multiply);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('options show only for brushes that use them',
        (tester) async {
      final app = await pumpApp(tester);
      await openTools(tester);

      // Spray dots don't take gradients, but can still shade.
      app.settings.brush = BrushType.spray;
      await tester.pumpAndSettle();
      await scrollTools(tester, find.text('光影'));
      expect(find.text('渐变', skipOffstage: false), findsNothing);

      // The eraser has no colors at all.
      app.settings.brush = BrushType.eraser;
      await tester.pumpAndSettle();
      await scrollTools(tester, find.byIcon(Icons.opacity_rounded));
      expect(find.text('光影', skipOffstage: false), findsNothing);
      expect(find.text('渐变', skipOffstage: false), findsNothing);
    });

    testWidgets('options are in English too', (tester) async {
      await pumpApp(tester,
          app: await createTestApp(prefs: {'flutter.language': 'en'}));
      await tester.tap(find.text('Brushes · Colors'));
      await tester.pumpAndSettle();
      expect(find.text('Soft brush'), findsOneWidget);
      for (final label in ['Free shape', 'Dark bottom', 'Glow', 'Shadow']) {
        await scrollTools(tester, find.widgetWithText(ChoiceChip, label));
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
    });

    for (final id in kThemeIds) {
      testWidgets('theme $id: the new options meet accessibility guidelines',
          (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester,
            app: await createTestApp(prefs: {'flutter.theme': id}),
            screen: const Size(393, 1200));
        await openTools(tester);
        await scrollTools(tester, find.widgetWithText(ChoiceChip, '提亮'));
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

  group('Settings', () {
    test('free shape, gradient and blend are remembered and reset', () async {
      final app = await createTestApp();
      final settings = app.settings
        ..freeShape = true
        ..gradient = GradientStyle.glow
        ..blend = StrokeBlend.screen;
      final again = await AppSettings.load();
      expect(again.freeShape, isTrue);
      expect(again.gradient, GradientStyle.glow);
      expect(again.blend, StrokeBlend.screen);

      settings.shape = ShapeKind.ellipse;
      expect(settings.freeShape, isFalse, reason: 'a shape replaces it');

      await settings.resetAll();
      expect(settings.gradient, GradientStyle.none);
      expect(settings.blend, StrokeBlend.normal);
      expect(settings.freeShape, isFalse);
    });
  });

  test('a stroke being drawn leaves the finished layer alone; the eraser '
      'cuts into it', () {
    final drawing = DrawingController();
    Stroke fresh(BrushType brush) => Stroke(
        brush: brush, color: Colors.black, size: 4, usesRealPressure: false);
    var revision = drawing.finishedRevision.value;
    drawing.begin(fresh(BrushType.pen), const PointVector(1, 1, 0.5));
    drawing.extend(const PointVector(5, 5, 0.5));
    expect(drawing.finishedRevision.value, revision);
    drawing.end();
    expect(drawing.finishedRevision.value, greaterThan(revision));

    revision = drawing.finishedRevision.value;
    drawing.begin(fresh(BrushType.eraser), const PointVector(1, 1, 0.5));
    drawing.extend(const PointVector(5, 5, 0.5));
    expect(drawing.finishedRevision.value, greaterThan(revision + 1));
  });

  group('Paper grips', () {
    testWidgets('the right grip makes the paper wider; drawings keep their '
        'size; one undo puts it back', (tester) async {
      final app = await pumpApp(tester);
      await drawStroke(tester);
      final drawing = app.session.drawing;
      final stroke = drawing.strokes.single;
      final before = app.session.canvasSize;
      expect(drawing.paperSize, isNull, reason: 'fills the screen at first');

      final grip = find.byTooltip('拖动改变画纸宽度');
      await tester.dragFrom(tester.getCenter(grip), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(drawing.paperSize!.width, closeTo(before.width + 60, 1));
      expect(drawing.paperSize!.height, before.height);
      expect(drawing.strokes.single, same(stroke),
          reason: 'what is drawn is not resized');
      expect(app.session.canvasSize, drawing.paperSize);

      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pumpAndSettle();
      expect(drawing.paperSize, isNull, reason: 'the whole drag is one step');
      expect(drawing.strokes, hasLength(1));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the bottom grip makes it shorter, and the paper stays put '
        'on screen when let go', (tester) async {
      final app = await pumpApp(tester);
      final paper = find.byKey(CanvasPageState.paperKey);
      final topLeft = tester.getTopLeft(paper);
      final before = app.session.canvasSize;
      final grip = find.byTooltip('拖动改变画纸高度');
      await tester.dragFrom(tester.getCenter(grip), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(app.session.drawing.paperSize!.height,
          closeTo(before.height - 150, 1));
      expect(tester.getTopLeft(paper).dx, closeTo(topLeft.dx, 1));
      expect(tester.getTopLeft(paper).dy, closeTo(topLeft.dy, 1));
      expect(tester.getSize(paper).height, closeTo(before.height - 150, 1),
          reason: 'shown at real size, not stretched to fit');
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('screen readers can make the paper bigger', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester);
      expect(
          tester.getSemantics(find.byTooltip('拖动改变画纸宽度')),
          isSemantics(label: '拖动改变画纸宽度', hasIncreaseAction: true,
              hasDecreaseAction: true));
      handle.dispose();
    });

    testWidgets('the ⋮ menu brings the default size back', (tester) async {
      final app = await pumpApp(tester);
      app.session.drawing.setPaperSize(const Size(500, 500));
      await tester.pumpAndSettle();
      await tapMenu(tester, '画纸恢复默认大小');
      expect(app.session.drawing.paperSize, isNull);
      app.session.drawing.undo();
      expect(app.session.drawing.paperSize, const Size(500, 500));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a painting with its own size opens at that size',
        (tester) async {
      final app = await createTestApp();
      await app.store.save(
          PaintingDoc(
            meta: PaintingMeta(
              id: 'card',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              width: 300,
              height: 500,
              strokeCount: 1,
            ),
            strokes: [sampleStroke()],
            paperSize: const Size(300, 500),
          ),
          tinyPng);
      await pumpApp(tester, app: app);
      await app.session.open('card');
      await tester.pumpAndSettle();
      final paper = find.byKey(CanvasPageState.paperKey);
      expect(tester.widget<CustomPaint>(paper).size, const Size(300, 500));
      final doc = app.session.currentDoc();
      expect(paintingSize(doc), const Size(300, 500),
          reason: 'pictures are made at exactly the paper size');
    });
  });

  group('⋮ menu', () {
    testWidgets('View has no zoom buttons (pinch, the wheel or Ctrl +/−)',
        (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('拖动画板'), findsOneWidget);
      for (final gone in ['放大画布', '缩小画布', '适应屏幕', '画纸大小']) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
    });

    testWidgets('Download image offers PNG, JPG and PDF', (tester) async {
      final delivered = <ExportedFile>[];
      deliverExport = (file, origin) async => delivered.add(file);
      final app = await pumpApp(tester);
      app.session.name = '小猫';
      await tapMenu(tester, '下载图片');
      expect(find.text('选择下载格式'), findsOneWidget);
      for (final name in ['图片（PNG）', '图片（JPG）', 'PDF 文档']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('画作文件（可继续画）'), findsNothing);

      // In the apps a PDF goes to the share sheet (Save to Files…).
      await tester.tap(find.text('PDF 文档'));
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 500)));
      await tester.pumpAndSettle();
      expect(delivered.single.name, '小猫.pdf');
      expect(delivered.single.mimeType, 'application/pdf');
    });
  });
}
