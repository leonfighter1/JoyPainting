import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'brush_type.dart';
import 'shape_kind.dart';
import 'stroke_style.dart';
import 'stroke_texture.dart';
import 'stroke_transform.dart';
import 'text_content.dart';

export 'brush_type.dart';
export 'shape_kind.dart';
export 'stroke_style.dart';
export 'stroke_texture.dart';
export 'stroke_transform.dart';
export 'text_content.dart';

part 'stroke_paint.dart';

/// One continuous stroke made with a single brush.
class Stroke {
  Stroke({
    required this.brush,
    required this.color,
    required this.size,
    required this.usesRealPressure,
    this.opacity = 1,
    int? seed,
    this.stamp = StampShape.heart,
    this.mirrorX,
    this.shape,
    this.fill = false,
    this.text,
    this.transform,
    this.gradient,
    this.blur = 0,
    this.blend = StrokeBlend.normal,
    this.texture = StrokeTexture.none,
    List<PointVector>? points,
    this.area,
    this.isComplete = false,
  })  : seed = seed ?? math.Random().nextInt(1 << 30),
        points = points ?? [];

  /// A text item anchored at [anchor] (its left, center or right edge,
  /// depending on alignment, at the top of the text).
  factory Stroke.text({
    required Offset anchor,
    required TextContent content,
    required Color color,
    double opacity = 1,
    StrokeTransform? transform,
  }) =>
      Stroke(
        brush: BrushType.text,
        color: color,
        size: content.fontSize / BrushType.text.sizeFactor,
        opacity: opacity,
        usesRealPressure: false,
        seed: 0,
        text: content,
        transform: transform,
        isComplete: true,
        points: [PointVector(anchor.dx, anchor.dy, 0.5)],
      );

  /// A copy of any stroke shifted by [delta]. Strokes are never changed in
  /// place (undo snapshots rely on that), so moving makes a new one. The
  /// seed is kept so spray and stamps look identical after the move, and a
  /// mirrored stroke's axis moves with it so the pair stays together.
  Stroke moved(Offset delta) {
    // A turned or resized stroke moves by adding to its transform.
    if (transform != null) {
      return transformed(StrokeTransform.translation(delta));
    }
    if (text != null) {
      return Stroke.text(
          anchor: anchor + delta, content: text!, color: color, opacity: opacity);
    }
    return _copy(
      delta: delta,
      color: color,
      opacity: opacity,
      mirrorX: mirrorX == null ? null : mirrorX! + delta.dx,
      transform: null,
      gradient: gradient,
    );
  }

  /// A copy turned and/or resized by [t], on top of any earlier transform.
  Stroke transformed(StrokeTransform t) =>
      copyWith(transform: () => (transform ?? _identity).then(t));

  static const _identity = StrokeTransform(1, 0, 0, 1, 0, 0);

  /// A copy with a new color, opacity or transform. Everything else,
  /// including the seed, stays the same, except that a new color replaces
  /// a gradient.
  Stroke copyWith({
    Color? color,
    double? opacity,
    StrokeTransform? Function()? transform,
  }) {
    final c = color ?? this.color;
    final o = opacity ?? this.opacity;
    final t = transform == null ? this.transform : transform();
    if (text != null) {
      return Stroke.text(
          anchor: anchor, content: text!, color: c, opacity: o, transform: t);
    }
    return _copy(
      delta: Offset.zero,
      color: c,
      opacity: o,
      mirrorX: mirrorX,
      transform: t,
      gradient: color == null ? gradient : null,
    );
  }

  /// The first [fraction] (0–1) of a freehand stroke, as it looked while
  /// it was being drawn, for replays. Shapes, text and filled areas appear
  /// whole, so they come back as they are.
  Stroke partial(double fraction) {
    if (fraction >= 1 ||
        shape != null ||
        text != null ||
        area != null ||
        points.length < 2) {
      return this;
    }
    final n = math.max(1, (points.length * fraction).ceil());
    return Stroke(
      brush: brush,
      color: color,
      size: size,
      opacity: opacity,
      usesRealPressure: usesRealPressure,
      seed: seed,
      stamp: stamp,
      mirrorX: mirrorX,
      fill: fill,
      transform: transform,
      gradient: gradient,
      blur: blur,
      blend: blend,
      texture: texture,
      points: points.sublist(0, n),
    );
  }

  /// A finished copy of a shape or freehand stroke, shifted by [delta],
  /// with the given changes.
  Stroke _copy({
    required Offset delta,
    required Color color,
    required double opacity,
    required double? mirrorX,
    required StrokeTransform? transform,
    required StrokeGradient? gradient,
  }) {
    if (shape != null) {
      return Stroke.shape(
        shape: shape!,
        from: _from! + delta,
        to: _to! + delta,
        brush: brush,
        color: color,
        size: size,
        opacity: opacity,
        fill: fill,
        seed: seed,
        stamp: stamp,
        mirrorX: mirrorX,
        transform: transform,
        gradient: gradient,
        blur: blur,
        blend: blend,
        texture: texture,
        isComplete: true,
      );
    }
    return Stroke(
      brush: brush,
      color: color,
      size: size,
      opacity: opacity,
      usesRealPressure: usesRealPressure,
      seed: seed,
      stamp: stamp,
      mirrorX: mirrorX,
      fill: fill,
      transform: transform,
      gradient: gradient,
      blur: blur,
      blend: blend,
      texture: texture,
      isComplete: true,
      points: [
        for (final p in points)
          PointVector(p.x + delta.dx, p.y + delta.dy, p.pressure),
      ],
      area: area == null
          ? null
          : [
              for (final loop in area!) [for (final p in loop) p + delta],
            ],
    );
  }

  /// Whether [p] is on this stroke: inside text, a filled shape or a free
  /// shape, or within finger reach of its line (or of its mirror image).
  bool hits(Offset p, {double reach = 14}) {
    if (transform case final t?) {
      // Test in the stroke's own coordinates.
      p = t.inverse.apply(p);
      reach /= t.scale;
    }
    if (text != null) return textBounds.contains(p);
    if (!_localBounds.inflate(reach).contains(p)) return false;
    final candidates = [p, if (mirrorX case final m?) Offset(2 * m - p.dx, p.dy)];
    final tolerance = width / 2 + reach;
    for (final q in candidates) {
      if (fill && _fillArea.contains(q)) return true;
      // The line between points counts too: a quick swipe records few
      // points far apart.
      for (var i = 0; i < points.length; i++) {
        final a = points[i] as Offset;
        final b = i + 1 < points.length ? points[i + 1] as Offset : a;
        if (_distanceToSegment(q, a, b) <= tolerance) return true;
      }
    }
    return false;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.distanceSquared;
    if (len2 == 0) return (p - a).distance;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  /// Whether a selection box drawn over the paper catches this stroke:
  /// some of its line (or its mirror image) is inside [box], or [box]
  /// overlaps its text.
  bool touches(Rect box) {
    if (!bounds.overlaps(box)) return false;
    if (text != null) return true;
    final t = transform;
    Offset place(Offset q) => t == null ? q : t.apply(q);
    for (var i = 0; i < points.length; i++) {
      final a = points[i] as Offset;
      final b = i + 1 < points.length ? points[i + 1] as Offset : a;
      // Walk each segment in small steps: few, far-apart points still
      // count where the line between them crosses the box.
      final steps = math.max(1, ((b - a).distance / 4).ceil());
      for (var k = 0; k <= steps; k++) {
        final q = Offset.lerp(a, b, k / steps)!;
        if (box.contains(place(q))) return true;
        if (mirrorX case final m? when box.contains(place(Offset(2 * m - q.dx, q.dy)))) {
          return true;
        }
      }
    }
    // A big filled shape can be caught by a box drawn inside it.
    return fill && hits(box.center, reach: 0);
  }

  /// Creates a shape stroke from [from] to [to]; its points are generated
  /// along the outline so every brush can draw it.
  factory Stroke.shape({
    required ShapeKind shape,
    required Offset from,
    required Offset to,
    required BrushType brush,
    required Color color,
    required double size,
    double opacity = 1,
    bool fill = false,
    int? seed,
    StampShape stamp = StampShape.heart,
    double? mirrorX,
    StrokeTransform? transform,
    StrokeGradient? gradient,
    double blur = 0,
    StrokeBlend blend = StrokeBlend.normal,
    StrokeTexture texture = StrokeTexture.none,
    bool isComplete = false,
  }) =>
      Stroke(
        brush: brush,
        color: color,
        size: size,
        opacity: opacity,
        usesRealPressure: false,
        seed: seed,
        stamp: stamp,
        mirrorX: mirrorX,
        shape: shape,
        fill: fill && shape.closed,
        transform: transform,
        gradient: gradient,
        blur: blur,
        blend: blend,
        texture: texture,
        isComplete: isComplete,
      )..setShapeEnds(from, to);

  final BrushType brush;
  final Color color;

  /// The slider size when the stroke was drawn, before [BrushType.sizeFactor].
  final double size;

  /// The opacity slider, 0.05 to 1.
  final double opacity;

  /// Stylus input reports real pressure; finger input gets simulated pressure.
  final bool usesRealPressure;

  /// Seeds the spray dots and stamp wobble, so a saved stroke looks exactly
  /// the same every time it is drawn.
  final int seed;
  final StampShape stamp;

  /// When set, the stroke is also drawn mirrored across this vertical line.
  final double? mirrorX;

  /// Set for shape strokes; null for freehand.
  final ShapeKind? shape;

  /// Whether a closed shape is filled with the stroke's color. A filled
  /// freehand stroke is a free shape: the area its line goes around is
  /// filled, and the line itself isn't drawn.
  final bool fill;

  /// An exact area to fill, as closed outlines: the first goes around it,
  /// any others are its holes (filled even-odd). The paint bucket makes
  /// these; [points] hold the first outline too, so older versions still
  /// fill around it (smoothed, without the holes).
  final List<List<Offset>>? area;

  /// Set for text items; null otherwise.
  final TextContent? text;

  /// Set once the stroke has been turned or resized with the move tool.
  final StrokeTransform? transform;

  /// Paints a blend of colors instead of [color]; see [StrokeGradient].
  /// Text ignores it.
  final StrokeGradient? gradient;

  /// How blurred the edges are, as a blur radius in pixels: soft shadows,
  /// glows, shading. Lines, shapes and free shapes use it.
  final double blur;

  /// How the stroke mixes with the strokes under it.
  final StrokeBlend blend;

  /// The grain its paint is laid with. Text, the eraser and the blender
  /// ignore it.
  final StrokeTexture texture;
  TextPainter? _textPainter;
  Offset? _from;
  Offset? _to;

  final List<PointVector> points;
  bool isComplete;

  Path? _cachedPath;
  final List<Offset> _sprayDots = [];
  int _sprayPointsDone = 0;

  double get width => size * brush.sizeFactor;

  Offset? get shapeFrom => _from;
  Offset? get shapeTo => _to;

  /// Moves a shape's corners and regenerates its points.
  void setShapeEnds(Offset from, Offset to) {
    assert(shape != null);
    _from = from;
    _to = to;
    points
      ..clear()
      ..addAll(_sampleOutline(_shapePath));
    _cachedPath = null;
    _sprayDots.clear();
    _sprayPointsDone = 0;
  }

  /// A shape smaller than this (a tap rather than a drag) is discarded.
  bool get isDegenerateShape =>
      shape != null && (_to! - _from!).distance < 3;

  Path get _shapePath =>
      shape!.path(_from!, _to!, arrowHead: math.max(14, width * 2.5));

  /// Points every ~3px along [path], for brushes that follow points.
  static List<PointVector> _sampleOutline(Path path) {
    final out = <PointVector>[];
    for (final metric in path.computeMetrics()) {
      final steps = math.max(1, (metric.length / 3).ceil());
      for (var i = 0; i <= steps; i++) {
        final t = metric.getTangentForOffset(metric.length * i / steps);
        if (t != null) out.add(PointVector(t.position.dx, t.position.dy, 0.5));
      }
    }
    return out;
  }

  Offset get anchor => points.first;

  TextPainter get _laidOutText => _textPainter ??= TextPainter(
        text: TextSpan(text: text!.text, style: text!.style(color.withValues(alpha: 1))),
        textAlign: text!.align,
        textDirection: TextDirection.ltr,
      )..layout();

  /// Where the text's top-left corner goes, given its alignment.
  Offset get _textTopLeft {
    final w = _laidOutText.width;
    return switch (text!.align) {
      TextAlign.center => anchor - Offset(w / 2, 0),
      TextAlign.right || TextAlign.end => anchor - Offset(w, 0),
      _ => anchor,
    };
  }

  /// The area a text item covers, including its bubble; used for tapping
  /// and dragging text.
  Rect get textBounds {
    final rect = _textTopLeft & _laidOutText.size;
    return rect.inflate(text!.bubble ? TextContent.bubblePadding : 4);
  }

  /// The area a filled shape or a free shape covers.
  Path get _fillArea {
    if (shape != null) return _shapePath;
    if (_cachedFillArea case final cached?) return cached;
    if (area case final loops?) {
      final exact = Path()..fillType = PathFillType.evenOdd;
      for (final loop in loops) {
        exact.addPolygon(loop, true);
      }
      return _cachedFillArea = exact;
    }
    // A smooth closed curve through the points.
    final smooth = _outlineToPath([for (final p in points) p]);
    if (isComplete) _cachedFillArea = smooth;
    return smooth;
  }

  Path? _cachedFillArea;

  /// The box a gradient is placed in: a shape's corners, or around the
  /// points of a line or free shape.
  Rect get _outlineBox =>
      shape != null ? Rect.fromPoints(_from!, _to!) : _pointBox;

  Rect get _pointBox {
    if (points.isEmpty) return Rect.zero;
    var r = Rect.fromLTWH(points.first.x, points.first.y, 0, 0);
    for (final p in points) {
      r = r.expandToInclude(Rect.fromLTWH(p.x, p.y, 0, 0));
    }
    return r;
  }

  /// The area this stroke paints on the paper, mirror image and transform
  /// included.
  Rect get bounds => transform?.applyRect(_localBounds) ?? _localBounds;

  /// [bounds] before the transform.
  Rect get _localBounds {
    if (text != null) return textBounds;
    final r = _bounds;
    if (mirrorX case final m?) {
      return r.expandToInclude(
          Rect.fromLTRB(2 * m - r.right, r.top, 2 * m - r.left, r.bottom));
    }
    return r;
  }

  Rect get _bounds =>
      points.isEmpty ? Rect.zero : _pointBox.inflate(width + 4 + blur * 3);

  Path get path {
    if (_cachedPath != null) return _cachedPath!;
    final outline = getStroke(
      points,
      options: StrokeOptions(
        size: width,
        thinning: brush.thinning,
        smoothing: brush.smoothing,
        streamline: brush.streamline,
        simulatePressure: !usesRealPressure && brush.thinning > 0,
        isComplete: isComplete,
      ),
    );
    final path = _outlineToPath(outline);
    // Only cache once the stroke is finished; in-progress strokes keep changing.
    if (isComplete) _cachedPath = path;
    return path;
  }

  static Path _outlineToPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    if (pts.length < 2) {
      return path..addOval(Rect.fromCircle(center: pts.first, radius: 1));
    }
    path.moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      path.quadraticBezierTo(
          p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }
    return path..close();
  }

  /// Points are stored as a flat [x, y, pressure, x, y, pressure, ...] list,
  /// rounded to keep saved files small.
  Map<String, Object?> toJson() => {
        'brush': brush.name,
        'color': color.toARGB32(),
        'size': size,
        'opacity': opacity,
        'realPressure': usesRealPressure,
        'seed': seed,
        if (brush == BrushType.stamp) 'stamp': stamp.name,
        if (mirrorX != null) 'mirrorX': _round(mirrorX!, 10),
        if (transform != null) 'transform': transform!.toJson(),
        if (gradient != null) 'gradient': gradient!.toJson(),
        if (blur > 0) 'blur': _round(blur, 10),
        if (blend != StrokeBlend.normal) 'blend': blend.name,
        if (texture != StrokeTexture.none) 'texture': texture.name,
        if (text != null) 'text': text!.toJson(),
        // Shapes are stored by their two corners and rebuilt on load.
        if (shape != null) ...{
          'shape': shape!.name,
          'fill': fill,
          'from': [_round(_from!.dx, 10), _round(_from!.dy, 10)],
          'to': [_round(_to!.dx, 10), _round(_to!.dy, 10)],
          'points': const <num>[],
        } else ...{
          if (fill) 'fill': true,
          if (area != null)
            'area': [
              for (final loop in area!)
                [
                  for (final p in loop) ...[_round(p.dx, 10), _round(p.dy, 10)],
                ],
            ],
          'points': [
            for (final p in points) ...[
              _round(p.x, 10),
              _round(p.y, 10),
              _round(p.pressure ?? 0.5, 100),
            ],
          ],
        },
      };

  factory Stroke.fromJson(Map<String, Object?> json) {
    // Paintings saved before v2.0 have no transform.
    final transform = StrokeTransform.fromJson(json['transform']);
    // Nor gradients, blur or blend before v2.3.
    final gradient = StrokeGradient.fromJson(json['gradient']);
    final blur = (json['blur'] as num? ?? 0).toDouble();
    final blend = StrokeBlend.fromName(json['blend'] as String?);
    // Nor textures before v3.1.
    final texture = StrokeTexture.fromName(json['texture'] as String?);
    if (json['text'] case final Map<String, Object?> text) {
      final p = (json['points'] as List).cast<num>();
      return Stroke.text(
        anchor: Offset(p[0].toDouble(), p[1].toDouble()),
        content: TextContent.fromJson(text),
        color: Color(json['color'] as int),
        opacity: (json['opacity'] as num? ?? 1).toDouble(),
        transform: transform,
      );
    }
    final shape = ShapeKind.fromName(json['shape'] as String?);
    if (shape != null) {
      Offset offset(String key) {
        final v = (json[key] as List).cast<num>();
        return Offset(v[0].toDouble(), v[1].toDouble());
      }

      return Stroke.shape(
        shape: shape,
        from: offset('from'),
        to: offset('to'),
        brush: BrushType.fromName(json['brush'] as String?),
        color: Color(json['color'] as int),
        size: (json['size'] as num).toDouble(),
        opacity: (json['opacity'] as num? ?? 1).toDouble(),
        fill: json['fill'] as bool? ?? false,
        seed: json['seed'] as int? ?? 0,
        stamp: StampShape.fromName(json['stamp'] as String?),
        mirrorX: (json['mirrorX'] as num?)?.toDouble(),
        transform: transform,
        gradient: gradient,
        blur: blur,
        blend: blend,
        texture: texture,
        isComplete: true,
      );
    }
    final flat = (json['points'] as List).cast<num>();
    return Stroke(
      brush: BrushType.fromName(json['brush'] as String?),
      color: Color(json['color'] as int),
      size: (json['size'] as num).toDouble(),
      // Paintings saved before v1.2 have no opacity, seed, stamp or mirror.
      opacity: (json['opacity'] as num? ?? 1).toDouble(),
      usesRealPressure: json['realPressure'] as bool? ?? false,
      seed: json['seed'] as int? ?? 0,
      stamp: StampShape.fromName(json['stamp'] as String?),
      mirrorX: (json['mirrorX'] as num?)?.toDouble(),
      transform: transform,
      fill: json['fill'] as bool? ?? false,
      gradient: gradient,
      blur: blur,
      blend: blend,
      texture: texture,
      isComplete: true,
      // Paint bucket areas since v4.1.
      area: switch (json['area']) {
        final List<Object?> loops => [
            for (final loop in loops.cast<List<Object?>>())
              [
                for (var i = 0; i + 1 < loop.length; i += 2)
                  Offset((loop[i]! as num).toDouble(),
                      (loop[i + 1]! as num).toDouble()),
              ],
          ],
        _ => null,
      },
      points: [
        for (var i = 0; i + 2 < flat.length; i += 3)
          PointVector(flat[i].toDouble(), flat[i + 1].toDouble(),
              flat[i + 2].toDouble()),
      ],
    );
  }

  static double _round(double v, int scale) => (v * scale).round() / scale;
}
