import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'stroke.dart';

/// Paints [strokes] in order over a paper of [size] and [paper] color.
///
/// They go on their own layer so the eraser only removes ink, not the
/// paper. A blender stroke shows a blurred picture of everything painted
/// before it; see [Stroke.paintSmudge].
void paintStrokes(Canvas canvas, Size size, List<Stroke> strokes,
    {required Color paper}) {
  canvas.saveLayer(Offset.zero & size, Paint());
  for (var i = 0; i < strokes.length; i++) {
    _paintAt(canvas, size, strokes, i, paper);
  }
  canvas.restore();
}

/// Paints [smudge], a blender stroke still being drawn on top of every
/// finished one in [strokes].
void paintSmudgeOver(Canvas canvas, Size size, List<Stroke> strokes,
    Stroke smudge, {required Color paper}) {
  final under = _under(smudge, strokes, strokes.length, size, paper);
  if (under != null) smudge.paintSmudge(canvas, under.image, under.rect);
}

void _paintAt(
    Canvas canvas, Size size, List<Stroke> strokes, int i, Color paper) {
  final s = strokes[i];
  if (s.brush != BrushType.smudge) {
    s.paint(canvas);
    return;
  }
  final under = _under(s, strokes, i, size, paper);
  if (under != null) s.paintSmudge(canvas, under.image, under.rect);
}

/// The blurred picture under a blender stroke, kept until something
/// under it changes.
class _Under {
  _Under(this.region, this.below, this.paper, this.image, this.rect);

  final Rect region;

  /// The strokes it was made from (strokes are never changed in place, so
  /// the same objects mean the same picture).
  final List<Stroke> below;
  final int paper;
  final ui.Image image;

  /// Where [image] goes on the paper.
  final Rect rect;
}

final _cache = Expando<_Under>('blender');

/// The paint under [smudge] (the first [count] of [strokes]), blurred.
/// While the stroke is being drawn the whole paper is taken, once, so it
/// can go anywhere; when it's finished, only the part around it.
_Under? _under(Stroke smudge, List<Stroke> strokes, int count, Size size,
    Color paper) {
  final page = Offset.zero & size;
  final radius = smudge.smudgeRadius;
  final region = (smudge.isComplete ? smudge.bounds.inflate(radius * 3) : page)
      .intersect(page);
  if (region.width < 1 || region.height < 1) return null;
  final below = [
    for (var j = 0; j < count; j++)
      if (strokes[j].bounds.overlaps(region)) j,
  ];
  final belowStrokes = [for (final j in below) strokes[j]];
  final cached = _cache[smudge];
  if (cached != null &&
      cached.region == region &&
      cached.paper == paper.toARGB32() &&
      cached.below.length == belowStrokes.length &&
      Iterable.generate(belowStrokes.length)
          .every((k) => identical(cached.below[k], belowStrokes[k]))) {
    return cached;
  }

  // Big papers are taken at a lower resolution; it's blurred anyway.
  final scale = math.min(1.0, 2048 / math.max(region.width, region.height));
  final w = math.max(1, (region.width * scale).ceil());
  final h = math.max(1, (region.height * scale).ceil());
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..scale(scale)
    ..translate(-region.left, -region.top)
    ..clipRect(region)
    // Clamped edges, so the picture doesn't fade out at its border.
    ..saveLayer(
        region,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
              sigmaX: radius * scale,
              sigmaY: radius * scale,
              tileMode: TileMode.clamp))
    ..drawRect(region, Paint()..color = paper)
    ..saveLayer(region, Paint());
  for (final j in below) {
    _paintAt(canvas, size, strokes, j, paper);
  }
  canvas
    ..restore()
    ..restore();
  final image = recorder.endRecording().toImageSync(w, h);
  final under = _Under(region, belowStrokes, paper.toARGB32(), image,
      Rect.fromLTWH(region.left, region.top, w / scale, h / scale));
  _cache[smudge] = under;
  return under;
}
