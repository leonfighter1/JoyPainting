import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jingyao_paint/drawing/stroke.dart';

import 'artist.dart';
import 'nature.dart';

/// The intermediate sample, 海边的晚霞 (Sunset by the Sea): painted only
/// with what the intermediate level offers (the soft brush, gradients, free
/// shapes and opacity), to show what they can do.
abstract final class SunsetByTheSea {
  static const size = Size(1200, 800);
  static const paper = Color(0xFF2B2A5E);

  static List<Stroke> strokes() {
    final a = Artist();
    _paint(a);
    return a.strokes;
  }
}

const _horizon = 470.0;
const _sun = Offset(770, 452);

void _paint(Artist a) {
  final rnd = math.Random(7);
  _sky(a, rnd);
  _sea(a, rnd);
  _beach(a, rnd);
  _palm(a, rnd);
  _birds(a);
}

void _soft(Artist a, List<Offset> pts, Color color,
        {required double width, double opacity = 0.6}) =>
    a.curveLine(pts, color,
        width: width,
        brush: BrushType.soft,
        opacity: opacity,
        blur: BrushType.soft.blur * width,
        taper: true);

void _sky(Artist a, math.Random rnd) {
  a.area(const [Offset(0, 0), Offset(1200, 0), Offset(1200, 480),
    Offset(0, 480)], const Fill.linear(Offset(0, 0), Offset(0, 480), [
    Color(0xFF26275A), Color(0xFF5E3C7C), Color(0xFFB9527A),
    Color(0xFFEE8458), Color(0xFFFFC768),
  ], [0, 0.3, 0.58, 0.82, 1]), spacing: 6);
  // The first stars, high up where the sky is darkest.
  for (var i = 0; i < 26; i++) {
    final p = Offset(rnd.nextDouble() * 1200, 10 + rnd.nextDouble() * 120);
    a.oval(p, 1.2 + rnd.nextDouble() * 1.2, 1.2 + rnd.nextDouble() * 1.2,
        const Fill(Color(0xFFFFF6E0)), opacity: 0.4 + rnd.nextDouble() * 0.5);
  }
  // The sun's glow, then the sun, half under the sea.
  a.glow(_sun, 420, const Color(0x66FFC27A), squash: 0.6);
  a.glow(_sun, 200, const Color(0x88FFE09A), squash: 0.8);
  a.oval(_sun, 66, 66, Fill.radial(_sun + const Offset(-10, -14), 70,
      const [Color(0xFFFFFBE8), Color(0xFFFFE08A), Color(0xFFFFA24E)],
      const [0, 0.55, 1]));
  // Long clouds, purple on top and lit gold underneath.
  for (var k = 0; k < 11; k++) {
    final y = 110 + k * 30 + rnd.nextDouble() * 16;
    final x0 = rnd.nextDouble() * 900 - 100;
    final len = 220 + rnd.nextDouble() * 420 - k * 10;
    final warm = k / 10;
    final body = Nature.mix(const Color(0xFF6B4482), const Color(0xFFD9707A), warm);
    final pts = [
      Offset(x0, y), Offset(x0 + len * 0.35, y - 6 + rnd.nextDouble() * 6),
      Offset(x0 + len * 0.7, y - 4 + rnd.nextDouble() * 8), Offset(x0 + len, y),
    ];
    _soft(a, pts, body, width: 26 + rnd.nextDouble() * 30, opacity: 0.55);
    _soft(a, [for (final p in pts) p + const Offset(10, 9)],
        Nature.mix(const Color(0xFFFF9E6E), const Color(0xFFFFD58A), warm),
        width: 8 + rnd.nextDouble() * 8, opacity: 0.6);
  }
  // A dark headland far away on the left.
  a.blob(const [Offset(-20, 474), Offset(-20, 432), Offset(60, 420),
    Offset(150, 430), Offset(230, 446), Offset(320, 462), Offset(380, 474)],
      const Fill.linear(Offset(0, 420), Offset(0, 474), [
        Color(0xFF4A2F5E), Color(0xFF7A4468),
      ]));
}

void _sea(Artist a, math.Random rnd) {
  a.area(const [Offset(0, _horizon), Offset(1200, _horizon), Offset(1200, 800),
    Offset(0, 800)], const Fill.linear(Offset(0, _horizon), Offset(0, 800), [
    Color(0xFFF09A62), Color(0xFFA9557A), Color(0xFF473A72), Color(0xFF1C2248),
  ], [0, 0.18, 0.55, 1]), spacing: 6);
  // The sun's path on the water: broken strokes, narrower far away.
  for (var y = _horizon + 4; y < 760; y += 5 + (y - _horizon) * 0.05) {
    final t = (y - _horizon) / 300;
    final half = 60 + t * 90;
    for (var k = 0; k < 2 + rnd.nextInt(3); k++) {
      final x = _sun.dx + (rnd.nextDouble() - 0.5) * 2 * half;
      final len = 14 + rnd.nextDouble() * 40 * (1 - t * 0.5);
      a.line([Offset(x - len / 2, y), Offset(x + len / 2, y)],
          Nature.mix(const Color(0xFFFFF0C0), const Color(0xFFFF9E5E), t),
          width: 2 + t * 4,
          brush: BrushType.highlighter,
          opacity: 1 - t * 0.6,
          taper: true);
    }
  }
  // Waves: long low lines, closer together far away.
  for (var y = _horizon + 10; y < 800; y += 6 + (y - _horizon) * 0.08) {
    final t = (y - _horizon) / 330;
    var x = rnd.nextDouble() * 80 - 40;
    while (x < 1200) {
      final len = 40 + t * 160 + rnd.nextDouble() * 60;
      _soft(a, [Offset(x, y), Offset(x + len / 2, y - 1 - t * 3),
        Offset(x + len, y)], const Color(0xFF2A2858),
          width: 3 + t * 8, opacity: 0.35);
      a.line([Offset(x + len * 0.2, y - 2 - t * 3), Offset(x + len * 0.7, y - 2 - t * 4)],
          const Color(0xFFE79BA0), width: 1 + t * 2, opacity: 0.35, taper: true);
      x += len + 20 + rnd.nextDouble() * 80;
    }
  }
}

void _beach(Artist a, math.Random rnd) {
  // Wet sand reflecting the sky, then dry sand.
  const shore = [
    Offset(420, 800), Offset(560, 760), Offset(720, 720), Offset(880, 690),
    Offset(1040, 668), Offset(1220, 650),
  ];
  a.area([...Artist.spline(shore), const Offset(1220, 820), const Offset(420, 820)],
      const Fill.linear(Offset(0, 650), Offset(0, 800), [
        Color(0xFFB0607A), Color(0xFF6A3E5E),
      ]));
  final dry = [for (final p in shore) p + const Offset(40, 22)];
  a.area([...Artist.spline(dry), const Offset(1220, 820), const Offset(460, 820)],
      const Fill.linear(Offset(1200, 660), Offset(600, 800), [
        Color(0xFFF2B98A), Color(0xFFC07E6A), Color(0xFF6E4558),
      ]));
  // Foam where the waves run up.
  for (var k = 0; k < 3; k++) {
    final off = Offset(-6.0 * k, -5.0 * k);
    _soft(a, [for (final p in shore) p + off], const Color(0xFFFFE6D6),
        width: 6 - k * 1.5, opacity: 0.6 - k * 0.15);
  }
  // Pebbles and a starfish.
  for (var k = 0; k < 18; k++) {
    final x = 620 + rnd.nextDouble() * 560;
    final y = 740 + rnd.nextDouble() * 50 - (x - 620) * 0.08;
    a.oval(Offset(x, y), 3 + rnd.nextDouble() * 4, 2 + rnd.nextDouble() * 2,
        Fill.linear(Offset(x, y - 3), Offset(x, y + 3), const [
          Color(0xFFFFD9B0), Color(0xFF7A4E5A),
        ]));
  }
  a.star(const Offset(700, 772), 12, const Color(0xFFFF8A5C));
}

void _palm(Artist a, math.Random rnd) {
  // A palm leaning over the beach, dark against the sky, lit at the edge.
  final trunk = Artist.spline(const [
    Offset(1090, 700), Offset(1080, 600), Offset(1060, 480), Offset(1030, 360),
    Offset(990, 250),
  ]);
  a.area(Artist.spline(Artist.tube(trunk, [
    for (var i = 0; i < trunk.length; i++) 26 - 14 * i / trunk.length,
  ]), closed: true), const Fill.linear(Offset(1060, 0), Offset(1100, 0), [
    Color(0xFF241A2A), Color(0xFF4A3040), Color(0xFFB0705A),
  ]));
  for (var i = 4; i < trunk.length - 2; i += 6) {
    final p = trunk[i];
    a.line([p + const Offset(-10, 0), p + const Offset(10, -3)],
        const Color(0xFF1A1220), width: 1.5, opacity: 0.6, taper: true);
  }
  const crown = Offset(990, 250);
  for (final (deg, len, droop) in const [
    (200.0, 230.0, 60.0), (170.0, 210.0, 80.0), (230.0, 180.0, 40.0),
    (150.0, 160.0, 90.0), (300.0, 200.0, 70.0), (330.0, 230.0, 90.0),
    (10.0, 190.0, 110.0), (270.0, 120.0, 30.0), (120.0, 130.0, 70.0),
  ]) {
    final d = Offset.fromDirection(deg * math.pi / 180);
    final tip = crown + d * len + Offset(0, droop);
    final mid = crown + d * len * 0.5 + Offset(0, -20 + droop * 0.2);
    final spine = Artist.spline([crown, mid, tip]);
    a.line(spine, const Color(0xFF1C1424), width: 5, taper: true);
    // Leaflets hanging from the spine.
    for (var k = 3; k < spine.length - 1; k += 2) {
      final p = spine[k];
      final t = k / spine.length;
      final l = 34 * (1 - t * 0.6);
      for (final side in const [-1.0, 1.0]) {
        a.line([p, p + Offset(side * l * 0.4, l * 0.9)],
            const Color(0xFF231A2C), width: 3.5 * (1 - t * 0.5), taper: true);
      }
    }
  }
  for (final c in const [Offset(978, 262), Offset(996, 268), Offset(986, 276)]) {
    a.oval(c, 9, 9, Fill.radial(c + const Offset(-2, -3), 10, const [
      Color(0xFF8A5A40), Color(0xFF2A1A1A),
    ]));
  }
}

void _birds(Artist a) {
  for (final (c, w) in const [
    (Offset(360, 210), 26.0), (Offset(420, 240), 20.0), (Offset(470, 196), 16.0),
    (Offset(300, 260), 14.0), (Offset(520, 230), 12.0),
  ]) {
    a.curveLine([c + Offset(-w, -w * 0.25), c + Offset(-w * 0.45, -w * 0.4), c],
        const Color(0xFF2A2040), width: 2.4, brush: BrushType.pen, taper: true);
    a.curveLine([c, c + Offset(w * 0.45, -w * 0.45), c + Offset(w, -w * 0.2)],
        const Color(0xFF2A2040), width: 2.4, brush: BrushType.pen, taper: true);
  }
}
