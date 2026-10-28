// The line drawings of the coloring pages (lib/gallery/coloring_pages.dart):
// bold, closed outlines a kid can color inside, by hand or with the paint
// bucket. Made by make_coloring_test.dart.
import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../samples/artist.dart';

/// Every page is this size (portrait, like a sheet of paper).
const pageSize = Size(800, 1000);

const ink = Color(0xFF222222);
const w = 7.0;

/// Draws page [name] with [a].
void drawPage(String name, Artist a) => switch (name) {
      'cat' => _cat(a),
      'house' => _house(a),
      'flower' => _flower(a),
      'fish' => _fish(a),
      'rocket' => _rocket(a),
      'butterfly' => _butterfly(a),
      'car' => _car(a),
      'tree' => _tree(a),
      _ => throw ArgumentError(name),
    };

/// A closed smooth outline through [pts].
void _blob(Artist a, List<Offset> pts, {double width = w}) =>
    a.line([...Artist.spline(pts, closed: true), Artist.spline(pts, closed: true).first],
        ink, width: width);

/// A closed outline with straight sides.
void _poly(Artist a, List<Offset> pts, {double width = w}) =>
    a.line([...pts, pts.first], ink, width: width);

void _ground(Artist a, double y) =>
    a.curveLine([Offset(40, y), Offset(260, y - 14), Offset(540, y + 10), Offset(760, y - 6)],
        ink, width: w);

void _cat(Artist a) {
  // Body, then the head over it.
  a.ovalLine(const Offset(400, 730), 170, 190, ink, width: w);
  // Tail curling up beside the body.
  _blob(a, const [
    Offset(560, 820), Offset(660, 780), Offset(700, 640), Offset(650, 560),
    Offset(630, 600), Offset(660, 660), Offset(630, 760), Offset(555, 790),
  ]);
  // Ears.
  a.line(const [Offset(262, 272), Offset(250, 150), Offset(352, 222)], ink, width: w);
  a.line(const [Offset(538, 272), Offset(550, 150), Offset(448, 222)], ink, width: w);
  a.ring(const Offset(400, 380), 175, ink, width: w);
  // Eyes, nose, mouth, whiskers.
  for (final x in [330.0, 470.0]) {
    a.ovalLine(Offset(x, 355), 30, 38, ink, width: w);
    a.ring(Offset(x + 6, 362), 12, ink, width: w - 2);
  }
  _poly(a, const [Offset(380, 420), Offset(420, 420), Offset(400, 444)]);
  a.curveLine(const [Offset(400, 444), Offset(380, 478), Offset(352, 470)], ink, width: w - 2);
  a.curveLine(const [Offset(400, 444), Offset(420, 478), Offset(448, 470)], ink, width: w - 2);
  for (final (dy, tilt) in [(0.0, -14.0), (22.0, 6.0)]) {
    a.line([Offset(315, 440 + dy), Offset(205, 430 + dy + tilt)], ink, width: 4);
    a.line([Offset(485, 440 + dy), Offset(595, 430 + dy + tilt)], ink, width: 4);
  }
  // Paws.
  a.ovalLine(const Offset(330, 905), 55, 34, ink, width: w);
  a.ovalLine(const Offset(470, 905), 55, 34, ink, width: w);
}

void _house(Artist a) {
  // The sun, a cloud.
  a.ring(const Offset(650, 140), 60, ink, width: w);
  for (var i = 0; i < 8; i++) {
    final d = Offset.fromDirection(i * math.pi / 4, 1);
    a.line([const Offset(650, 140) + d * 80, const Offset(650, 140) + d * 112], ink, width: 5);
  }
  _blob(a, const [
    Offset(90, 200), Offset(120, 140), Offset(190, 130), Offset(240, 90),
    Offset(320, 120), Offset(340, 190), Offset(260, 220), Offset(150, 225),
  ]);
  // Chimney behind the roof, the roof, the walls.
  _poly(a, const [Offset(470, 330), Offset(470, 230), Offset(530, 230), Offset(530, 380)]);
  _poly(a, const [Offset(170, 480), Offset(400, 270), Offset(630, 480)]);
  a.box(const Rect.fromLTRB(220, 480, 580, 840), ink, width: w);
  // Door with a knob, two windows with crosses.
  a.box(const Rect.fromLTRB(345, 640, 455, 840), ink, width: w);
  a.ring(const Offset(435, 745), 8, ink, width: 5);
  for (final x in [255.0, 455.0]) {
    final r = Rect.fromLTWH(x, 530, 90, 80);
    a.box(r, ink, width: w);
    a.line([r.topCenter, r.bottomCenter], ink, width: 5);
    a.line([r.centerLeft, r.centerRight], ink, width: 5);
  }
  // A round window in the roof.
  a.ring(const Offset(400, 400), 34, ink, width: w);
  _ground(a, 860);
  // Flowers by the door.
  for (final x in [170.0, 640.0]) {
    a.line([Offset(x, 900), Offset(x, 850)], ink, width: 5);
    for (var i = 0; i < 5; i++) {
      a.ring(Offset(x, 830) + Offset.fromDirection(i * 2 * math.pi / 5, 18), 12, ink, width: 4);
    }
    a.ring(Offset(x, 830), 9, ink, width: 4);
  }
}

void _flower(Artist a) {
  const c = Offset(400, 330);
  // Petals, then the middle over them.
  for (var i = 0; i < 8; i++) {
    final angle = i * math.pi / 4;
    a.ovalLine(c + Offset.fromDirection(angle, 148), 70, 40, ink, width: w, angle: angle);
  }
  a.ring(c, 78, ink, width: w);
  for (final d in const [Offset(-25, -20), Offset(22, -28), Offset(0, 18), Offset(-30, 28), Offset(32, 22)]) {
    a.ring(c + d, 8, ink, width: 4);
  }
  // Stem and leaves.
  a.line(const [Offset(385, 548), Offset(382, 760)], ink, width: w);
  a.line(const [Offset(415, 548), Offset(418, 760)], ink, width: w);
  a.curveLine(const [Offset(383, 660), Offset(320, 590), Offset(230, 600), Offset(300, 665), Offset(383, 690)], ink, width: w);
  a.curveLine(const [Offset(417, 620), Offset(480, 555), Offset(575, 560), Offset(505, 630), Offset(417, 650)], ink, width: w);
  // A pot with a rim.
  _poly(a, const [Offset(260, 760), Offset(540, 760), Offset(540, 810), Offset(260, 810)]);
  _poly(a, const [Offset(280, 810), Offset(520, 810), Offset(485, 960), Offset(315, 960)]);
  a.curveLine(const [Offset(310, 870), Offset(400, 890), Offset(490, 870)], ink, width: 5);
}

void _fish(Artist a) {
  // Tail behind the body, the body, a fin on top.
  a.line(const [Offset(597, 420), Offset(730, 360), Offset(700, 470), Offset(730, 580), Offset(597, 520)], ink, width: w);
  a.ovalLine(const Offset(380, 470), 230, 150, ink, width: w);
  a.curveLine(const [Offset(290, 335), Offset(330, 250), Offset(420, 225), Offset(500, 250), Offset(495, 345)], ink, width: w);
  // Eye, gill, mouth, a fin and scales.
  a.ring(const Offset(250, 430), 36, ink, width: w);
  a.ring(const Offset(260, 430), 14, ink, width: w - 2);
  a.curveLine(const [Offset(320, 370), Offset(345, 470), Offset(320, 570)], ink, width: w - 1);
  a.curveLine(const [Offset(165, 500), Offset(190, 520), Offset(220, 510)], ink, width: 5);
  a.curveLine(const [Offset(395, 618), Offset(440, 690), Offset(520, 690), Offset(500, 605)], ink, width: w);
  for (final (x, y) in [(420.0, 420.0), (500.0, 430.0), (460.0, 490.0), (540.0, 495.0)]) {
    a.curveLine([Offset(x - 26, y - 20), Offset(x, y), Offset(x - 26, y + 20)], ink, width: 5);
  }
  // Bubbles and the seabed.
  for (final (x, y, r) in [(160.0, 250.0, 22.0), (110.0, 160.0, 15.0), (180.0, 110.0, 10.0), (620.0, 200.0, 18.0)]) {
    a.ring(Offset(x, y), r, ink, width: 5);
  }
  _ground(a, 860);
  for (final x in [120.0, 650.0]) {
    _blob(a, [Offset(x, 860), Offset(x - 30, 760), Offset(x + 5, 690), Offset(x + 30, 780)]);
  }
}

void _rocket(Artist a) {
  // Flame below, fins, the body, the nose.
  a.curveLine(const [Offset(345, 760), Offset(360, 860), Offset(400, 960), Offset(440, 860), Offset(455, 760)], ink, width: w);
  a.curveLine(const [Offset(375, 760), Offset(400, 860), Offset(425, 760)], ink, width: 5);
  a.line(const [Offset(313, 590), Offset(220, 760), Offset(318, 742)], ink, width: w);
  a.line(const [Offset(487, 590), Offset(580, 760), Offset(482, 742)], ink, width: w);
  _blob(a, const [
    Offset(400, 140), Offset(470, 260), Offset(490, 480), Offset(480, 760),
    Offset(320, 760), Offset(310, 480), Offset(330, 260),
  ]);
  a.curveLine(const [Offset(338, 300), Offset(400, 320), Offset(462, 300)], ink, width: w);
  // Two round windows, a stripe.
  a.ring(const Offset(400, 420), 46, ink, width: w);
  a.ring(const Offset(400, 550), 32, ink, width: w);
  a.line(const [Offset(318, 660), Offset(482, 660)], ink, width: w);
  // Stars and a planet.
  for (final (x, y, r) in [(140.0, 180.0, 34.0), (650.0, 320.0, 28.0), (160.0, 560.0, 24.0), (660.0, 640.0, 30.0)]) {
    final pts = [
      for (var i = 0; i < 10; i++)
        Offset(x, y) + Offset.fromDirection(i * math.pi / 5 - math.pi / 2, i.isEven ? r : r * 0.45),
    ];
    _poly(a, pts, width: 5);
  }
  a.ring(const Offset(620, 120), 50, ink, width: w);
  a.ovalLine(const Offset(620, 120), 90, 20, ink, width: 5, angle: -0.35);
}

void _butterfly(Artist a) {
  // Wings (top and bottom, each side), then the body over them.
  for (final s in [-1.0, 1.0]) {
    _blob(a, [
      Offset(400 + s * 36, 430), Offset(400 + s * 120, 200), Offset(400 + s * 300, 170),
      Offset(400 + s * 330, 330), Offset(400 + s * 200, 460),
    ]);
    _blob(a, [
      Offset(400 + s * 36, 500), Offset(400 + s * 230, 520), Offset(400 + s * 280, 680),
      Offset(400 + s * 160, 760), Offset(400 + s * 36, 640),
    ]);
    a.ring(Offset(400 + s * 210, 310), 46, ink, width: w);
    a.ring(Offset(400 + s * 170, 620), 34, ink, width: w);
    a.ring(Offset(400 + s * 270, 245), 16, ink, width: 5);
  }
  a.ovalLine(const Offset(400, 500), 34, 210, ink, width: w);
  a.ring(const Offset(400, 270), 40, ink, width: w);
  // Antennae.
  for (final s in [-1.0, 1.0]) {
    a.curveLine([Offset(400 + s * 15, 235), Offset(400 + s * 50, 160), Offset(400 + s * 100, 120)], ink, width: 5);
    a.ring(Offset(400 + s * 108, 112), 14, ink, width: 5);
  }
  for (final (x, y) in [(150.0, 880.0), (650.0, 900.0)]) {
    a.line([Offset(x, 960), Offset(x, y)], ink, width: 5);
    _blob(a, [Offset(x, y), Offset(x - 40, y - 60), Offset(x, y - 110), Offset(x + 40, y - 60)]);
  }
}

void _car(Artist a) {
  // The road, the body, the cabin.
  a.line(const [Offset(30, 780), Offset(770, 780)], ink, width: w);
  for (var x = 80.0; x < 760; x += 140) {
    a.box(Rect.fromLTWH(x, 860, 70, 18), ink, width: 5);
  }
  _blob(a, const [
    Offset(110, 640), Offset(130, 540), Offset(250, 515), Offset(560, 515),
    Offset(680, 550), Offset(700, 640), Offset(680, 700), Offset(130, 700),
  ]);
  _poly(a, const [Offset(250, 515), Offset(310, 390), Offset(510, 390), Offset(590, 515)]);
  // Windows, door line, handle, lights.
  _poly(a, const [Offset(275, 505), Offset(322, 410), Offset(400, 410), Offset(400, 505)]);
  _poly(a, const [Offset(420, 505), Offset(420, 410), Offset(500, 410), Offset(560, 505)]);
  a.line(const [Offset(410, 515), Offset(410, 690)], ink, width: 5);
  a.box(const Rect.fromLTWH(440, 560, 50, 16), ink, width: 5);
  a.ovalLine(const Offset(670, 590), 20, 26, ink, width: 5);
  a.box(const Rect.fromLTWH(118, 580, 34, 30), ink, width: 5);
  // Wheels with hubs.
  for (final x in [240.0, 560.0]) {
    a.ring(Offset(x, 700), 76, ink, width: w);
    a.ring(Offset(x, 700), 32, ink, width: w);
  }
  // A cloud and a bird.
  _blob(a, const [
    Offset(470, 220), Offset(500, 160), Offset(570, 150), Offset(620, 110),
    Offset(700, 140), Offset(720, 210), Offset(640, 240), Offset(530, 245),
  ]);
  a.curveLine(const [Offset(150, 180), Offset(185, 155), Offset(215, 180), Offset(245, 155), Offset(280, 180)], ink, width: 5);
}

void _tree(Artist a) {
  // The trunk, then the crown over it.
  a.line(const [Offset(368, 678), Offset(350, 905)], ink, width: w);
  a.line(const [Offset(432, 678), Offset(450, 905)], ink, width: w);
  a.curveLine(const [Offset(359, 810), Offset(330, 790), Offset(300, 760)], ink, width: 5);
  final crown = [
    for (var i = 0; i < 9; i++)
      ...() {
        final mid = Offset(400, 400) + Offset.fromDirection(i * 2 * math.pi / 9 - math.pi / 2, 230);
        final out = Offset(400, 400) + Offset.fromDirection((i + 0.5) * 2 * math.pi / 9 - math.pi / 2, 285);
        return [mid, out];
      }(),
  ];
  _blob(a, crown);
  // Apples, a hole with an owl's eyes, grass and a mushroom.
  for (final (x, y) in [(300.0, 330.0), (480.0, 290.0), (540.0, 450.0), (330.0, 500.0), (420.0, 190.0), (230.0, 420.0)]) {
    a.ring(Offset(x, y), 26, ink, width: w);
    a.line([Offset(x, y - 26), Offset(x + 6, y - 42)], ink, width: 4);
  }
  a.ovalLine(const Offset(402, 780), 26, 34, ink, width: w);
  _ground(a, 910);
  for (var x = 80.0; x < 760; x += 60) {
    if ((x - 400).abs() < 70) continue;
    a.line([Offset(x, 915), Offset(x + 10, 875), Offset(x + 20, 915)], ink, width: 4);
  }
  a.line(const [Offset(580, 908), Offset(582, 862)], ink, width: 5);
  a.line(const [Offset(620, 908), Offset(618, 862)], ink, width: 5);
  _blob(a, const [Offset(540, 862), Offset(560, 815), Offset(600, 800), Offset(640, 815), Offset(660, 862)]);
}
