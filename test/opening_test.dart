import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/render/layer_cache.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/gallery/sample_progress_card.dart';

import 'layer_cache_test.dart' show maxDiff, mix;
import 'test_helpers.dart';
import 'v3_test.dart' show box;
import 'v4_test.dart' show line;
import 'widget_test.dart' show pumpApp;

const _size = Size(60, 40);

/// [strokes] on [layers] painted through [cache], called once per frame
/// until [cache] has painted them all (at most [frames] times), as RGBA.
Future<(Uint8List, int)> _paintUntilDone(LayeredCache cache,
    List<Stroke> strokes, List<PaintingLayer> layers, {int frames = 1}) async {
  ui.Image? image;
  var calls = 0;
  bool done() => layers.every((l) {
        final own = [for (final s in strokes) if (s.layerId == l.id) s];
        return own.isEmpty || cache.imageOf(l.id, own, _size) != null;
      });
  do {
    image?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(Offset.zero & _size, Paint()..color = Colors.white);
    cache.paint(canvas, _size, strokes, layers, Colors.white, 1);
    image = await recorder.endRecording().toImage(60, 40);
    calls++;
  } while (!done() && calls < frames);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return (data!.buffer.asUint8List(), calls);
}

/// A painting of [count] strokes in a row, for opening.
List<Stroke> _many(int count) => [
      for (var i = 0; i < count; i++)
        line(Offset(10.0 + i % 20 * 15, 40.0 + i ~/ 20 * 12),
            Offset(30.0 + i % 20 * 15, 46.0 + i ~/ 20 * 12),
            color: Color.fromARGB(255, 40 * (i % 6), 120, 200)),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Opening a big painting', () {
    test('reading it in steps gives the same painting, telling how far it '
        'has got', () async {
      final layers = [
        PaintingLayer.base,
        const PaintingLayer(id: 'top', name: '上', opacity: 0.5),
      ];
      final strokes = [
        for (var i = 0; i < 300; i++)
          for (final s in mix()) i.isEven ? s : s.onLayer('top'),
      ];
      final doc = PaintingDoc(
        meta: PaintingMeta(
          id: 'big',
          createdAt: DateTime(2026, 10, 28),
          updatedAt: DateTime(2026, 10, 28),
          width: 60,
          height: 40,
          strokeCount: strokes.length,
          name: '大画',
        ),
        strokes: strokes,
        paper: const Color(0xFFFFF6E5),
        paperSize: _size,
        layers: layers,
      );
      final text = doc.encode();
      expect(text.length, greaterThan(200000), reason: 'read in pieces');
      final told = <double>[];
      final back = await PaintingDoc.decodeInSteps(text, told.add);
      expect(jsonEncode(back.toJson()), text);
      expect(told.length, greaterThan(3));
      for (var i = 1; i < told.length; i++) {
        expect(told[i], greaterThanOrEqualTo(told[i - 1]));
      }
      expect(told.last, 1);
    });

    test('the paper paints it a slice at a time, the same as all at once',
        () async {
      final layers = [
        PaintingLayer.base,
        const PaintingLayer(id: 'top', name: '上', opacity: 0.6),
      ];
      final strokes = [
        ...mix(),
        for (final s in mix()) s.onLayer('top'),
        box(const Rect.fromLTWH(40, 0, 20, 20), Colors.green).onLayer('top'),
      ];
      final (whole, once) = await _paintUntilDone(LayeredCache(), strokes, layers);
      expect(once, 1);

      final budget = LayeredCache.sliceBudget;
      addTearDown(() => LayeredCache.sliceBudget = budget);
      LayeredCache.sliceBudget = Duration.zero;
      final sliced = LayeredCache(sliced: true)..paintInSlices((_) {});
      final (slices, calls) =
          await _paintUntilDone(sliced, strokes, layers, frames: 100);
      expect(calls, greaterThan(5), reason: 'a stroke or so each frame');
      expect(maxDiff(slices, whole), lessThanOrEqualTo(2));
    });

    test('only a cache that may paint in slices does: the replay paints '
        'every frame whole', () async {
      final budget = LayeredCache.sliceBudget;
      addTearDown(() => LayeredCache.sliceBudget = budget);
      LayeredCache.sliceBudget = Duration.zero;
      final strokes = mix();
      final cache = LayeredCache()..paintInSlices((_) {});
      final (_, calls) = await _paintUntilDone(
          cache, strokes, const [PaintingLayer.base],
          frames: 100);
      expect(calls, 1);
    });

    testWidgets('a big one shows a card with how far it has got, from '
        'reading it to having it all on the paper', (tester) async {
      final stepsFrom = PaintingDoc.stepsFrom, budget = LayeredCache.sliceBudget;
      addTearDown(() {
        PaintingDoc.stepsFrom = stepsFrom;
        LayeredCache.sliceBudget = budget;
      });
      PaintingDoc.stepsFrom = 2000;
      LayeredCache.sliceBudget = Duration.zero;

      final app = await createTestApp();
      app.session.drawing.load(_many(60));
      await app.session.save();
      final id = app.session.id;
      final name = app.session.name;
      await app.session.newPainting();
      await pumpApp(tester, app: app);
      final state = tester.state<CanvasPageState>(find.byType(CanvasPage));

      var opened = false;
      app.session.open(id, name: name).then((ok) => opened = ok);
      final told = <double>[];
      void note() {
        if (app.session.opening.value case final now?) told.add(now.done);
      }

      app.session.opening.addListener(note);
      addTearDown(() => app.session.opening.removeListener(note));
      var cardSeen = false;
      for (var frame = 0; frame < 400; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final now = app.session.opening.value;
        final card = find.byType(OpeningProgressCard);
        if (card.evaluate().isNotEmpty) {
          final bar = tester.widget<LinearProgressIndicator>(find.descendant(
              of: card, matching: find.byType(LinearProgressIndicator)));
          final percent = find.descendant(
              of: card, matching: find.textContaining(RegExp(r'^\d+%$')));
          if (find.text('正在打开「$name」…').evaluate().isNotEmpty &&
              percent.evaluate().isNotEmpty &&
              bar.value! > 0 &&
              bar.value! < 1) {
            cardSeen = true;
          }
        }
        if (opened && now == null) break;
      }
      expect(opened, isTrue);
      expect(cardSeen, isTrue, reason: 'the name and the percentage show');
      expect(told.any((d) => d < 0.4), isTrue, reason: 'reading');
      expect(told.any((d) => d > 0.4 && d < 1), isTrue, reason: 'painting');
      for (var i = 1; i < told.length; i++) {
        expect(told[i], greaterThanOrEqualTo(told[i - 1]));
      }
      await tester.pump();
      expect(find.textContaining('正在打开'), findsNothing);
      expect(
        state.layerCache.imageOf(PaintingLayer.baseId,
            app.session.drawing.strokes, app.session.canvasSize),
        isNotNull,
        reason: 'all of it is on the paper',
      );
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a small one opens at once, with no card', (tester) async {
      final app = await createTestApp();
      app.session.drawing.load(_many(3));
      await app.session.save();
      final id = app.session.id;
      await app.session.newPainting();
      await pumpApp(tester, app: app);
      var opened = false;
      app.session.open(id).then((ok) => opened = ok);
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(app.session.opening.value, isNull);
        expect(find.textContaining('正在打开'), findsNothing);
      }
      expect(opened, isTrue);
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
