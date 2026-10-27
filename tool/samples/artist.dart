import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

/// What an area or line is painted with: one color, or a gradient placed
/// on the paper. It's turned into the stroke's own [StrokeGradient], which
/// is placed in the stroke's box.
class Fill {
  const Fill(Color color)
      : colors = const [],
        _color = color,
        stops = null,
        radial = false,
        from = Offset.zero,
        to = Offset.zero;

  const Fill.linear(this.from, this.to, this.colors, [this.stops])
      : _color = null,
        radial = false;

  /// Centered on [center], reaching [radius].
  Fill.radial(Offset center, double radius, this.colors, [this.stops])
      : _color = null,
        radial = true,
        from = center,
        to = center + Offset(radius, 0);

  final Color? _color;
  final List<Color> colors;
  final List<double>? stops;
  final bool radial;
  final Offset from;
  final Offset to;

  /// The stroke's own color: the solid one, or the gradient's strongest.
  Color get color => _color ?? colors.reduce((a, b) => b.a > a.a ? b : a);

  StrokeGradient? gradientIn(Rect box) {
    if (_color != null) return null;
    // A flat box gets some height, as when the stroke is painted.
    final b = Rect.fromCenter(
      center: box.center,
      width: math.max(box.width, 1),
      height: math.max(box.height, 1),
    );
    Offset fraction(Offset p) =>
        Offset((p.dx - b.left) / b.width, (p.dy - b.top) / b.height);
    return StrokeGradient(
      colors: colors,
      stops: stops,
      radial: radial,
      from: fraction(from),
      to: fraction(to),
    );
  }
}

/// Draws with the app's strokes. Sizes are on-paper widths in pixels.
class Artist {
  final strokes = <Stroke>[];
  var _seed = 1;

  /// Each stroke's [StrokeGradient] stores 3 decimals: fine enough for a
  /// box up to about 1000px across.
  void _shape(
    ShapeKind kind,
    Rect box,
    Fill fill, {
    bool filled = true,
    double width = 1,
    double angle = 0,
    StrokeTransform? transform,
    double blur = 0,
    StrokeBlend blend = StrokeBlend.normal,
    StrokeTexture texture = StrokeTexture.none,
    double opacity = 1,
  }) =>
      strokes.add(Stroke.shape(
        shape: kind,
        from: box.topLeft,
        to: box.bottomRight,
        brush: BrushType.pen,
        color: fill.color,
        size: width,
        opacity: opacity,
        fill: filled,
        seed: _seed++,
        transform: transform ??
            (angle == 0
                ? null
                : StrokeTransform.around(box.center, angle: angle)),
        gradient: fill.gradientIn(box),
        blur: blur,
        blend: blend,
        texture: texture,
        isComplete: true,
      ));

  void rect(Rect r, Color color) => _shape(ShapeKind.rectangle, r, Fill(color));

  /// An empty rectangle.
  void box(Rect r, Color color, {double width = 2}) =>
      _shape(ShapeKind.rectangle, r, Fill(color), filled: false, width: width);

  /// A filled ellipse, turned by [angle] (radians, clockwise; a gradient
  /// is placed as if it weren't turned).
  void oval(
    Offset c,
    double rx,
    double ry,
    Fill fill, {
    double angle = 0,
    double blur = 0,
    StrokeBlend blend = StrokeBlend.normal,
    StrokeTexture texture = StrokeTexture.none,
    double opacity = 1,
  }) =>
      _shape(ShapeKind.ellipse,
          Rect.fromCenter(center: c, width: rx * 2, height: ry * 2), fill,
          angle: angle,
          blur: blur,
          blend: blend,
          opacity: opacity,
          texture: texture);

  /// A soft light (or shade): [color] in the middle, fading out all
  /// around. [squash] flattens it and [angle] turns it, so the fade still
  /// reaches the edge.
  void glow(Offset c, double r, Color color,
      {StrokeBlend blend = StrokeBlend.normal,
      double squash = 1,
      double angle = 0}) {
    final flat = StrokeTransform(1, 0, 0, squash, 0, c.dy * (1 - squash));
    _shape(ShapeKind.ellipse, Rect.fromCircle(center: c, radius: r),
        Fill.radial(c, r, [color, color.withValues(alpha: 0)]),
        transform: angle == 0
            ? flat
            : flat.then(StrokeTransform.around(c, angle: angle)),
        blend: blend);
  }

  /// An empty circle.
  void ring(Offset c, double r, Color color, {double width = 2}) => _shape(
      ShapeKind.ellipse, Rect.fromCircle(center: c, radius: r), Fill(color),
      filled: false, width: width);

  void star(Offset c, double r, Color color) =>
      _shape(ShapeKind.star, Rect.fromCircle(center: c, radius: r), Fill(color));

  void diamond(Offset c, double r, Color color) => area([
        c + Offset(0, -r), c + Offset(r * 0.7, 0), c + Offset(0, r),
        c + Offset(-r * 0.7, 0),
      ], Fill(color), spacing: 1);

  /// A free shape: the area [outline] goes around, filled. Straight sides
  /// get a point every [spacing] pixels so corners stay sharp.
  void area(
    List<Offset> outline,
    Fill fill, {
    double blur = 0,
    StrokeBlend blend = StrokeBlend.normal,
    StrokeTexture texture = StrokeTexture.none,
    double opacity = 1,
    double spacing = 3,
  }) {
    final pts = densify([...outline, outline.first], spacing);
    strokes.add(Stroke(
      brush: BrushType.pen,
      color: fill.color,
      size: 1,
      opacity: opacity,
      usesRealPressure: false,
      seed: _seed++,
      fill: true,
      gradient: fill.gradientIn(boxOf(pts)),
      blur: blur,
      blend: blend,
      texture: texture,
      isComplete: true,
      points: [for (final p in pts) PointVector(p.dx, p.dy, 0.5)],
    ));
  }

  /// A smooth free shape through [corners] (a closed spline).
  void blob(
    List<Offset> corners,
    Fill fill, {
    double blur = 0,
    StrokeBlend blend = StrokeBlend.normal,
    StrokeTexture texture = StrokeTexture.none,
    double opacity = 1,
  }) =>
      area(spline(corners, closed: true), fill,
          blur: blur, blend: blend, opacity: opacity, texture: texture);

  /// A freehand stroke through [corners], with a point every few pixels as
  /// a hand would make. [taper] thins both ends, like a brush lifting off.
  void line(
    List<Offset> corners,
    Color color, {
    double width = 3,
    BrushType brush = BrushType.marker,
    double opacity = 1,
    double blur = 0,
    StrokeBlend blend = StrokeBlend.normal,
    StrokeTexture texture = StrokeTexture.none,
    bool taper = false,
    Fill? fill,
  }) {
    final pts = densify(corners, 4);
    final usePen = taper && brush.thinning == 0;
    final b = usePen ? BrushType.pen : brush;
    strokes.add(Stroke(
      brush: b,
      color: fill?.color ?? color,
      // Full pressure makes the line (1 + thinning) times as wide.
      size: width / b.sizeFactor / (taper ? 1 + b.thinning : 1),
      opacity: opacity,
      usesRealPressure: taper,
      seed: _seed++,
      gradient: fill?.gradientIn(boxOf(pts)),
      blur: blur,
      blend: blend,
      texture: texture,
      isComplete: true,
      points: [
        for (final (i, p) in pts.indexed)
          PointVector(p.dx, p.dy,
              taper ? math.sin(math.pi * (i + 0.5) / pts.length) : 0.5),
      ],
    ));
  }

  /// A line through [corners] that bends smoothly.
  void curveLine(List<Offset> corners, Color color,
          {double width = 3,
          BrushType brush = BrushType.marker,
          double opacity = 1,
          double blur = 0,
          StrokeBlend blend = StrokeBlend.normal,
          StrokeTexture texture = StrokeTexture.none,
          bool taper = false,
          Fill? fill}) =>
      line(spline(corners), color,
          width: width,
          brush: brush,
          opacity: opacity,
          blur: blur,
          blend: blend,
          texture: texture,
          taper: taper,
          fill: fill);

  /// The blender along a smooth curve through [corners]: softens and mixes
  /// what's painted under a band [width] wide, as much as [strength].
  void smudge(List<Offset> corners,
      {double width = 20, double strength = 0.8}) {
    final pts = densify(spline(corners), 3);
    strokes.add(Stroke(
      brush: BrushType.smudge,
      color: const Color(0xFF000000),
      size: width / BrushType.smudge.sizeFactor,
      opacity: strength,
      usesRealPressure: true,
      seed: _seed++,
      blur: width * 0.2,
      isComplete: true,
      points: [for (final p in pts) PointVector(p.dx, p.dy, 0.5)],
    ));
  }

  /// The blender over the whole area [outline] goes around: colors spread
  /// about [radius] pixels, softer toward the edge.
  void smudgeArea(List<Offset> outline,
      {double radius = 4, double strength = 1}) {
    final pts = densify([...outline, outline.first], 3);
    // The blender's reach is 0.3 of its width (see Stroke.smudgeRadius).
    final width = radius / 0.3;
    strokes.add(Stroke(
      brush: BrushType.smudge,
      color: const Color(0xFF000000),
      size: width / BrushType.smudge.sizeFactor,
      opacity: strength,
      usesRealPressure: false,
      seed: _seed++,
      fill: true,
      blur: radius,
      isComplete: true,
      points: [for (final p in pts) PointVector(p.dx, p.dy, 0.5)],
    ));
  }

  void stamp(StampShape kind, Offset at, Color color, {double width = 24}) =>
      strokes.add(Stroke(
        brush: BrushType.stamp,
        color: color,
        size: width / BrushType.stamp.sizeFactor,
        usesRealPressure: false,
        seed: _seed++,
        stamp: kind,
        points: [PointVector(at.dx, at.dy, 0.5)],
        isComplete: true,
      ));

  /// Airbrush dots along [pts].
  void spray(List<Offset> pts, Color color,
          {double width = 20, double opacity = 1}) =>
      line(pts, color,
          width: width, brush: BrushType.spray, opacity: opacity);

  /// Centered text whose top is at [top].
  void text(String words, Offset top, Color color,
          {double size = 32, String? font, bool bold = false}) =>
      strokes.add(Stroke.text(
        anchor: top,
        content: TextContent(
          text: words,
          fontFamily: font,
          fontSize: size,
          bold: bold,
          align: TextAlign.center,
        ),
        color: color,
      ));

  /// How wide [words] are once drawn by [text].
  static double textWidth(String words, {double size = 32, String? font}) {
    final painter = TextPainter(
      text: TextSpan(
        text: words,
        style: TextContent(fontFamily: font, fontSize: size)
            .style(const Color(0xFF000000)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// Points on a circle's arc, angles in degrees counterclockwise from
  /// the right (as in math, with y pointing down on screen).
  List<Offset> arc(Offset center, double r, double from, double to,
          {int steps = 40}) =>
      [
        for (var i = 0; i <= steps; i++)
          center +
              Offset.fromDirection(
                  -(from + (to - from) * i / steps) * math.pi / 180, r),
      ];

  /// Points on a cubic Bézier curve.
  List<Offset> curve(Offset p0, Offset c1, Offset c2, Offset p3,
      {int steps = 24}) {
    Offset at(double t) {
      final s = 1 - t;
      return p0 * (s * s * s) +
          c1 * (3 * s * s * t) +
          c2 * (3 * s * t * t) +
          p3 * (t * t * t);
    }

    return [for (var i = 0; i <= steps; i++) at(i / steps)];
  }

  /// A smooth curve through every one of [corners] (Catmull-Rom), with a
  /// point every few pixels.
  static List<Offset> spline(List<Offset> corners, {bool closed = false}) {
    final n = corners.length;
    if (n < 3) return corners;
    Offset at(int i) => closed
        ? corners[(i % n + n) % n]
        : corners[i.clamp(0, n - 1)];
    final out = <Offset>[];
    final segments = closed ? n : n - 1;
    for (var i = 0; i < segments; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final steps = math.max(2, ((p2 - p1).distance / 3).ceil());
      for (var k = 0; k < steps; k++) {
        final t = k / steps, t2 = t * t, t3 = t2 * t;
        out.add((p1 * 2 +
                (p2 - p0) * t +
                (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2 +
                (p1 * 3 - p0 - p2 * 3 + p3) * t3) *
            0.5);
      }
    }
    if (!closed) out.add(corners.last);
    return out;
  }

  /// The outline of a limb or anything tube-like: around [spine], [widths]
  /// wide at each of its points.
  static List<Offset> tube(List<Offset> spine, List<double> widths) {
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < spine.length; i++) {
      final a = spine[math.max(0, i - 1)], b = spine[math.min(spine.length - 1, i + 1)];
      final d = b - a;
      final n = Offset(-d.dy, d.dx) / d.distance;
      left.add(spine[i] + n * (widths[i] / 2));
      right.add(spine[i] - n * (widths[i] / 2));
    }
    return [...left, ...right.reversed];
  }

  /// [pts] with extra points so none are more than [spacing] apart.
  static List<Offset> densify(List<Offset> pts, double spacing) {
    final out = <Offset>[];
    for (var i = 0; i + 1 < pts.length; i++) {
      final a = pts[i], b = pts[i + 1];
      final steps = math.max(1, ((b - a).distance / spacing).ceil());
      for (var k = 0; k < steps; k++) {
        out.add(Offset.lerp(a, b, k / steps)!);
      }
    }
    out.add(pts.last);
    return out;
  }

  static Rect boxOf(List<Offset> pts) {
    var r = Rect.fromPoints(pts.first, pts.first);
    for (final p in pts) {
      r = r.expandToInclude(Rect.fromPoints(p, p));
    }
    return r;
  }
}
