import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jingyao_paint/drawing/drawing_controller.dart';
import 'package:jingyao_paint/drawing/render/render_image.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_file.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/share/painting_export.dart';
import 'package:jingyao_paint/share/photo_import.dart';
import 'package:jingyao_paint/share/share_actions.dart';
import 'package:jingyao_paint/skill_level.dart';
import 'package:jingyao_paint/widgets/elastic_switch.dart';
import 'package:jingyao_paint/widgets/menu_button.dart';

import 'test_helpers.dart';
import 'v3_test.dart' show box;
import 'widget_test.dart' show pumpApp, tapMenu;

/// A [w]×[h] picture in one [color], as PNG bytes.
Uint8List pictureBytes(int w, int h, img.Color color) =>
    img.encodePng(img.Image(width: w, height: h)..clear(color));

StrokePhoto redPhoto() => StrokePhoto(
  pictureBytes(4, 2, img.ColorRgb8(255, 0, 0)),
  const Size(40, 20),
);

void main() {
  group('A photo on the paper', () {
    test('is saved with its picture, moves, and is hit inside its box', () {
      final s = Stroke.photo(topLeft: const Offset(10, 10), photo: redPhoto());
      expect(s.bounds, const Rect.fromLTWH(10, 10, 40, 20));
      expect(s.hits(const Offset(45, 25), reach: 0), isTrue);
      expect(s.hits(const Offset(55, 25), reach: 0), isFalse);
      expect(s.touches(const Rect.fromLTWH(0, 0, 12, 12)), isTrue);
      final back = Stroke.fromJson(s.toJson());
      expect(back.photo!.bytes, s.photo!.bytes);
      expect(back.photo!.size, const Size(40, 20));
      expect(back.moved(const Offset(5, 0)).bounds.left, 15);
      expect(
        s.toJson()['brush'],
        'pen',
        reason: 'older versions read it as a (tiny) pen dot',
      );
    });

    test('paints its picture, see-through at its opacity', () async {
      Future<List<int>> at(Stroke s, int x, int y) async {
        final raw = await renderRgba([s], const Size(60, 40), 1);
        final i = (y * raw.width + x) * 4;
        return raw.rgba.sublist(i, i + 3);
      }

      final photo = redPhoto();
      final solid = Stroke.photo(topLeft: const Offset(10, 10), photo: photo);
      expect(await at(solid, 30, 20), [255, 0, 0]);
      expect(await at(solid, 5, 5), [255, 255, 255]);
      final faded = Stroke.photo(
        topLeft: const Offset(10, 10),
        photo: photo,
        opacity: 0.5,
      );
      final pink = await at(faded, 30, 20);
      expect(pink[0], 255);
      expect(pink[1], inInclusiveRange(124, 131));
    });

    test(
      'a big picture is made smaller and fitted; a broken one is refused',
      () async {
        final big = pictureBytes(3000, 1000, img.ColorRgb8(0, 128, 255));
        final photo = await photoFromBytes(big, const Size(500, 500));
        final decoded = img.decodeJpg(photo!.bytes)!;
        expect(decoded.width, maxPhotoSide);
        expect(photo.size.width, 500);
        expect(photo.size.height, closeTo(500 / 3, 0.5));
        expect(
          await photoFromBytes(Uint8List.fromList([1, 2, 3]), Size.zero),
          isNull,
        );
      },
    );

    test('goes under everything, or onto a new locked layer at the bottom', () {
      final d = DrawingController()
        ..add(box(const Rect.fromLTWH(0, 0, 9, 9), Colors.blue));
      final photo = Stroke.photo(topLeft: Offset.zero, photo: redPhoto());
      d.addUnder(photo);
      expect(d.strokes.first, same(photo));
      d.undo();
      d.addLayer();
      final drawingOn = d.activeLayer;
      final onLayer = Stroke.photo(
        topLeft: Offset.zero,
        photo: redPhoto(),
        layer: 'ph',
      );
      d.addUnder(
        onLayer,
        newLayer: const PaintingLayer(id: 'ph', locked: true, opacity: 0.5),
      );
      expect(d.layers.first.id, 'ph');
      expect(d.layers.first.locked, isTrue);
      expect(d.strokes.first, same(onLayer));
      expect(d.activeLayer, drawingOn, reason: 'still drawing where we were');
      expect(
        d.hitStroke(const Offset(20, 10)),
        isNull,
        reason: 'a locked layer is never picked from',
      );
    });
  });

  group('Leaving the photo out of exports', () {
    PaintingDoc traced() => PaintingDoc(
      meta: sampleDoc('t', DateTime(2026, 10, 28)).meta,
      strokes: [
        Stroke.photo(topLeft: const Offset(10, 10), photo: redPhoto()),
        box(const Rect.fromLTWH(60, 60, 20, 20), Colors.blue),
      ],
      paperSize: const Size(100, 100),
    );

    test('pictures leave it out when asked; a .jypaint keeps it', () async {
      img.Pixel at(ExportedFile f, int x, int y) =>
          img.decodePng(f.bytes)!.getPixel(x, y);

      final doc = traced();
      expect(hasPhoto(doc), isTrue);
      expect(hasPhoto(withoutPhotos(doc)), isFalse);
      final whole = await exportPainting(doc, ExportFormat.png);
      final drawn = await exportPainting(doc, ExportFormat.png, photos: false);
      // 2 pixels per point: (30, 20) is inside the photo, (70, 70) the box.
      expect(at(whole, 60, 40).r, 255);
      expect(at(whole, 60, 40).g, lessThan(10));
      expect(at(drawn, 60, 40).g, 255, reason: 'paper, no photo');
      expect(
        at(drawn, 140, 140).b,
        greaterThan(200),
        reason: 'the drawing stays',
      );
      final file = await exportPainting(
        doc,
        ExportFormat.painting,
        photos: false,
      );
      expect(PaintingFile.decode(file.bytes).strokes, hasLength(2));
    });

    testWidgets('the format sheet asks only when there is a photo', (
      tester,
    ) async {
      deliverExport = (file, origin) async {};
      final app = await pumpApp(tester);
      await tapMenu(tester, '下载图片');
      expect(find.text('选择下载格式'), findsOneWidget);
      expect(find.text('照片也放进去'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      app.session.drawing.addUnder(
        Stroke.photo(topLeft: const Offset(10, 10), photo: redPhoto()),
      );
      await tester.pump();
      await tapMenu(tester, '下载图片');
      final toggle = find.byKey(const ValueKey('exportPhotos'));
      expect(find.text('照片也放进去'), findsOneWidget);
      expect(
        tester.widget<ElasticSwitchTile>(toggle).value,
        isTrue,
        reason: 'what is seen, unless turned off',
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<ElasticSwitchTile>(toggle).value, isFalse);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('the ☰ menu offers a photo from the intermediate level', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    Future<bool> offered() async {
      await tester.tap(find.byType(MenuButton));
      await tester.pumpAndSettle();
      final found = find
          .text('导入照片（描着画）', skipOffstage: false)
          .evaluate()
          .isNotEmpty;
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      return found;
    }

    expect(await offered(), isTrue, reason: 'tests run at the advanced level');
    app.settings.level = SkillLevel.beginner;
    await tester.pumpAndSettle();
    expect(await offered(), isFalse);
  });
}
