import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import '../drawing/stroke.dart';
import '../l10n.dart';

/// The painting every kid finds in My Paintings to begin with: a sunny day
/// with a rainbow, a house on the hill, an apple tree and a girl flying a
/// kite. It's made of the app's own brushes and shapes, so it opens,
/// moves, recolors and erases like anything a kid drew.
class SamplePainting {
  static const size = Size(1200, 800);
  static const paper = Color(0xFFDDF1FF);

  /// The strokes, back to front. [s] gives the sun's greeting.
  static List<Stroke> strokes(S s) => _Builder().build(s);
}

class _Builder {
  final _out = <Stroke>[];
  var _seed = 1;

  void shape(
    ShapeKind kind,
    Rect box,
    Color color, {
    bool fill = true,
    double size = 3,
    double angle = 0,
  }) {
    _out.add(
      Stroke.shape(
        shape: kind,
        from: box.topLeft,
        to: box.bottomRight,
        brush: BrushType.pen,
        color: color,
        size: size,
        fill: fill,
        seed: _seed++,
        transform: angle == 0
            ? null
            : StrokeTransform.around(box.center, angle: angle),
        isComplete: true,
      ),
    );
  }

  void oval(double cx, double cy, double rx, double ry, Color color) => shape(
    ShapeKind.ellipse,
    Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
    color,
  );

  /// A freehand stroke through [corners], with a point every few pixels as
  /// a hand would make.
  void line(
    List<Offset> corners,
    Color color, {
    BrushType brush = BrushType.pen,
    double size = 4,
    double opacity = 1,
  }) {
    final points = <PointVector>[];
    for (var i = 0; i < corners.length - 1; i++) {
      final a = corners[i], b = corners[i + 1];
      final steps = math.max(1, ((b - a).distance / 4).ceil());
      for (var k = 0; k < steps; k++) {
        final p = Offset.lerp(a, b, k / steps)!;
        points.add(PointVector(p.dx, p.dy, 0.5));
      }
    }
    points.add(PointVector(corners.last.dx, corners.last.dy, 0.5));
    _out.add(
      Stroke(
        brush: brush,
        color: color,
        size: size,
        opacity: opacity,
        usesRealPressure: false,
        seed: _seed++,
        points: points,
        isComplete: true,
      ),
    );
  }

  /// Points on a circle's arc, angles in degrees counterclockwise from
  /// the right (as in math, with y pointing down on screen).
  List<Offset> arc(
    Offset center,
    double r,
    double from,
    double to, {
    int steps = 40,
  }) => [
    for (var i = 0; i <= steps; i++)
      center +
          Offset.fromDirection(
            -(from + (to - from) * i / steps) * math.pi / 180,
            r,
          ),
  ];

  void stamp(StampShape kind, Offset at, Color color, {double size = 12}) =>
      _out.add(
        Stroke(
          brush: BrushType.stamp,
          color: color,
          size: size,
          usesRealPressure: false,
          seed: _seed++,
          stamp: kind,
          points: [PointVector(at.dx, at.dy, 0.5)],
          isComplete: true,
        ),
      );

  List<Stroke> build(S s) {
    const brown = Color(0xFF6D4C41);
    // Rainbow, behind everything: its feet disappear behind the hills.
    const bands = [
      Color(0xFFEF5350), Color(0xFFFFA726), Color(0xFFFFEE58), //
      Color(0xFF66BB6A), Color(0xFF42A5F5), Color(0xFFAB47BC),
    ];
    for (final (i, color) in bands.indexed) {
      line(
        arc(const Offset(600, 720), 420 - i * 17.0, 10, 170, steps: 60),
        color,
        brush: BrushType.marker,
        size: 15,
        opacity: 0.8,
      );
    }

    // The sun, smiling, with its rays.
    const sun = Offset(1010, 140);
    for (var i = 0; i < 12; i++) {
      final d = Offset.fromDirection(i * math.pi / 6);
      line([sun + d * 88, sun + d * 120], const Color(0xFFFFB300), size: 6);
    }
    oval(sun.dx, sun.dy, 72, 72, const Color(0xFFFFD54F));
    oval(sun.dx - 24, sun.dy - 14, 7, 9, brown);
    oval(sun.dx + 24, sun.dy - 14, 7, 9, brown);
    oval(sun.dx - 42, sun.dy + 14, 12, 8, const Color(0x99FF8A80));
    oval(sun.dx + 42, sun.dy + 14, 12, 8, const Color(0x99FF8A80));
    line(arc(sun + const Offset(0, 4), 28, 200, 340), brown, size: 5);

    // Clouds.
    for (final (cx, cy, k) in [(250.0, 140.0, 1.0), (640.0, 95.0, 0.7)]) {
      oval(cx - 70 * k, cy + 10 * k, 60 * k, 36 * k, Colors.white);
      oval(cx, cy - 10 * k, 66 * k, 48 * k, Colors.white);
      oval(cx + 70 * k, cy + 12 * k, 58 * k, 34 * k, Colors.white);
      oval(cx, cy + 22 * k, 120 * k, 28 * k, Colors.white);
    }

    // Birds.
    for (final (x, y) in [(470.0, 215.0), (520.0, 185.0), (430.0, 250.0)]) {
      line(
        [
          ...arc(Offset(x - 11, y + 6), 12, 160, 40, steps: 8),
          ...arc(Offset(x + 11, y + 6), 12, 140, 20, steps: 8),
        ],
        const Color(0xFF546E7A),
        size: 3,
      );
    }

    // Hills and the meadow.
    shape(
      ShapeKind.ellipse,
      const Rect.fromLTRB(0, 470, 760, 800),
      const Color(0xFFAED581),
    );
    shape(
      ShapeKind.ellipse,
      const Rect.fromLTRB(470, 500, 1200, 800),
      const Color(0xFF9CCC65),
    );
    shape(
      ShapeKind.rectangle,
      const Rect.fromLTRB(0, 650, 1200, 800),
      const Color(0xFF7CB342),
    );
    line(
      [for (var x = 12.0; x <= 1188; x += 12) Offset(x, 652 + (x % 36) / 6)],
      const Color(0xFF558B2F),
      brush: BrushType.spray,
      size: 6,
      opacity: 0.7,
    );

    // The house, with a smoking chimney.
    shape(
      ShapeKind.rectangle,
      const Rect.fromLTRB(935, 470, 962, 540),
      const Color(0xFFBCAAA4),
    );
    // Soft puffs of smoke, drifting up and to the right.
    for (final (x, y, r) in [
      (952.0, 448.0, 9.0),
      (962.0, 422.0, 12.0),
      (976.0, 392.0, 15.0),
    ]) {
      shape(
        ShapeKind.ellipse,
        Rect.fromCircle(center: Offset(x, y), radius: r),
        const Color(0xFFCFD8DC),
      );
    }
    shape(
      ShapeKind.rectangle,
      const Rect.fromLTRB(800, 560, 990, 700),
      const Color(0xFFFFF3E0),
    );
    shape(
      ShapeKind.rectangle,
      const Rect.fromLTRB(800, 560, 990, 700),
      brown,
      fill: false,
      size: 3,
    );
    shape(
      ShapeKind.triangle,
      const Rect.fromLTRB(775, 455, 1015, 565),
      const Color(0xFFE57373),
    );
    shape(
      ShapeKind.rectangle,
      const Rect.fromLTRB(870, 620, 920, 700),
      const Color(0xFF8D6E63),
    );
    oval(910, 662, 4, 4, const Color(0xFFFFD54F));
    for (final x in [818.0, 938.0]) {
      shape(
        ShapeKind.rectangle,
        Rect.fromLTWH(x, 590, 36, 36),
        const Color(0xFF81D4FA),
      );
      line([Offset(x + 18, 590), Offset(x + 18, 626)], Colors.white, size: 3);
      line([Offset(x, 608), Offset(x + 36, 608)], Colors.white, size: 3);
    }
    // Stepping stones from the door down the meadow.
    for (final (x, y, r) in [
      (895.0, 712.0, 17.0),
      (872.0, 735.0, 16.0),
      (846.0, 757.0, 15.0),
      (818.0, 778.0, 14.0),
    ]) {
      oval(x, y, r, r * 0.45, const Color(0xFFD7CCC8));
    }

    // The apple tree.
    shape(
      ShapeKind.rectangle,
      const Rect.fromLTRB(150, 560, 186, 700),
      const Color(0xFF8D6E63),
    );
    for (final (cx, cy, rx, ry) in [
      (170.0, 505.0, 80.0, 70.0),
      (115.0, 550.0, 55.0, 48.0),
      (225.0, 548.0, 55.0, 50.0),
      (168.0, 455.0, 58.0, 50.0),
    ]) {
      oval(cx, cy, rx, ry, const Color(0xFF43A047));
    }
    for (final (x, y) in [
      (130.0, 500.0),
      (200.0, 470.0),
      (215.0, 545.0),
      (150.0, 560.0),
      (95.0, 555.0),
      (175.0, 515.0),
      (250.0, 520.0),
    ]) {
      oval(x, y, 9, 9, const Color(0xFFE53935));
    }

    // The kite, its tail and string.
    shape(
      ShapeKind.triangle,
      const Rect.fromLTRB(385, 250, 445, 300),
      const Color(0xFFFF7043),
    );
    shape(
      ShapeKind.triangle,
      const Rect.fromLTRB(385, 300, 445, 375),
      const Color(0xFFFFCA28),
      angle: math.pi,
    );
    line([const Offset(415, 250), const Offset(415, 375)], brown, size: 2);
    line([const Offset(385, 300), const Offset(445, 300)], brown, size: 2);
    line(
      [
        const Offset(415, 375),
        const Offset(400, 400),
        const Offset(428, 425),
        const Offset(408, 452),
        const Offset(430, 478),
      ],
      brown,
      size: 2,
    );
    for (final (i, at) in const [
      Offset(402, 401),
      Offset(426, 426),
      Offset(410, 452),
    ].indexed) {
      stamp(StampShape.heart, at, bands[i * 2], size: 7);
    }
    line(
      [
        const Offset(415, 375),
        const Offset(395, 450),
        const Offset(380, 530),
        const Offset(366, 612),
      ],
      const Color(0xFF795548),
      brush: BrushType.pencil,
      size: 3,
    );

    // The girl flying it.
    const skin = Color(0xFFFFCC80);
    line([const Offset(310, 690), const Offset(304, 728)], brown, size: 6);
    line([const Offset(332, 690), const Offset(338, 728)], brown, size: 6);
    line([const Offset(300, 640), const Offset(280, 668)], skin, size: 7);
    line([const Offset(342, 640), const Offset(366, 612)], skin, size: 7);
    shape(
      ShapeKind.triangle,
      const Rect.fromLTRB(290, 620, 352, 698),
      const Color(0xFFEC407A),
    );
    oval(321, 596, 24, 25, skin);
    oval(321, 578, 25, 12, const Color(0xFF5D4037));
    oval(295, 594, 9, 13, const Color(0xFF5D4037));
    oval(347, 594, 9, 13, const Color(0xFF5D4037));
    oval(313, 596, 3, 4, brown);
    oval(329, 596, 3, 4, brown);
    line(arc(const Offset(321, 600), 9, 210, 330, steps: 10), brown, size: 3);

    // Flowers in the meadow.
    const petals = [
      Color(0xFFF06292),
      Color(0xFFFFCA28),
      Color(0xFFBA68C8),
      Color(0xFFFF8A65),
      Color(0xFFFFFFFF),
      Color(0xFF4FC3F7),
    ];
    final flowers = [
      (40.0, 742.0),
      (95.0, 712.0),
      (230.0, 760.0),
      (420.0, 720.0),
      (480.0, 768.0),
      (545.0, 728.0),
      (620.0, 760.0),
      (700.0, 718.0),
      (1040.0, 735.0),
      (1105.0, 768.0),
      (1160.0, 718.0),
      (250.0, 715.0),
    ];
    for (final (i, (x, y)) in flowers.indexed) {
      line(
        [Offset(x, y + 30), Offset(x + 2, y)],
        const Color(0xFF2E7D32),
        size: 4,
      );
      stamp(StampShape.flower, Offset(x, y), petals[i % petals.length]);
    }

    // The sun says hello.
    _out.add(
      Stroke.text(
        anchor: const Offset(760, 110),
        content: TextContent(
          text: s.sampleGreeting,
          fontSize: 34,
          bold: true,
          bubble: true,
        ),
        color: const Color(0xFF5D4037),
      ),
    );
    return _out;
  }
}
