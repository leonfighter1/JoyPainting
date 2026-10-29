// The advanced coloring pages (for about age 18): detailed line art with
// many areas, the smallest still big enough for the paint bucket. Each
// draws front to back with a [Pen], so lines stop where they go behind
// something.
import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../samples/artist.dart';
import 'pen.dart';

part 'pages_adv_garden.dart';
part 'pages_adv_more.dart';

const _w = 4.0;
const _d = 2.6;

void drawAdv(String name, Pen p) {
  p.width = _w;
  switch (name) {
    case 'mandala':
      _mandala(p);
    case 'koi':
      _koiPond(p);
    case 'pavilion':
      _pavilion(p);
    case 'peacock':
      _peacock(p);
    case 'teaset':
      _teaset(p);
    case 'street':
      _street(p);
    default:
      throw ArgumentError(name);
  }
}

Offset _polar(Offset c, double r, double deg) =>
    c + Offset.fromDirection(deg * math.pi / 180, r);

/// A petal round [c] from radius [r0] out to [r1], centred on angle [a]
/// (degrees), [half] degrees wide each side at its base: pointed, or
/// rounded at the tip if [round].
List<Offset> _petal(Offset c, double a, double r0, double r1, double half,
    {bool round = false, double belly = 1}) {
  Offset at(double t, double side) => _polar(c, r0 + (r1 - r0) * t, a + side);
  final left = [at(0, -half), at(0.4, -half * belly), at(0.76, -half * 0.6 * belly)];
  final right = [at(0.76, half * 0.6 * belly), at(0.4, half * belly), at(0, half)];
  final tip = at(1, 0);
  return round
      ? Artist.spline([...left, tip, ...right])
      : Pen.joined([
          [...left, tip],
          [tip, ...right],
        ]);
}

/// A rosette: a middle, a ring of round petals with drops in them, a
/// ring of beads; [r] across. Used in the mandala page's corners.
void _rosette(Pen p, Offset c, double r, int petals) {
  p.circle(c, r * 0.18);
  for (var i = 0; i < petals; i++) {
    final a = i * 360 / petals;
    p.shape(_petal(c, a, r * 0.3, r * 0.55, 90 / petals, round: true), width: _d);
    p.shape(_petal(c, a, r * 0.18, r * 0.72, 180 / petals, round: true));
  }
  p.circle(c, r * 0.78);
  for (var i = 0; i < petals * 2; i++) {
    p.circle(_polar(c, r * 0.86, (i + 0.5) * 180 / petals), r * 0.06, width: _d);
  }
  p.circle(c, r * 0.94);
}

void _mandala(Pen p) {
  const c = Offset(400, 500);
  // The middle: a little flower in a ring.
  p.circle(c, 9, width: _d);
  for (var i = 0; i < 6; i++) {
    p.shape(_petal(c, i * 60.0, 9, 24, 26, round: true), width: _d);
  }
  p.circle(c, 28);
  // Eight round petals, each with a drop inside.
  for (var i = 0; i < 8; i++) {
    p.shape(_petal(c, i * 45.0, 38, 64, 8, round: true), width: _d);
    p.shape(_petal(c, i * 45.0, 28, 78, 22.5, round: true));
  }
  p.circle(c, 84);
  // Sixteen pointed petals with a vein each.
  for (var i = 0; i < 16; i++) {
    final a = 11.25 + i * 22.5;
    p.path([_polar(c, 94, a), _polar(c, 128, a)], width: _d);
    p.shape(_petal(c, a, 84, 142, 11.25));
  }
  p.circle(c, 148);
  // A ring of beads.
  for (var i = 0; i < 24; i++) {
    p.circle(_polar(c, 159, i * 15.0), 7.5, width: _d);
  }
  p.circle(c, 170);
  // Twelve lotus petals with a petal and a drop inside, and pointed
  // petals behind, in the gaps.
  for (var i = 0; i < 12; i++) {
    final a = i * 30.0;
    p.shape(_petal(c, a, 200, 234, 4, round: true), width: _d);
    p.shape(_petal(c, a, 178, 252, 10.5, round: true), width: _d);
    p.shape(_petal(c, a, 170, 266, 15, round: true));
  }
  for (var i = 0; i < 12; i++) {
    p.shape(_petal(c, 15 + i * 30.0, 170, 240, 8.5));
  }
  // A scalloped band with a dot in each scallop.
  p.circle(c, 274);
  for (var i = 0; i < 36; i++) {
    final a = i * 10.0 + 5;
    p.circle(_polar(c, 284, a), 6, width: _d);
    p.shape([
      _polar(c, 270, a - 5),
      ...Pen.arc(_polar(c, 274, a), 274 * math.sin(5 * math.pi / 180), a - 90, a + 90),
      _polar(c, 270, a + 5),
    ]);
  }
  // Pointed leaves behind it, each with a midrib, and beads between.
  for (var i = 0; i < 24; i++) {
    final a = i * 15.0;
    p.path([_polar(c, 300, a), _polar(c, 340, a)], width: _d);
    p.shape(_petal(c, a, 280, 356, 7));
    p.circle(_polar(c, 340, a + 7.5), 5, width: _d);
  }
  // Rosettes in the corners and at the edges.
  for (final corner in const [Offset(0, 0), Offset(800, 0), Offset(0, 1000), Offset(800, 1000)]) {
    _rosette(p, corner, 150, 16);
  }
  for (final at in const [Offset(400, 62), Offset(400, 938)]) {
    _rosette(p, at, 58, 8);
  }
  for (final at in const [Offset(0, 500), Offset(800, 500)]) {
    _rosette(p, at, 44, 8);
  }
}

/// A koi along [spine] (head first), [fat] wide at its widest.
void _koi(Pen p, List<Offset> spine, double fat) {
  final s = Artist.spline(spine);
  final n = s.length;
  double w(double t) =>
      (t < 0.3 ? 0.5 + 0.5 * math.sin(t / 0.3 * math.pi / 2) : 1 - 0.74 * math.pow((t - 0.3) / 0.7, 1.25)) * fat;
  int index(double t) => (t * (n - 1)).round().clamp(0, n - 1);
  Offset at(double t) => s[index(t)];
  Offset dir(double t) {
    final a = s[math.max(0, index(t) - 3)], b = s[math.min(n - 1, index(t) + 3)];
    return (b - a) / (b - a).distance;
  }

  Offset side(double t) => Offset(-dir(t).dy, dir(t).dx);
  double deg(Offset v) => math.atan2(v.dy, v.dx) * 180 / math.pi;

  // Barbels, eyes, the ridge of the back fin, scales, the gill line.
  for (final k in [-1.0, 1.0]) {
    p.curve([at(0.01) + side(0.01) * (k * 8), at(0) - dir(0) * 10 + side(0) * (k * 16), at(0) - dir(0) * 8 + side(0) * (k * 26)], width: _d);
    p.circle(at(0.09) + side(0.09) * (k * w(0.09) * 0.32), 6.5, width: _d);
  }
  p.shape(Pen.joined([
    [at(0.3), at(0.45) + side(0.45) * 4, at(0.62) + side(0.62) * 3, at(0.7)],
    [at(0.7), at(0.62) - side(0.62) * 3, at(0.45) - side(0.45) * 4, at(0.3)],
  ]), width: _d);
  for (var row = 0; row < 13; row++) {
    final t = 0.27 + row * 0.045;
    final half = w(t) / 2 - 13;
    for (var k = -half + (row.isOdd ? 9 : 0); k <= half; k += 18) {
      final c = at(t) + side(t) * k - dir(t) * 9;
      final a = deg(dir(t));
      p.path(Pen.arc(c, 11, a - 70, a + 70), width: _d - 0.4);
    }
  }
  p.curve([at(0.19) + side(0.19) * (w(0.19) / 2), at(0.24), at(0.19) - side(0.19) * (w(0.19) / 2)], width: _d);
  // The body, rounded at the head.
  final back = s.reversed.toList();
  p.shape(Pen.rounded(Artist.tube(back, [for (var i = 0; i < n; i++) w(1 - i / (n - 1))])));
  // Fins under it: the side fins with their rays, then the tail.
  for (final k in [-1.0, 1.0]) {
    for (final (t, size) in [(0.26, 58.0), (0.56, 38.0)]) {
      final base = at(t) + side(t) * (k * w(t) * 0.4);
      final tip = base + side(t) * (k * size) + dir(t) * (size * 0.55);
      final rear = at(t + 0.07) + side(t + 0.07) * (k * w(t + 0.07) * 0.4);
      for (final f in [0.35, 0.65]) {
        p.path([base, Offset.lerp(tip, rear, f)! + (tip - base) * 0.05], width: _d - 0.6);
      }
      p.shape(Pen.joined([
        [base, base + (tip - base) * 0.5 + dir(t) * -6, tip],
        [tip, Offset.lerp(tip, rear, 0.5)! + side(t) * (k * 6), rear],
      ]));
    }
  }
  final tail = at(1), d = dir(0.97), sd = side(0.97);
  for (final k in [-30.0, -12.0, 12.0, 30.0]) {
    p.path([tail, tail + d * 78 + sd * k], width: _d - 0.6);
  }
  p.shape(Pen.joined([
    [tail + sd * 12, tail + d * 40 + sd * 40, tail + d * 96 + sd * 54],
    [tail + d * 96 + sd * 54, tail + d * 76 + sd * 18, tail + d * 56],
    [tail + d * 56, tail + d * 76 - sd * 18, tail + d * 96 - sd * 54],
    [tail + d * 96 - sd * 54, tail + d * 40 - sd * 40, tail - sd * 12],
  ]));
}

/// A lotus flower opening at [c] (where its petals start), [s] times the
/// size of the big one, front petals first.
void _lotus(Pen p, Offset c, double s, {double? width}) {
  void petal(double angle, double len, double across, Offset from) {
    final base = c + from * s;
    final d = Offset(math.sin(angle * math.pi / 180), -math.cos(angle * math.pi / 180)) * (len * s);
    final n = Offset(-d.dy, d.dx) / d.distance * (across * s);
    final tip = base + d;
    p.path([base + d * 0.15, base + d * 0.78], width: _d - 0.6);
    p.shape(Pen.joined([
      [base - n * 0.15, base + d * 0.32 - n * 0.48, base + d * 0.72 - n * 0.4, tip],
      [tip, base + d * 0.72 + n * 0.4, base + d * 0.32 + n * 0.48, base + n * 0.15],
    ]), width: width);
  }

  petal(0, 110, 66, Offset.zero);
  petal(-30, 104, 60, const Offset(-14, 4));
  petal(30, 104, 60, const Offset(14, 4));
  petal(-12, 140, 58, const Offset(-6, -4));
  petal(12, 140, 58, const Offset(6, -4));
  petal(-56, 100, 58, const Offset(-22, 8));
  petal(56, 100, 58, const Offset(22, 8));
  petal(-84, 92, 50, const Offset(-26, 14));
  petal(84, 92, 50, const Offset(26, 14));
}

/// A lily pad: an ellipse with a notch cut in, and veins from the middle.
void _pad(Pen p, Offset c, double rx, double ry, double notch) {
  final ring = Pen.ovalPoints(c, rx, ry);
  for (var i = 0; i < 9; i++) {
    final a = notch + 25 + i * 35;
    if (a > notch + 340) break;
    p.path([c, c + Offset(rx * math.cos(a * math.pi / 180), ry * math.sin(a * math.pi / 180)) * 0.92], width: _d - 0.4);
  }
  bool cut(Offset q) {
    var a = math.atan2((q.dy - c.dy) / ry, (q.dx - c.dx) / rx) * 180 / math.pi - notch;
    while (a > 180) {
      a -= 360;
    }
    while (a < -180) {
      a += 360;
    }
    return a.abs() < 9;
  }

  final start = ring.indexWhere(cut);
  final outer = [
    for (var i = 0; i < ring.length; i++)
      if (!cut(ring[(start + i) % ring.length])) ring[(start + i) % ring.length],
  ];
  p.shape([c, ...outer]);
}

/// Rings spreading on the water round [c].
void _ripples(Pen p, Offset c, double rx, double ry, int rings) {
  for (var i = 1; i <= rings; i++) {
    p.shape(Pen.ovalPoints(c, rx + i * 22, ry + i * 9), width: _d - 0.6, covers: false);
  }
}

void _koiPond(Pen p) {
  // A dragonfly over the water.
  {
    const c = Offset(330, 170);
    p.circle(c + const Offset(-36, -12), 8, width: _d);
    p.shape(Pen.rounded(Pen.tube(const [Offset(298, 160), Offset(340, 172), Offset(410, 196)], (t) => 12 - 6 * t)), width: _d);
    for (final (a, len) in [(-85.0, 92.0), (-55.0, 84.0), (125.0, 92.0), (95.0, 84.0)]) {
      final tip = _polar(c, len, a);
      p.shape(Pen.ovalPoints((c + tip) / 2, len / 2, 13, angle: a * math.pi / 180), width: _d);
    }
  }
  // Petals fallen on the water.
  for (final (x, y, a) in [(160.0, 330.0, 0.5), (660.0, 520.0, -0.4), (430.0, 900.0, 1.1)]) {
    p.shape(Pen.joined([
      [Offset(x - 22, y), Offset(x - 6, y - 12), Offset(x + 22, y - 4)],
      [Offset(x + 22, y - 4), Offset(x + 2, y + 10), Offset(x - 22, y)],
    ].map((piece) => [for (final q in piece) Offset(x, y) + _turn(q - Offset(x, y), a)]).toList()), width: _d);
  }
  // Lotus flowers and a bud, on their pads, over the fish.
  _lotus(p, const Offset(580, 300), 1);
  _pad(p, const Offset(580, 330), 180, 72, 70);
  _lotus(p, const Offset(170, 800), 0.62);
  _pad(p, const Offset(160, 830), 140, 56, 110);
  p.path(const [Offset(706, 760), Offset(700, 820)], width: _w);
  p.shape(Pen.joined(const [
    [Offset(704, 760), Offset(680, 730), Offset(684, 690), Offset(706, 650)],
    [Offset(706, 650), Offset(728, 690), Offset(730, 730), Offset(704, 760)],
  ]));
  p.curve(const [Offset(700, 755), Offset(694, 712), Offset(706, 650)], width: _d);
  _pad(p, const Offset(720, 850), 110, 44, 200);
  _pad(p, const Offset(110, 150), 120, 48, 30);
  _pad(p, const Offset(760, 120), 90, 36, 160);
  // Two koi circling under them.
  _koi(p, const [Offset(150, 350), Offset(232, 428), Offset(300, 524), Offset(328, 626), Offset(306, 720)], 100);
  _koi(p, const [Offset(660, 740), Offset(576, 684), Offset(518, 598), Offset(500, 500), Offset(522, 416)], 92);
  // Ripples on the water.
  _ripples(p, const Offset(580, 330), 180, 72, 2);
  _ripples(p, const Offset(160, 830), 140, 56, 2);
  for (final (x, y) in [(420.0, 420.0), (640.0, 960.0), (300.0, 960.0), (740.0, 420.0), (420.0, 60.0), (90.0, 560.0), (400.0, 620.0), (720.0, 560.0), (220.0, 250.0), (560.0, 840.0)]) {
    p.curve([Offset(x - 30, y), Offset(x - 15, y - 5), Offset(x, y), Offset(x + 15, y + 5), Offset(x + 30, y)], width: _d - 0.4);
  }
}

Offset _turn(Offset v, double a) =>
    Offset(v.dx * math.cos(a) - v.dy * math.sin(a), v.dx * math.sin(a) + v.dy * math.cos(a));

/// A leafy crown: a ball of leaves with smaller ones behind it.
void _crown(Pen p, Offset c, double r, {double? width}) {
  p.circle(c, r, width: width);
  for (final a in [-160.0, -122.0, -86.0, -52.0, -18.0, 16.0, 164.0]) {
    p.circle(c + Offset.fromDirection(a * math.pi / 180, r * 0.8), r * 0.5, width: width);
  }
}

