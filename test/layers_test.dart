import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas/layer_panel.dart';
import 'package:jingyao_paint/drawing/drawing_controller.dart';
import 'package:jingyao_paint/drawing/render/layer_cache.dart';
import 'package:jingyao_paint/drawing/render/render_image.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/skill_level.dart';

import 'layer_cache_test.dart' show maxDiff;
import 'test_helpers.dart';
import 'v3_test.dart' show box;
import 'v4_test.dart' show line;
import 'widget_test.dart' show drawStroke, openTools, pumpApp;

const _size = Size(60, 40);

Stroke red({String? layer}) =>
    box(const Rect.fromLTWH(0, 0, 60, 40), const Color(0xFFFF0000))
        .onLayer(layer ?? PaintingLayer.baseId);

Stroke eraserAcross({String? layer}) => line(
        const Offset(0, 20), const Offset(60, 20),
        brush: BrushType.eraser, size: 10, color: Colors.black)
    .onLayer(layer ?? PaintingLayer.baseId);

/// The RGB at (x, y) of [strokes] on [layers], over white paper.
Future<List<int>> rgbAt(
    List<Stroke> strokes, List<PaintingLayer> layers, int x, int y) async {
  final raw = await renderRgba(strokes, _size, 1, layers: layers);
  final i = (y * raw.width + x) * 4;
  return raw.rgba.sublist(i, i + 3);
}

void main() {
  group('Layers in the drawing', () {
    test('a new layer goes above the active one; strokes stay grouped', () {
      final d = DrawingController()..add(red());
      expect(d.layers, [PaintingLayer.base]);
      expect(d.addLayer(), isTrue);
      final top = d.activeLayer;
      expect(d.layers.map((l) => l.id), [PaintingLayer.baseId, top]);
      d.add(box(const Rect.fromLTWH(0, 0, 10, 10), Colors.blue).onLayer(top));
      // Back to the base layer: a new stroke goes under the top layer's.
      d.selectLayer(PaintingLayer.baseId);
      final under = box(const Rect.fromLTWH(5, 5, 5, 5), Colors.green);
      d.add(under);
      expect(d.strokes.map((s) => s.layerId),
          [PaintingLayer.baseId, PaintingLayer.baseId, top]);
      d.undo();
      d.undo();
      d.undo();
      expect(d.layers, [PaintingLayer.base], reason: 'adding a layer undoes');
    });

    test('moving, merging and deleting layers; the last one stays', () {
      final d = DrawingController()..add(red());
      d.addLayer();
      final top = d.activeLayer;
      d.add(eraserAcross(layer: top));
      d.moveLayer(top, 0);
      expect(d.strokes.first.layerId, top, reason: 'strokes follow the order');
      d.undo();
      expect(d.strokes.last.layerId, top);
      d.mergeDown(top);
      expect(d.layers, [PaintingLayer.base]);
      expect(d.strokes.every((s) => s.layerId == PaintingLayer.baseId), isTrue);
      d.undo();
      d.deleteLayer(top);
      expect(d.layers, [PaintingLayer.base]);
      expect(d.strokes, hasLength(1));
      d.deleteLayer(PaintingLayer.baseId);
      expect(d.layers, hasLength(1), reason: 'the last layer stays');
    });

    test('only the active, shown and unlocked layer can be picked from', () {
      final d = DrawingController()..add(red());
      d.addLayer();
      expect(d.hitStroke(const Offset(30, 20)), isNull,
          reason: 'the red box is on another layer');
      d.selectLayer(PaintingLayer.baseId);
      expect(d.hitStroke(const Offset(30, 20)), isNotNull);
      d.updateLayer(d.active.copyWith(locked: true));
      expect(d.canDrawOnActive, isFalse);
      expect(d.hitStroke(const Offset(30, 20)), isNull);
      d.updateLayer(d.active.copyWith(locked: false, visible: false));
      expect(d.canDrawOnActive, isFalse);
    });

    test('strokes on a layer that is not there go on the base layer', () {
      final d = DrawingController()..load([red(layer: 'gone')]);
      expect(d.strokes.single.layerId, PaintingLayer.baseId);
    });
  });

  group('Saving layers', () {
    test('a painting keeps its layers and each stroke its layer', () {
      final layers = [
        PaintingLayer.base,
        const PaintingLayer(id: 'L2', name: '天空', opacity: 0.5, locked: true),
        const PaintingLayer(id: 'L3', visible: false),
      ];
      final doc = PaintingDoc(
        meta: sampleDoc('p', DateTime(2026)).meta,
        strokes: [red(), red(layer: 'L2')],
        layers: layers,
      );
      final back = PaintingDoc.decode(doc.encode());
      expect(back.layers, layers);
      expect(back.strokes.map((s) => s.layer), [null, 'L2']);
      final plain = PaintingDoc(meta: doc.meta, strokes: [red()]);
      expect(plain.toJson().containsKey('layers'), isFalse,
          reason: 'a one-layer painting saves as before');
      expect(red().toJson().containsKey('layer'), isFalse);
    });
  });

  group('Painting layers', () {
    final layers = [PaintingLayer.base, const PaintingLayer(id: 'L2')];

    test('the eraser cuts only into its own layer', () async {
      final strokes = [red(), eraserAcross(layer: 'L2')];
      expect(await rgbAt(strokes, layers, 30, 20), [255, 0, 0]);
      expect(await rgbAt([red(), eraserAcross()], [PaintingLayer.base], 30, 20),
          [255, 255, 255],
          reason: 'on the same layer it does');
    });

    test('a hidden layer is not painted; a half see-through one is faded',
        () async {
      final strokes = [red(layer: 'L2')];
      expect(
          await rgbAt(strokes,
              [PaintingLayer.base, layers[1].copyWith(visible: false)], 30, 20),
          [255, 255, 255]);
      final faded = await rgbAt(
          strokes, [PaintingLayer.base, layers[1].copyWith(opacity: 0.5)], 30, 20);
      expect(faded[0], 255);
      expect(faded[1], inInclusiveRange(125, 130));
    });

    test('kept pictures, one per layer, look the same and are kept apart',
        () async {
      final see = [
        PaintingLayer.base,
        const PaintingLayer(id: 'L2', opacity: 0.6),
      ];
      final strokes = [
        red(),
        box(const Rect.fromLTWH(10, 10, 30, 20), Colors.blue).onLayer('L2'),
        eraserAcross(layer: 'L2'),
      ];
      final cache = LayeredCache();
      Future<Uint8List> viaCache(List<Stroke> s) async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)
          ..drawRect(Offset.zero & _size, Paint()..color = Colors.white);
        cache.paint(canvas, _size, s, see, Colors.white, 1);
        final image = await recorder.endRecording().toImage(60, 40);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        return data!.buffer.asUint8List();
      }

      final cached = await viaCache(strokes);
      final direct = (await renderRgba(strokes, _size, 1, layers: see)).rgba;
      expect(maxDiff(cached, direct), lessThanOrEqualTo(2));
      final before = cache.rebuilds;
      await viaCache([
        ...strokes,
        box(const Rect.fromLTWH(0, 0, 5, 5), Colors.green).onLayer('L2'),
      ]);
      expect(cache.rebuilds, before, reason: 'added onto its layer only');
    });
  });

  testWidgets('advanced: the layers row opens the layers; a new layer is '
      'drawn on; a hidden one says why it can\'t be', (tester) async {
    final app = await pumpApp(tester);
    await openTools(tester);
    expect(find.byType(LayersRow), findsOneWidget);
    await tester.tap(find.byType(LayersRow));
    await tester.pumpAndSettle();
    expect(find.byType(LayerSheet), findsOneWidget);
    await tester.tap(find.text('新建图层'));
    await tester.pumpAndSettle();
    final drawing = app.session.drawing;
    expect(drawing.layers, hasLength(2));
    final top = drawing.activeLayer;
    await tester.tap(find.byTooltip('隐藏图层').first);
    await tester.pumpAndSettle();
    expect(drawing.active.visible, isFalse);
    Navigator.of(tester.element(find.byType(LayerSheet))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('收起画笔和颜色'));
    await tester.pumpAndSettle();
    await drawStroke(tester);
    expect(drawing.strokes, isEmpty);
    expect(find.text('这个图层隐藏了，先让它显示出来再画。'), findsOneWidget);
    drawing.updateLayer(drawing.active.copyWith(visible: true));
    await tester.pumpAndSettle();
    await drawStroke(tester);
    expect(drawing.strokes.single.layerId, top);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('below advanced there is no layers row', (tester) async {
    final app = await pumpApp(tester);
    app.settings.level = SkillLevel.intermediate;
    await tester.pumpAndSettle();
    await openTools(tester);
    expect(find.byType(LayersRow), findsNothing);
  });
}
