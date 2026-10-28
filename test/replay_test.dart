import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jingyao_paint/drawing/render/layer_cache.dart';
import 'package:jingyao_paint/drawing/render/render_image.dart';
import 'package:jingyao_paint/drawing/replay/replay_gif.dart';
import 'package:jingyao_paint/drawing/replay/replay_page.dart';
import 'package:jingyao_paint/drawing/replay/replay_timeline.dart';
import 'package:jingyao_paint/drawing/stroke.dart';

import 'layer_cache_test.dart' show maxDiff, mix;
import 'v3_test.dart' show box;
import 'widget_test.dart' show pumpApp, tapMenu;

const _size = Size(60, 40);

/// The replay at [seconds], as RGBA bytes.
Future<Uint8List> frameAt(ReplayTimeline timeline, double seconds) async {
  final recorder = ui.PictureRecorder();
  paintReplayFrame(Canvas(recorder), _size, timeline, seconds, Colors.white,
      const [PaintingLayer.base], LayeredCache(), 1);
  final image = await recorder.endRecording().toImage(60, 40);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  group('Replay timeline', () {
    test('strokes come back in order; freehand ones point by point', () {
      final strokes = mix();
      final timeline = ReplayTimeline(strokes);
      expect(timeline.at(0).done, 0);
      var last = 0;
      for (var t = 0.0; t <= timeline.total; t += 0.05) {
        final now = timeline.at(t);
        expect(now.done, greaterThanOrEqualTo(last));
        last = now.done;
        if (now.drawing case final s?) {
          final whole = strokes[now.done];
          if (whole.shape == null && whole.points.length > 2) {
            expect(s.points.length, lessThanOrEqualTo(whole.points.length));
          } else {
            expect(s, same(whole), reason: 'shapes appear at once');
          }
        }
      }
      expect(timeline.at(timeline.total).done, strokes.length);
      expect(timeline.at(timeline.total).drawing, isNull);
    });

    test('a long painting is sped up to at most 40 seconds', () {
      final many = [for (var i = 0; i < 3000; i++) ...mix()];
      final timeline = ReplayTimeline(many);
      expect(timeline.total, ReplayTimeline.maxSeconds);
      expect(timeline.at(timeline.total).done, many.length);
      expect(ReplayTimeline(const []).total, 0);
    });
  });

  group('Replay frames', () {
    test('the last frame is the finished painting', () async {
      final strokes = mix();
      final timeline = ReplayTimeline(strokes);
      final end = await frameAt(timeline, timeline.total);
      final painting = (await renderRgba(strokes, _size, 1)).rgba;
      expect(maxDiff(end, painting), lessThanOrEqualTo(2));
    });

    test('the eraser cuts in while it is replayed', () async {
      final strokes = mix();
      final eraser =
          strokes.indexWhere((s) => s.brush == BrushType.eraser);
      final timeline = ReplayTimeline(strokes);
      // Halfway through the eraser stroke.
      var t = 0.0;
      while (timeline.at(t).done < eraser) {
        t += 0.01;
      }
      final before = await frameAt(timeline, t - 0.01);
      final during = await frameAt(timeline, t + 0.2);
      expect(maxDiff(before, during), greaterThan(0));
    });

    test('a GIF of the replay: a looping animation, one frame per step',
        () async {
      final gif = await replayGif(mix(), _size, Colors.white,
          maxSide: 60, fps: 4, maxSeconds: 1.5);
      expect(String.fromCharCodes(gif!.sublist(0, 6)), 'GIF89a');
      final decoded = img.decodeGif(gif)!;
      expect(decoded.width, 60);
      expect(decoded.numFrames, 6);
      var cancelled = false;
      expect(
          await replayGif(mix(), _size, Colors.white,
              maxSide: 60, fps: 4, maxSeconds: 1.5, cancelled: () {
            final was = cancelled;
            cancelled = true;
            return was;
          }),
          isNull);
    });
  });

  testWidgets('the ☰ menu plays the painting back; pause and jump',
      (tester) async {
    final app = await pumpApp(tester);
    app.session.drawing
      ..add(box(const Rect.fromLTWH(40, 40, 80, 80), Colors.red))
      ..add(box(const Rect.fromLTWH(140, 40, 80, 80), Colors.blue));
    await tester.pumpAndSettle();
    await tapMenu(tester, '回放作画过程');
    expect(find.byType(ReplayPage), findsOneWidget);
    final state = tester.state<ReplayPageState>(find.byType(ReplayPage));
    // It started by itself and has played to the end by now.
    expect(state.time.value, state.timeline.total);
    expect(state.playing, isFalse);
    // Play again: from the start.
    await tester.tap(find.byTooltip('播放'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(state.playing, isTrue);
    expect(state.time.value, inExclusiveRange(0, state.timeline.total));
    await tester.tap(find.byTooltip('暂停'));
    await tester.pump();
    expect(state.playing, isFalse);
    final paused = state.time.value;
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.time.value, paused);
    await tester.tap(find.byTooltip('播放'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(state.time.value, state.timeline.total, reason: 'played to the end');
    expect(state.playing, isFalse);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ReplayPage), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });
}
