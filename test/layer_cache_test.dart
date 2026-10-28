import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/render/layer_cache.dart';
import 'package:jingyao_paint/drawing/render/render_image.dart';
import 'package:jingyao_paint/drawing/stroke.dart';

import 'v3_test.dart' show box;
import 'v4_test.dart' show blender, line;
import 'widget_test.dart' show drawStroke, pumpApp;

const _size = Size(60, 40);
const _cream = Color(0xFFFFF6E5);

/// The paper and [strokes] (plus the [eraser] in use) painted through
/// [cache], as RGBA bytes.
Future<Uint8List> viaCache(StrokeLayerCache cache, List<Stroke> strokes,
    {Color paper = Colors.white, Stroke? eraser, double ratio = 1}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(Offset.zero & _size, Paint()..color = paper);
  cache.paint(canvas, _size, strokes, paper, ratio, intoLayer: eraser);
  final image = await recorder.endRecording().toImage(60, 40);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// The same painted stroke by stroke, as the app did before the cache.
Future<Uint8List> direct(List<Stroke> strokes,
        {Color paper = Colors.white}) async =>
    (await renderRgba(strokes, _size, 1, paper: paper)).rgba;

/// The biggest difference in any channel of any pixel.
int maxDiff(Uint8List a, Uint8List b) {
  var most = 0;
  for (var i = 0; i < a.length; i++) {
    final d = (a[i] - b[i]).abs();
    if (d > most) most = d;
  }
  return most;
}

/// A mix of what paintings hold: plain and see-through paint, a shadow
/// (multiply), the eraser and the blender.
List<Stroke> mix() => [
      box(const Rect.fromLTWH(0, 0, 30, 40), const Color(0xFFFF0000)),
      line(const Offset(4, 10), const Offset(56, 10), size: 8),
      box(const Rect.fromLTWH(20, 15, 30, 20), const Color(0xFF3060C0),
          blend: StrokeBlend.multiply),
      line(const Offset(4, 30), const Offset(56, 30),
          brush: BrushType.highlighter, color: const Color(0xFFFFE000)),
      line(const Offset(10, 4), const Offset(10, 36),
          brush: BrushType.eraser, size: 6),
      blender(),
    ];

void main() {
  group('The finished drawing kept as a picture', () {
    test('looks the same as painting every stroke', () async {
      final strokes = mix();
      final cache = StrokeLayerCache();
      expect(maxDiff(await viaCache(cache, strokes), await direct(strokes)),
          lessThanOrEqualTo(2));
    });

    test('adds a new stroke without painting the others again; an undo '
        'and a redo find their pictures kept', () async {
      final strokes = mix();
      final cache = StrokeLayerCache();
      await viaCache(cache, strokes.sublist(0, 4));
      expect(cache.rebuilds, 1);
      final grown = await viaCache(cache, strokes);
      expect(cache.rebuilds, 1, reason: 'only the new strokes were added');
      expect(maxDiff(grown, await direct(strokes)), lessThanOrEqualTo(2));
      final undone = await viaCache(cache, strokes.sublist(0, 4));
      expect(maxDiff(undone, await direct(strokes.sublist(0, 4))),
          lessThanOrEqualTo(2));
      final redone = await viaCache(cache, strokes);
      expect(maxDiff(redone, await direct(strokes)), lessThanOrEqualTo(2));
      expect(cache.rebuilds, 1, reason: 'both pictures were kept');
    });

    test('moving a stroke paints it again; undoing the move does not',
        () async {
      final strokes = mix();
      final cache = StrokeLayerCache();
      await viaCache(cache, strokes);
      final moved = [...strokes]..[1] = strokes[1].moved(const Offset(0, 12));
      final after = await viaCache(cache, moved);
      expect(cache.rebuilds, 2);
      expect(maxDiff(after, await direct(moved)), lessThanOrEqualTo(2));
      await viaCache(cache, [...strokes]);
      expect(cache.rebuilds, 2);
    });

    test('while erasing, the eraser cuts into the picture down to the paper',
        () async {
      final strokes = [box(const Rect.fromLTWH(0, 0, 60, 40), Colors.green)];
      final eraser = line(const Offset(4, 20), const Offset(56, 20),
          brush: BrushType.eraser, size: 10, color: Colors.black);
      final cache = StrokeLayerCache();
      await viaCache(cache, strokes, paper: _cream);
      final erased =
          await viaCache(cache, strokes, paper: _cream, eraser: eraser);
      expect(cache.rebuilds, 1, reason: 'the picture itself is unchanged');
      expect(maxDiff(erased, await direct([...strokes, eraser], paper: _cream)),
          lessThanOrEqualTo(2));
      final i = (20 * 60 + 30) * 4;
      expect(erased.sublist(i, i + 3), [0xFF, 0xF6, 0xE5],
          reason: 'the paper shows where it was erased');
    });

    test('a new paper color repaints it only if a blender mixed the paper '
        'in', () async {
      final plain = mix().where((s) => s.brush != BrushType.smudge).toList();
      final cache = StrokeLayerCache();
      await viaCache(cache, plain);
      await viaCache(cache, plain, paper: _cream);
      expect(cache.rebuilds, 1);
      final blended = mix();
      final other = StrokeLayerCache();
      await viaCache(other, blended);
      final cream = await viaCache(other, blended, paper: _cream);
      expect(other.rebuilds, 2);
      expect(maxDiff(cream, await direct(blended, paper: _cream)),
          lessThanOrEqualTo(2));
    });

    test('a paper too big for one picture is painted directly', () async {
      final strokes = mix();
      final cache = StrokeLayerCache();
      final huge = await viaCache(cache, strokes, ratio: 1000);
      expect(cache.imageOf(strokes, _size), isNull);
      expect(cache.rebuilds, 0);
      expect(maxDiff(huge, await direct(strokes)), 0);
    });

    test('its resolution follows the zoom in whole steps', () {
      expect(cacheRatioFor(2, 1, 1), 2);
      expect(cacheRatioFor(2, 1, 0.6), 2, reason: 'never less than fit');
      expect(cacheRatioFor(2, 0.5, 1.5), 2);
      expect(cacheRatioFor(2, 1, 2), 4);
      expect(cacheRatioFor(2, 1, 2.01), 8);
      expect(cacheRatioFor(3, 1, 8), 24);
    });

    testWidgets('new strokes on the canvas never repaint the whole drawing',
        (tester) async {
      final app = await pumpApp(tester);
      final state = tester.state<CanvasPageState>(find.byType(CanvasPage));
      await drawStroke(tester);
      await tester.pumpAndSettle();
      final before = state.layerCache.rebuilds;
      for (var i = 0; i < 3; i++) {
        await drawStroke(tester);
      }
      await tester.pumpAndSettle();
      expect(app.session.drawing.strokes, hasLength(4));
      expect(state.layerCache.rebuilds, before);
      app.session.drawing.undo();
      await tester.pumpAndSettle();
      expect(state.layerCache.rebuilds, before, reason: 'kept for undo');
      final first = app.session.drawing.strokes.first;
      app.session.drawing.replace(first, first.moved(const Offset(10, 10)));
      await tester.pumpAndSettle();
      expect(state.layerCache.rebuilds, before + 1);
      // Let the autosave run.
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
