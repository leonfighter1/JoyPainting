import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../render/layer_cache.dart';
import '../render/paint_strokes.dart';
import '../stroke.dart';

/// When each stroke of a painting appears in its replay.
///
/// A freehand stroke takes longer the more points it has (it is drawn
/// point by point); a shape, text or a filled area appears at once. Long
/// paintings are sped up so a replay never takes more than [maxSeconds].
class ReplayTimeline {
  ReplayTimeline(this.strokes) {
    var t = 0.0;
    for (final s in strokes) {
      _starts.add(t);
      final length = _drawsAlong(s)
          ? math.min(1.5, 0.15 + s.points.length * 0.012)
          : 0.35;
      _lengths.add(length);
      t += length + pause;
    }
    _natural = t;
  }

  final List<Stroke> strokes;
  final _starts = <double>[];
  final _lengths = <double>[];
  late final double _natural;

  /// The longest a replay takes, in seconds.
  static const maxSeconds = 40.0;

  /// The pause after each stroke, before speeding up.
  static const pause = 0.05;

  /// How long the replay takes, in seconds.
  double get total => math.min(_natural, maxSeconds);

  double get _speed => _natural <= maxSeconds ? 1 : _natural / maxSeconds;

  /// The painting [seconds] into the replay: how many strokes are finished,
  /// and the one being drawn (partly), if any.
  ({int done, Stroke? drawing}) at(double seconds) {
    final t = seconds.clamp(0, total) * _speed;
    // The last stroke that has started by then.
    var lo = 0, hi = strokes.length;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_starts[mid] <= t) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final i = lo - 1;
    if (i < 0) return (done: 0, drawing: null);
    final f = (t - _starts[i]) / _lengths[i];
    if (f >= 1) return (done: i + 1, drawing: null);
    return (done: i, drawing: strokes[i].partial(math.max(f, 0.01)));
  }

  static bool _drawsAlong(Stroke s) =>
      s.shape == null && s.text == null && s.area == null && s.points.length > 1;
}

/// Paints the replay of [timeline] at [seconds] on a paper of [size]: the
/// paper, the finished strokes on [layers] from [cache] (at [ratio] pixels
/// per point) and the stroke being drawn on top. The eraser cuts into its
/// layer, light and shadow mix with it, the blender mixes it, as when the
/// painting was made. Strokes come bottom layer first, so the layers above
/// the one being drawn on are still empty.
void paintReplayFrame(
    Canvas canvas,
    Size size,
    ReplayTimeline timeline,
    double seconds,
    Color paper,
    List<PaintingLayer> layers,
    LayeredCache cache,
    double ratio) {
  final now = timeline.at(seconds);
  final done = timeline.strokes.sublist(0, now.done);
  final drawing = now.drawing;
  canvas.drawRect(Offset.zero & size, Paint()..color = paper);
  if (drawing != null && drawing.paintsIntoLayer) {
    cache.paint(canvas, size, done, layers, paper, ratio, intoLayer: drawing);
    return;
  }
  cache.paint(canvas, size, done, layers, paper, ratio);
  if (drawing == null) return;
  if (drawing.brush == BrushType.smudge) {
    final mine = [
      for (final s in done)
        if (s.layerId == drawing.layerId) s,
    ];
    paintSmudgeOver(canvas, size, mine, drawing,
        paper: paper,
        finished: cache.imageOf(drawing.layerId, mine, size));
  } else {
    drawing.paint(canvas);
  }
}
