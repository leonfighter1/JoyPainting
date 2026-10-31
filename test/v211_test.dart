import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/drawing_controller.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_archive.dart';
import 'package:jingyao_paint/gallery/painting_file.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/share/import_actions.dart';
import 'package:jingyao_paint/share/painting_export.dart';
import 'package:jingyao_paint/share/share_actions.dart';
import 'package:jingyao_paint/l10n.dart';

import 'test_helpers.dart';
import 'widget_test.dart'
    show drawStroke, inGallery, openTab, openTools, pumpApp, tapMenu, zoomBy;

PaintingDoc named(String id, String name, DateTime created) {
  final d = sampleDoc(id, created);
  return PaintingDoc(
      meta: d.meta.copyWith(name: name), strokes: d.strokes, paper: d.paper);
}

void main() {
  group('Painting archives', () {
    test('several paintings go into one zip and come back', () {
      final docs = [
        named('a', '小猫', DateTime(2026, 1, 1)),
        named('b', '小猫', DateTime(2026, 2, 1)),
        named('c', 'My dog: Rex', DateTime(2026, 3, 1)),
      ];
      final zip = PaintingArchive.encode(docs);
      expect(PaintingArchive.isZip(zip), isTrue);
      final back = PaintingArchive.decode(zip);
      expect([for (final d in back) d.meta.name], ['小猫', '小猫', 'My dog: Rex']);
      expect(back.first.strokes.length, docs.first.strokes.length);
    });

    test('things in a zip that are not paintings are skipped', () {
      final zip = PaintingArchive.encode([named('a', 'ok', DateTime(2026))]);
      // A cut-off zip, as a broken download would be.
      final bad = Uint8List.fromList([0x50, 0x4B, 3, 4, 1, 2, 3]);
      expect(PaintingArchive.decode(bad), isEmpty,
          reason: 'nothing usable; import then says it is not a painting');
      expect(PaintingArchive.decode(zip), hasLength(1));
      expect(PaintingArchive.isZip(PaintingFile.encode(named('x', 'x', DateTime(2026)))),
          isFalse);
    });

    test('importing a zip adds every painting without opening one', () async {
      final app = await createTestApp();
      await app.session.restoreLast();
      final openBefore = app.session.id;
      final zip = PaintingArchive.encode([
        named('a', '小猫', DateTime(2025, 1, 1)),
        named('b', '', DateTime(2025, 2, 1)),
      ]);
      expect(await app.session.importArchive(zip), 2);
      final names = [for (final m in await app.store.list()) m.name];
      expect(names, contains('小猫'));
      expect(names.where((n) => n.startsWith('我的画作 ')), hasLength(1),
          reason: 'the unnamed one gets the next free number');
      expect(app.session.id, openBefore, reason: 'stays on the open painting');
      expect(await app.session.importArchive(Uint8List.fromList([1, 2, 3])), 0);
    });

    testWidgets('import tells how many paintings a zip added', (tester) async {
      final app = await pumpApp(tester);
      final zip = PaintingArchive.encode([
        named('a', 'one', DateTime(2025)),
        named('b', 'two', DateTime(2025)),
        named('c', 'three', DateTime(2025)),
      ]);
      final context = tester.element(find.byType(CanvasPage));
      await importBytes(ScaffoldMessenger.of(context), const S('zh'),
          app.session, zip, () {});
      await tester.pump();
      expect(find.text('已导入 3 幅画作，在“我的画作”里'), findsOneWidget);
    });
  });

  group('Export from My Paintings', () {
    late List<ExportedFile> delivered;
    setUp(() {
      delivered = [];
      deliverExport = (file, origin) async => delivered.add(file);
    });

    Future<TestApp> galleryWith(WidgetTester tester) async {
      final app = await createTestApp();
      await app.store.save(named('a', '小猫', DateTime(2025, 6, 1)), tinyPng);
      await app.store.save(named('b', '小狗', DateTime(2026, 2, 1)), tinyPng);
      await app.store.save(named('c', '小鸟', DateTime(2026, 3, 1)), tinyPng);
      await pumpApp(tester, app: app);
      await openTab(tester, 1);
      return app;
    }

    testWidgets('import and export are labelled buttons', (tester) async {
      await galleryWith(tester);
      expect(find.widgetWithText(OutlinedButton, '导入'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '导出'), findsOneWidget);
    });

    testWidgets('several checked paintings export as one zip', (tester) async {
      await galleryWith(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, '导出'));
      await tester.pumpAndSettle();
      expect(find.text('已选 0 幅'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(inGallery(find.text('小猫')));
      await tester.tap(inGallery(find.text('小鸟')));
      // The count rolls to its new number.
      await tester.pumpAndSettle();
      expect(find.text('已选 2 幅'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '导出 2 幅'));
      await tester.pumpAndSettle();

      final file = delivered.single;
      expect(file.name, endsWith('_2幅.zip'));
      expect(file.mimeType, 'application/zip');
      expect([for (final d in PaintingArchive.decode(file.bytes)) d.meta.name],
          containsAll(['小猫', '小鸟']));
      expect(find.text('已导出 2 幅画作'), findsOneWidget);
      expect(find.text('已选 2 幅'), findsNothing, reason: 'choosing ends');
    });

    testWidgets('one checked painting exports as its own .jypaint file',
        (tester) async {
      await galleryWith(tester);
      // A long press starts choosing with that painting checked.
      await tester.longPress(inGallery(find.text('小狗')));
      await tester.pumpAndSettle();
      expect(find.text('已选 1 幅'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '导出 1 幅'));
      await tester.pumpAndSettle();
      expect(delivered.single.name, '小狗.jypaint');
      expect(PaintingFile.decode(delivered.single.bytes).meta.name, '小狗');
    });

    testWidgets('select all follows the year filter; Back stops choosing',
        (tester) async {
      await galleryWith(tester);
      await tester.tap(inGallery(find.text('2026年 (2)')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '导出'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全选'));
      await tester.pumpAndSettle();
      expect(find.text('已选 2 幅'), findsOneWidget, reason: 'only 2026');
      expect(find.text('全不选'), findsOneWidget);
      await tester.tap(find.text('全不选'));
      await tester.pumpAndSettle();
      expect(find.text('已选 0 幅'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, '导出'), findsOneWidget,
          reason: 'back to the normal gallery');
    });
  });

  group('Paper size', () {
    test('a paper size can be undone and is saved with the painting',
        () async {
      final app = await createTestApp();
      final drawing = app.session.drawing;
      drawing.setPaperSize(const Size(900, 1400));
      expect(drawing.paperSize, const Size(900, 1400));
      drawing.undo();
      expect(drawing.paperSize, isNull, reason: 'back to filling the screen');
      drawing.redo();
      drawing.add(sampleStroke());
      expect(await app.session.save(), isTrue);
      final saved = await app.store.load(app.session.id);
      expect(saved!.paperSize, const Size(900, 1400));
      expect(saved.meta.width, 900);
      expect(PaintingDoc.decode(saved.encode()).paperSize,
          const Size(900, 1400));
    });

    test('sizes are whole pixels, 100 to 8000', () {
      final drawing = DrawingController()
        ..setPaperSize(const Size(20.4, 9000));
      expect(drawing.paperSize, const Size(100, 8000));
      drawing.setPaperSize(const Size(640.6, 480.2));
      expect(drawing.paperSize, const Size(641, 480));
    });

    test('a 2× to 4× paper from v2.1 keeps the size it was saved at', () {
      final old = sampleDoc('p', DateTime(2026)).toJson()
        ..['paperScale'] = 4
        ..['width'] = 1600
        ..['height'] = 2400;
      expect(PaintingDoc.fromJson(old).paperSize, const Size(1600, 2400));
      final plain = sampleDoc('p', DateTime(2026)).toJson();
      expect(PaintingDoc.fromJson(plain).paperSize, isNull,
          reason: 'a 1× paper still fills the screen');
    });

    test('exports of very big papers stay within 4096 pixels', () {
      expect(exportRatioFor(const Size(800, 1200)), 2);
      expect(exportRatioFor(const Size(4000, 2600)) * 4000,
          closeTo(maxExportSide, 0.001));
    });
  });

  group('Pinned palette', () {
    testWidgets('pinned, it stays beside the paper while drawing',
        (tester) async {
      final app = await pumpApp(tester, screen: const Size(1280, 800));
      await openTools(tester);
      await tester.tap(find.byTooltip('固定在屏幕上，边画边选'));
      await tester.pumpAndSettle();
      expect(app.settings.paletteLocked, isTrue);
      expect(find.byKey(CanvasPageState.dockedPaletteKey), findsOneWidget);
      expect(find.byKey(CanvasPageState.toolsButtonKey), findsNothing);
      expect(find.byTooltip('收起画笔和颜色'), findsNothing);

      // Pick a color and draw: the palette stays.
      await tester.tap(find.bySemanticsLabel('颜色 #3DA9FC'));
      await tester.pump();
      final paper = tester.getRect(find.byKey(CanvasPageState.paperKey));
      await tester.dragFrom(paper.center, const Offset(60, 40));
      await tester.pump();
      expect(app.session.drawing.strokes.single.color, const Color(0xFF3DA9FC));
      expect(find.byKey(CanvasPageState.dockedPaletteKey), findsOneWidget);

      await tester.tap(find.byTooltip('取消固定'));
      await tester.pumpAndSettle();
      expect(app.settings.paletteLocked, isFalse);
      expect(find.byKey(CanvasPageState.toolsButtonKey), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('on an upright phone it is a slim strip below the paper',
        (tester) async {
      final app = await createTestApp(prefs: {'flutter.paletteLocked': true});
      await pumpApp(tester, app: app);
      final strip = tester.getRect(find.byKey(CanvasPageState.dockedPaletteKey));
      final paper = tester.getRect(find.byKey(CanvasPageState.paperKey));
      expect(strip.top, greaterThanOrEqualTo(paper.bottom - 1));
      expect(strip.height, lessThanOrEqualTo(110), reason: 'most of it is paper');
      expect(paper.height, greaterThan(500));

      // Brushes and colors right in the strip.
      await tester.tap(find.bySemanticsLabel('马克笔'));
      await tester.pump();
      expect(app.settings.brush, BrushType.marker);
      await tester.tap(find.bySemanticsLabel('颜色 #FF5A5F').first);
      await tester.pump();
      expect(app.settings.color, const Color(0xFFFF5A5F));

      // "More" slides in the full drawer, which closes again.
      await tester.tap(find.byTooltip('更多：大小、形状、透明度'));
      await tester.pumpAndSettle();
      expect(find.text('画笔与颜色'), findsOneWidget);
      await tester.tap(find.byTooltip('收起画笔和颜色'));
      await tester.pumpAndSettle();
      expect(find.text('画笔与颜色'), findsNothing);
      expect(find.byKey(CanvasPageState.dockedPaletteKey), findsOneWidget);
    });
  });
  group('Move the paper', () {
    Matrix4 viewOf(WidgetTester tester) =>
        tester.widget<Transform>(find.byKey(CanvasPageState.zoomKey)).transform;

    testWidgets('with ✋ on, one finger moves the paper instead of drawing',
        (tester) async {
      final app = await pumpApp(tester);
      await tester.tap(find.byTooltip('拖动画板'));
      await tester.pump();
      await tester.dragFrom(const Offset(150, 300), const Offset(60, 40));
      await tester.pumpAndSettle();
      expect(app.session.drawing.strokes, isEmpty, reason: 'nothing drawn');
      final moved = viewOf(tester).getTranslation();
      expect(moved.x, closeTo(60, 1));
      expect(moved.y, closeTo(40, 1));
      expect(find.textContaining('适应屏幕'), findsOneWidget,
          reason: 'the chip brings it back');

      await tester.tap(find.byTooltip('拖动画板'));
      await tester.pump();
      await drawStroke(tester);
      expect(app.session.drawing.strokes, hasLength(1), reason: 'draws again');
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('holding Space moves the paper (computers, browsers)',
        (tester) async {
      final app = await pumpApp(tester, screen: const Size(1280, 800));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.dragFrom(const Offset(500, 400), const Offset(-80, 30));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(app.session.drawing.strokes, isEmpty);
      expect(viewOf(tester).getTranslation().x, closeTo(-80, 1));
    });

    testWidgets('dragging outside the paper moves it', (tester) async {
      final app = await pumpApp(tester);
      await zoomBy(tester, 0.8); // 80%: room around the paper
      final paper = tester.getRect(find.byKey(CanvasPageState.paperKey));
      final before = viewOf(tester).getTranslation();
      // Just left of the paper, inside the page.
      await tester.dragFrom(Offset(paper.left - 12, paper.center.dy),
          const Offset(50, 20));
      await tester.pumpAndSettle();
      final after = viewOf(tester).getTranslation();
      expect(after.x - before.x, closeTo(50, 1));
      expect(after.y - before.y, closeTo(20, 1));
      expect(app.session.drawing.strokes, isEmpty, reason: 'nothing drawn');
    });

    testWidgets('the ⋮ menu has the same switch', (tester) async {
      await pumpApp(tester);
      await tapMenu(tester, '拖动画板');
      final state = tester.state<CanvasPageState>(find.byType(CanvasPage));
      expect(state.panMode.value, isTrue);
    });
  });
}
