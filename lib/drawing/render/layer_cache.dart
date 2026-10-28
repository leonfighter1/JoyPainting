import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

  /// Paints [strokes] (and [intoLayer], a stroke being drawn into this
  /// layer: the eraser, light and shadow) on [canvas] at [size], from the
  /// picture kept at [ratio] pixels per paper point.
  ///
  /// With a [clock], strokes still missing from the picture are painted
  /// only until it passes [budget] (at least one if [atLeastOne]), and the
  /// rest on later calls: a slice at a time. Returns how many of [strokes]
  /// are painted.
  int paint(Canvas canvas, Size size, List<Stroke> strokes, Color paper,
      double ratio,
      {Stroke? intoLayer,
      Stopwatch? clock,
      Duration budget = Duration.zero,
      bool atLeastOne = true}) {
    final width = (size.width * ratio).ceil();
    final height = (size.height * ratio).ceil();
    if (!enabled || width <= 0 || height <= 0 || width * height > maxPixels) {
      dispose();
      paintStrokes(canvas, size, [...strokes, ?intoLayer], paper: paper);
      return strokes.length;
    }
    final painted = _update(size, strokes, paper.toARGB32(), ratio, width,
        height, clock: clock, budget: budget, atLeastOne: atLeastOne);
    if (painted == 0) {
      // Nothing of these strokes painted yet (the picture kept may be
      // another painting's); a stroke being drawn still goes on its own
      // layer, so an eraser doesn't cut into the paper.
      if (intoLayer != null) {
        canvas.saveLayer(Offset.zero & size, Paint());
        intoLayer.paint(canvas);
        canvas.restore();
      }
      return 0;
    }
    final image = _current!.image;
    final src = Rect.fromLTWH(
        0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, image.width / ratio, image.height / ratio);
    final look = Paint()..filterQuality = FilterQuality.medium;
    if (intoLayer == null) {
      canvas.drawImageRect(image, src, dst, look);
      return painted;
    }
    // Into the strokes' layer, not the paper under it: the eraser cuts
    // into it, light and shadow mix with it.
    canvas
      ..saveLayer(Offset.zero & size, Paint())
      ..drawImageRect(image, src, dst, look);
    intoLayer.paint(canvas);
    canvas.restore();
    return painted;
  }

  /// Brings the picture up to [strokes] (or, with a [clock], as far as
  /// [budget] allows) and returns how many of them it shows.
  int _update(Size size, List<Stroke> strokes, int paper, double ratio,
      int width, int height,
      {Stopwatch? clock,
      Duration budget = Duration.zero,
      bool atLeastOne = true}) {
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
    final from = base?.drawn.length ?? 0;
    if (from == strokes.length) return from;
    // Painting in slices, and this frame's time is up.
    if (clock != null && !atLeastOne && clock.elapsed >= budget) return from;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    if (base != null) {
      canvas.drawImageRect(
          base.image,
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          Rect.fromLTWH(0, 0, width / ratio, height / ratio),
          Paint());
    } else {
      rebuilds++;
    }
    var to = strokes.length;
    if (clock != null) {
      // A slice: one stroke after another while there's time.
      to = from;
      do {
        paintStrokeRange(canvas, size, strokes, to, to + 1, paper: Color(paper));
        to++;
      } while (to < strokes.length && clock.elapsed < budget);
    } else if (base != null) {
      paintStrokeRange(canvas, size, strokes, from, to, paper: Color(paper));
    } else {
      paintStrokes(canvas, size, strokes, paper: Color(paper));
    }
    final next = _Kept(recorder.endRecording().toImageSync(width, height),
        strokes.sublist(0, to), size, ratio, paper);
    if (clock != null && base != null && identical(base, _current)) {
      // The slice before this one: no state to undo back to.
      base.image.dispose();
    } else {
      _keep(_current);
    }
    _current = next;
    return to;
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

/// A [StrokeLayerCache] for each layer of a painting, composed bottom
/// first at each layer's opacity. Adding to one layer, or erasing on it,
/// leaves the pictures of the others as they are.
class LayeredCache {
  /// [sliced]: a painting just opened may be painted a slice at a time
  /// (see [paintInSlices]); only the canvas asks for it. The replay paints
  /// every frame whole.
  LayeredCache({this.sliced = false});

  final bool sliced;

  /// How long one frame spends painting strokes while a painting is
  /// painted in slices: the screen stays alive and the progress shows.
  static Duration sliceBudget = const Duration(milliseconds: 24);

  final _caches = <String, StrokeLayerCache>{};

  /// How many times any layer's picture was painted from the start; for
  /// tests.
  int get rebuilds => _caches.values.fold(0, (n, c) => n + c.rebuilds);

  /// Told after each frame of a painting painted in slices how much of it
  /// is painted, and null once all of it is.
  void Function(double? done)? _onSlice;

  /// Ticks for one more frame while slices are left to paint.
  final _more = ValueNotifier<int>(0);

  /// What a painter of this cache repaints on, as well as its strokes.
  Listenable get repaint => _more;

  /// Paints the next picture of every layer a slice at a time: as many
  /// strokes as fit in [sliceBudget] each frame, the lowest layers first,
  /// so a big painting doesn't freeze the screen while it's put on the
  /// paper. [onProgress] is told after each frame how much is painted (0
  /// to 1), and null once it's all on the paper, after one frame if the
  /// painting is small. Does nothing unless the cache is [sliced].
  void paintInSlices(void Function(double? done) onProgress) {
    if (!sliced) return;
    _onSlice = onProgress;
    _more.value++;
  }

  /// Paints [strokes] on [layers] (and [intoLayer] being drawn on its
  /// layer, if any) at [ratio] pixels per paper point. No paper.
  void paint(Canvas canvas, Size size, List<Stroke> strokes,
      List<PaintingLayer> layers, Color paper, double ratio,
      {Stroke? intoLayer}) {
    _caches.removeWhere((id, cache) {
      final gone = !layers.any((l) => l.id == id);
      if (gone) cache.dispose();
      return gone;
    });
    final report = _onSlice;
    final clock = report == null ? null : (Stopwatch()..start());
    var total = 0, painted = 0;
    final page = Offset.zero & size;
    for (final layer in layers) {
      if (!layer.visible || layer.opacity <= 0) continue;
      final own = [
        for (final s in strokes)
          if (s.layerId == layer.id) s,
      ];
      final drawn = intoLayer?.layerId == layer.id ? intoLayer : null;
      if (own.isEmpty && drawn == null) continue;
      final cache = _caches.putIfAbsent(layer.id, StrokeLayerCache.new);
      final seeThrough = layer.opacity < 1;
      if (seeThrough) {
        canvas.saveLayer(
            page, Paint()..color = Color.fromRGBO(0, 0, 0, layer.opacity));
      }
      // The lowest unfinished layer always gets a slice, so every frame
      // gets further.
      painted += cache.paint(canvas, size, own, paper, ratio,
          intoLayer: drawn,
          clock: clock,
          budget: sliceBudget,
          atLeastOne: painted == total);
      total += own.length;
      if (seeThrough) canvas.restore();
    }
    if (report == null) return;
    final finished = painted >= total;
    if (finished) _onSlice = null;
    // Not while painting: listeners may rebuild widgets.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      report(finished ? null : painted / total);
      if (!finished) _more.value++;
    });
  }

  /// The picture of layer [id] if it shows exactly [strokes] (that
  /// layer's) on a paper of [size], else null.
  ui.Image? imageOf(String id, List<Stroke> strokes, Size size) =>
      _caches[id]?.imageOf(strokes, size);

  void dispose() {
    for (final c in _caches.values) {
      c.dispose();
    }
    _caches.clear();
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
