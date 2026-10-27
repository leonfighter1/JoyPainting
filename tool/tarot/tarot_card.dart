import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

/// A tarot card made of the app's own strokes (shapes, free shapes,
/// brushes, gradients, soft edges, light and shadow, text), so it opens,
/// moves, recolors and erases like anything drawn by hand.
///
/// Every card shares one frame (see [TarotFrame]); a card only brings its
/// number, names, keywords and the scene inside the arched window.
class TarotCard {
  const TarotCard({
    required this.number,
    required this.numeral,
    required this.zh,
    required this.en,
    required this.keywords,
    required this.scene,
  });

  final int number;

  /// What the medallion shows: '0', 'I', 'II', ...
  final String numeral;
  final String zh;
  final String en;
  final List<String> keywords;

  /// Paints the picture. It may spill past the window; the frame covers it.
  final void Function(Artist a) scene;

  static const size = Size(700, 1200);
  static const paper = Color(0xFFFFFFFF);

  /// "00 愚人 The Fool": sorts in deck order.
  String get fileName => '${number.toString().padLeft(2, '0')} $zh $en';

  List<Stroke> strokes() {
    final a = Artist();
    scene(a);
    TarotFrame.draw(a, this);
    return a.strokes;
  }

  PaintingDoc doc(DateTime now) {
    final all = strokes();
    return PaintingDoc(
      meta: PaintingMeta(
        id: 'tarot-$number',
        name: '塔罗 $numeral · $zh $en',
        createdAt: now,
        updatedAt: now,
        width: size.width,
        height: size.height,
        strokeCount: all.length,
      ),
      strokes: all,
      paper: paper,
      // The paper is exactly the card: no margin around it, in the app or
      // in pictures made from it.
      paperSize: size,
    );
  }
}

/// The deck's shared look: a night-blue card, a gold arched window for the
/// picture, the number on a medallion at the top and the names below.
abstract final class TarotFrame {
  static const navy = Color(0xFF1E2546);
  static const gold = Color(0xFFE4BC62);
  static const goldDeep = Color(0xFFB58A35);
  static const goldPale = Color(0xFFF7E3A8);
  static const cream = Color(0xFFFFF6E3);

  /// Polished gold: pale where the light catches it, deeper at the ends.
  static Fill goldAcross(double x0, double x1) => Fill.linear(
        Offset(x0, 0),
        Offset(x1, 0),
        const [goldDeep, goldPale, gold, goldPale, goldDeep],
      );

  /// The picture window: straight sides and bottom, a half-circle on top.
  static const window = Rect.fromLTRB(48, 130, 652, 930);
  static const archCenter = Offset(350, 432);
  static const archRadius = 302.0;

  static const titleFont = 'ZCOOLQingKeHuangYou';
  static const textFont = 'ZCOOLKuaiLe';

  static void draw(Artist a, TarotCard card) {
    final w = window;
    // Navy mats around the window hide whatever the scene spilled; the top
    // one is cut along the arch.
    a.rect(const Rect.fromLTRB(0, 930, 700, 1200), navy);
    a.rect(const Rect.fromLTRB(0, 430, 48, 1200), navy);
    a.rect(const Rect.fromLTRB(652, 430, 700, 1200), navy);
    a.area([
      const Offset(0, 0), const Offset(700, 0), const Offset(700, 436),
      Offset(w.right, 436),
      ...a.arc(archCenter, archRadius, 0, 180, steps: 120),
      Offset(w.left, 436), const Offset(0, 436),
    ], const Fill(navy), spacing: 2);

    // A soft glow behind the names.
    a.glow(const Offset(350, 1040), 250, gold.withValues(alpha: 0.12),
        squash: 0.44);

    // Borders.
    a.box(const Rect.fromLTRB(16, 16, 684, 1184), gold, width: 3);
    a.box(const Rect.fromLTRB(26, 26, 674, 1174), goldDeep, width: 1.2);
    a.box(const Rect.fromLTRB(40, 122, 660, 938), goldDeep, width: 1.5);
    for (final c in const [
      Offset(26, 26), Offset(674, 26), Offset(26, 1174), Offset(674, 1174), //
    ]) {
      a.diamond(c, 9, gold);
    }

    // The window's gold frame.
    final frame = goldAcross(w.left, w.right);
    a.line([w.bottomLeft, Offset(w.left, archCenter.dy)], gold, width: 6,
        fill: frame);
    a.line([w.bottomRight, Offset(w.right, archCenter.dy)], gold, width: 6,
        fill: frame);
    a.line([w.bottomLeft, w.bottomRight], gold, width: 6, fill: frame);
    a.line(a.arc(archCenter, archRadius, 0, 180, steps: 120), gold,
        width: 6, fill: frame);
    a.line(a.arc(archCenter, archRadius - 9, 0, 180, steps: 120), goldPale,
        width: 1.2, opacity: 0.6);

    // Moon and star in the top corners, with a few small stars.
    a.oval(const Offset(100, 182), 26, 26, Fill.radial(
        const Offset(92, 174), 34, const [goldPale, gold, goldDeep]));
    a.oval(const Offset(111, 174), 22, 22, const Fill(navy));
    a.oval(const Offset(600, 182), 30, 30, Fill.radial(const Offset(600, 182),
        30, [goldPale.withValues(alpha: 0.35), goldPale.withValues(alpha: 0)]));
    a.star(const Offset(600, 182), 24, gold);
    for (final (p, r) in const [
      (Offset(150, 152), 7.0), (Offset(72, 262), 6.0), (Offset(160, 222), 4.0),
      (Offset(550, 152), 7.0), (Offset(628, 262), 6.0), (Offset(540, 222), 4.0),
    ]) {
      a.star(p, r, goldPale);
    }

    // Medallion with the number, sitting on top of the arch.
    for (final (x0, x1) in const [(110.0, 296.0), (404.0, 590.0)]) {
      a.line([Offset(x0, 76), Offset(x1, 76)], gold, width: 1.5,
          fill: goldAcross(x0, x1));
    }
    a.diamond(const Offset(104, 76), 6, gold);
    a.diamond(const Offset(596, 76), 6, gold);
    a.oval(const Offset(350, 82), 47, 47, Fill.linear(const Offset(310, 40),
        const Offset(390, 124), const [goldPale, gold, goldDeep]));
    a.oval(const Offset(350, 82), 43, 43, Fill.radial(const Offset(340, 70),
        50, const [Color(0xFF34407A), navy]));
    a.ring(const Offset(350, 82), 37, goldDeep, width: 1);
    a.text(card.numeral, const Offset(350, 48), gold,
        size: 50, font: titleFont);

    // Names and keywords.
    a.text(card.zh, const Offset(350, 952), gold, size: 64, font: titleFont);
    a.text(card.en.toUpperCase().split('').join(' '), const Offset(350, 1036),
        goldPale, size: 24, font: titleFont);
    a.line([const Offset(190, 1090), const Offset(320, 1090)], gold,
        width: 1.5, fill: goldAcross(190, 320));
    a.line([const Offset(380, 1090), const Offset(510, 1090)], gold,
        width: 1.5, fill: goldAcross(380, 510));
    a.diamond(const Offset(184, 1090), 5, gold);
    a.diamond(const Offset(516, 1090), 5, gold);
    a.star(const Offset(350, 1090), 13, gold);
    _keywords(a, card.keywords, top: 1110);
  }

  /// The keywords in a centered row with small gold diamonds between them
  /// (the fonts' middle dots look like stray ticks).
  static void _keywords(Artist a, List<String> words, {required double top}) {
    const size = 26.0, gap = 40.0;
    final widths = [
      for (final w in words) Artist.textWidth(w, size: size, font: textFont),
    ];
    final total =
        widths.fold(0.0, (sum, w) => sum + w) + gap * (words.length - 1);
    var x = 350 - total / 2;
    for (final (i, word) in words.indexed) {
      if (i > 0) {
        a.diamond(Offset(x - gap / 2, top + size * 0.66), 5, gold);
      }
      a.text(word, Offset(x + widths[i] / 2, top), cream,
          size: size, font: textFont);
      x += widths[i] + gap;
    }
  }
}

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
    double opacity = 1,
  }) =>
      _shape(ShapeKind.ellipse,
          Rect.fromCenter(center: c, width: rx * 2, height: ry * 2), fill,
          angle: angle, blur: blur, blend: blend, opacity: opacity);

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
      gradient: fill.gradientIn(_boxOf(pts)),
      blur: blur,
      blend: blend,
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
    double opacity = 1,
  }) =>
      area(spline(corners, closed: true), fill,
          blur: blur, blend: blend, opacity: opacity);

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
      gradient: fill?.gradientIn(_boxOf(pts)),
      blur: blur,
      blend: blend,
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
          bool taper = false,
          Fill? fill}) =>
      line(spline(corners), color,
          width: width,
          brush: brush,
          opacity: opacity,
          blur: blur,
          blend: blend,
          taper: taper,
          fill: fill);

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

  static Rect _boxOf(List<Offset> pts) {
    var r = Rect.fromPoints(pts.first, pts.first);
    for (final p in pts) {
      r = r.expandToInclude(Rect.fromPoints(p, p));
    }
    return r;
  }
}
