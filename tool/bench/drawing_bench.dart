import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:jingyao_paint/drawing/drawing_controller.dart';
import 'package:jingyao_paint/drawing/render/layer_cache.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/settings.dart';

/// Moves one finger along [path] (screen positions), a frame's time per
/// point, and lifts it.
typedef Swipe = Future<void> Function(List<Offset> path);

Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

/// How smooth the drawing screen is with a big painting.
///
/// On a fresh copy of [doc] it draws 8 strokes, erases 4 times, undoes 4
/// times and fills once with the paint bucket, first with every stroke
/// painted directly (as before v4.1), then from the kept picture
/// ([StrokeLayerCache]). Returns frame timings per phase (draw_direct,
/// erase_direct, undo_direct, draw_cached, ...) and how long each fill took
/// (fill_direct, fill_cached).
///
/// Used by integration_test/draw_perf_test.dart (devices) and
/// tool/bench/web_bench.dart (Chrome).
Future<Map<String, Object>> drawingBench({
  required DrawingController drawing,
  required AppSettings settings,
  required PaintingDoc doc,
  required Rect Function() paper,
  required Swipe swipe,
}) async {
  final results = <String, Object>{};
  for (final cached in [false, true]) {
    StrokeLayerCache.enabled = cached;
    final name = cached ? 'cached' : 'direct';
    drawing.load(doc.strokes, paper: doc.paper, paperSize: doc.paperSize);
    await _wait(1500);
    final r = paper();
    // A slow diagonal across the paper, lower for each [t] from 0 to 1.
    List<Offset> path(double t) => [
          for (var i = 0; i <= 30; i++)
            r.topLeft +
                Offset(r.width * (0.2 + 0.02 * i),
                    r.height * (0.15 + 0.6 * t + 0.004 * i)),
        ];
    settings.brush = BrushType.marker;
    results['draw_$name'] = await measureFrames(() async {
      for (var i = 0; i < 8; i++) {
        await swipe(path(i / 8));
        await _wait(300);
      }
    });
    settings.brush = BrushType.eraser;
    results['erase_$name'] = await measureFrames(() async {
      for (var i = 0; i < 4; i++) {
        await swipe(path(i / 4));
        await _wait(300);
      }
    });
    results['undo_$name'] = await measureFrames(() async {
      for (var i = 0; i < 4; i++) {
        drawing.undo();
        await _wait(400);
      }
    });
    // A tap with the paint bucket in the middle of the paper: how long
    // until the fill is there.
    settings.brush = BrushType.bucket;
    final before = drawing.strokes.length;
    final watch = Stopwatch()..start();
    await swipe([r.center]);
    while (drawing.strokes.length == before && watch.elapsed.inSeconds < 20) {
      await _wait(10);
    }
    results['fill_$name'] = {
      'fill_millis': watch.elapsedMilliseconds,
      'filled': drawing.strokes.length > before,
    };
  }
  StrokeLayerCache.enabled = true;
  return results;
}

/// The frames shown while [action] runs: how many, and how long building
/// (UI thread) and rasterizing (GPU thread) took, in milliseconds.
Future<Map<String, Object>> measureFrames(Future<void> Function() action) async {
  final frames = <FrameTiming>[];
  void collect(List<FrameTiming> timings) => frames.addAll(timings);
  SchedulerBinding.instance.addTimingsCallback(collect);
  await action();
  // Timings arrive in batches.
  await _wait(1200);
  SchedulerBinding.instance.removeTimingsCallback(collect);
  const budget = 1000 / 60;
  Map<String, Object> stats(String what, List<double> ms) {
    if (ms.isEmpty) return {};
    ms.sort();
    return {
      'average_frame_${what}_time_millis':
          ms.reduce((a, b) => a + b) / ms.length,
      '90th_percentile_frame_${what}_time_millis':
          ms[((ms.length - 1) * 0.9).round()],
      'worst_frame_${what}_time_millis': ms.last,
      'missed_frame_${what}_budget_count': ms.where((t) => t > budget).length,
    };
  }

  double ms(Duration d) => d.inMicroseconds / 1000;
  return {
    'frame_count': frames.length,
    ...stats('build', [for (final f in frames) ms(f.buildDuration)]),
    ...stats('rasterizer', [for (final f in frames) ms(f.rasterDuration)]),
  };
}
