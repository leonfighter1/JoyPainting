import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../stroke.dart';
import 'paint_strokes.dart';

/// The finished strokes kept as one picture, so a big painting isn't
/// painted again stroke by stroke for every change.
///
/// It holds the strokes' own layer (no paper: the paper is painted under
/// it, so the eraser still shows the paper). When the strokes only grew
/// (a new stroke, a paste), just the new ones are painted onto it; while
/// the eraser is used, only the picture and the eraser are painted. Any
/// other change (moving or recoloring strokes, another painting) paints it
/// again from the start, as before; an undo or redo usually finds its
/// picture kept from before.
///
/// Strokes are never changed once finished, so the same stroke objects in
/// the same order mean the same picture.
class StrokeLayerCache {
  /// The biggest picture kept (about 64 MB). Beyond it (a big paper zoomed
  /// far in) strokes are painted directly, so they stay sharp.
  static const maxPixels = 4096 * 4096;

  /// All pictures kept together (the current one and earlier ones, for
  /// undo and redo) stay under this many pixels (about 64 MB)...
  static const maxKeptPixels = 4096 * 4096;

  /// ...and this many earlier ones.
  static const maxEarlier = 8;

  /// Off paints every stroke directly, as before the cache; only for
  /// measuring (tool/bench/drawing_bench.dart).
  static bool enabled = true;

  _Kept? _current;

  /// Pictures of earlier states, oldest first, so an undo or a redo finds
  /// its picture ready instead of painting every stroke again.
  final _earlier = <_Kept>[];

  /// How many times a picture was painted from the start; for tests.
  int rebuilds = 0;

  /// The current picture if it shows exactly [strokes] on a paper of
  /// [size], else null.
  ui.Image? imageOf(List<Stroke> strokes, Size size) {
    final k = _current;
    return k != null &&
            k.size == size &&
            k.drawn.length == strokes.length &&
            k.isStartOf(strokes)
        ? k.image
        : null;
  }

  /// Paints [strokes] (and the [eraser] being used, if any) on [canvas] at
  /// [size], from the picture kept at [ratio] pixels per paper point.
  void paint(Canvas canvas, Size size, List<Stroke> strokes, Color paper,
      double ratio, {Stroke? eraser}) {
    final width = (size.width * ratio).ceil();
    final height = (size.height * ratio).ceil();
    if (!enabled || width <= 0 || height <= 0 || width * height > maxPixels) {
      dispose();
      paintStrokes(canvas, size, [...strokes, ?eraser], paper: paper);
      return;
    }
    _update(size, strokes, paper.toARGB32(), ratio, width, height);
    final image = _current!.image;
    final src = Rect.fromLTWH(
        0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, image.width / ratio, image.height / ratio);
    final look = Paint()..filterQuality = FilterQuality.medium;
    if (eraser == null) {
      canvas.drawImageRect(image, src, dst, look);
      return;
    }
    // The eraser cuts into the strokes' layer, not the paper under it.
    canvas
      ..saveLayer(Offset.zero & size, Paint())
      ..drawImageRect(image, src, dst, look);
    eraser.paint(canvas);
    canvas.restore();
  }

  void _update(Size size, List<Stroke> strokes, int paper, double ratio,
      int width, int height) {
    // Pictures at another size can't be used now.
    _earlier.removeWhere((k) {
      final stale = k.size != size || k.ratio != ratio;
      if (stale) k.image.dispose();
      return stale;
    });
    bool fits(_Kept k) =>
        k.size == size &&
        k.ratio == ratio &&
        // A blender mixes in the paper, so a new paper color changes it.
        (!k.hasBlender || k.paper == paper) &&
        k.isStartOf(strokes);
    var base = _current != null && fits(_current!) ? _current : null;
    if (base == null) {
      // An undo or redo back to a state seen before: the closest picture.
      for (final k in _earlier) {
        if (fits(k) && (base == null || k.drawn.length > base.drawn.length)) {
          base = k;
        }
      }
      if (base != null) {
        _earlier.remove(base);
        _keep(_current);
        _current = base;
      }
    }
    if (base != null && base.drawn.length == strokes.length) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    if (base != null) {
      canvas.drawImageRect(
          base.image,
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          Rect.fromLTWH(0, 0, width / ratio, height / ratio),
          Paint());
      paintStrokeRange(canvas, size, strokes, base.drawn.length,
          strokes.length,
          paper: Color(paper));
    } else {
      rebuilds++;
      paintStrokes(canvas, size, strokes, paper: Color(paper));
    }
    final next = _Kept(recorder.endRecording().toImageSync(width, height),
        List.of(strokes), size, ratio, paper);
    _keep(_current);
    _current = next;
  }

  /// Keeps [k] for undo, forgetting the oldest pictures past the limits.
  /// A blank one isn't worth keeping: painting on it is painting from
  /// the start.
  void _keep(_Kept? k) {
    if (k == null) return;
    if (k.drawn.isEmpty) {
      k.image.dispose();
      return;
    }
    _earlier.add(k);
    int kept() => _earlier.fold(_current?.pixels ?? 0, (n, k) => n + k.pixels);
    while (_earlier.isNotEmpty &&
        (_earlier.length > maxEarlier || kept() > maxKeptPixels)) {
      _earlier.removeAt(0).image.dispose();
    }
  }

  void dispose() {
    _current?.image.dispose();
    _current = null;
    for (final k in _earlier) {
      k.image.dispose();
    }
    _earlier.clear();
  }
}

/// A kept picture and what it shows.
class _Kept {
  _Kept(this.image, this.drawn, this.size, this.ratio, this.paper)
      : hasBlender = drawn.any((s) => s.brush == BrushType.smudge);

  final ui.Image image;

  /// The strokes it shows, in order.
  final List<Stroke> drawn;
  final Size size;
  final double ratio;

  /// The paper color (as ARGB) a blender in it mixed in.
  final int paper;
  final bool hasBlender;

  int get pixels => image.width * image.height;

  /// Whether its strokes are the first ones of [strokes].
  bool isStartOf(List<Stroke> strokes) {
    if (strokes.length < drawn.length) return false;
    for (var i = 0; i < drawn.length; i++) {
      if (!identical(strokes[i], drawn[i])) return false;
    }
    return true;
  }
}

/// How many pixels per paper point the screen shows, rounded up to whole
/// zoom steps (1×, 2×, 4×, 8×), so pinching rebuilds the cache rarely.
double cacheRatioFor(double devicePixelRatio, double fitScale, double zoom) {
  final step = zoom <= 1
      ? 1.0
      : math.pow(2, (math.log(zoom) / math.ln2 - 1e-9).ceil()).toDouble();
  return devicePixelRatio * fitScale * step;
}
