// The intermediate coloring pages (for about age 12): whole scenes with
// more and smaller areas than the beginner's, still bold enough to fill
// with the paint bucket. Each draws front to back with a [Pen], so lines
// stop where they go behind something.
import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../samples/artist.dart';
import 'pen.dart';

part 'pages_mid_scenes.dart';

const _w = 5.0;
const _d = 3.5;

void drawMid(String name, Pen p) {
  p.width = _w;
  switch (name) {
    case 'lighthouse':
      _lighthouse(p);
    case 'castle':
      _castle(p);
    case 'underwater':
      _underwater(p);
    case 'balloons':
      _balloons(p);
    case 'owl':
      _owl(p);
    case 'panda':
      _panda(p);
    default:
      throw ArgumentError(name);
  }
}

/// A wavy line across the page at height [y].
List<Offset> _wave(double y, {double amp = 6, double length = 80, double shift = 0}) => [
      for (var x = -10.0; x <= 810; x += 4)
        Offset(x, y + amp * math.sin((x + shift) * 2 * math.pi / length)),
    ];

void _gull(Pen p, Offset at, double s) {
  p.curve([at + Offset(-26 * s, 5 * s), at + Offset(-13 * s, -8 * s), at + Offset(0, 4 * s)], width: 4);
  p.curve([at + Offset(0, 4 * s), at + Offset(13 * s, -8 * s), at + Offset(26 * s, 5 * s)], width: 4);
}

void _cloud(Pen p, Offset c, double s) => p.blob([
      for (final (x, y) in const [
        (-90.0, 20.0), (-70.0, -10.0), (-35.0, -22.0), (-10.0, -45.0), (30.0, -40.0),
        (55.0, -18.0), (85.0, -12.0), (100.0, 12.0), (70.0, 30.0), (0.0, 32.0), (-60.0, 32.0),
      ])
        c + Offset(x, y) * s,
    ]);

void _lighthouse(Pen p) {
  const horizon = 600.0;
  // Seagulls.
  _gull(p, const Offset(110, 390), 1);
  _gull(p, const Offset(195, 355), 0.75);
  _gull(p, const Offset(700, 430), 0.85);

  // A sailboat: flag, sails, the boom, the hull, then the mast.
  p.shape(const [Offset(135, 600), Offset(168, 608), Offset(135, 617)]);
  p.shape([const Offset(129, 750), ...Artist.spline(const [Offset(58, 750), Offset(80, 688), Offset(106, 640), Offset(129, 612)])]);
  p.shape(const [Offset(141, 628), Offset(141, 750), Offset(208, 750)]);
  p.path(const [Offset(58, 755), Offset(141, 755)], width: 4);
  p.curve(const [Offset(48, 784), Offset(135, 787), Offset(220, 784)], width: _d);
  p.shape([const Offset(40, 762), const Offset(228, 762), ...Pen.arc(const Offset(134, 690), 120, 52, 128)]);
  p.path(const [Offset(135, 762), Offset(135, 598)], width: 4);

  // Rocks at the cliff's foot, the water lapping round them.
  for (final (x0, x1, y) in [(186.0, 212.0, 928.0), (312.0, 330.0, 926.0), (232.0, 258.0, 992.0)]) {
    p.curve([Offset(x0, y), Offset((x0 + x1) / 2, y - 5), Offset(x1, y)], width: 3);
  }
  p.path(const [Offset(252, 882), Offset(258, 906), Offset(250, 924)], width: 3);
  p.shape(const [Offset(214, 930), Offset(226, 898), Offset(252, 878), Offset(278, 884), Offset(300, 904), Offset(308, 930)]);
  p.shape(const [Offset(262, 994), Offset(272, 960), Offset(298, 940), Offset(330, 938), Offset(350, 962), Offset(356, 994)]);

  // The cliff: cracks between rocks and the grass edge, then its outline.
  const top = [
    Offset(810, 720), Offset(700, 726), Offset(600, 722), Offset(480, 728),
    Offset(400, 726), Offset(335, 732),
  ];
  for (final crack in const [
    [Offset(318, 812), Offset(400, 800), Offset(470, 812), Offset(540, 842)],
    [Offset(540, 842), Offset(640, 828), Offset(720, 842), Offset(810, 832)],
    [Offset(470, 812), Offset(492, 770), Offset(486, 746)],
    [Offset(660, 832), Offset(672, 780), Offset(660, 744)],
    [Offset(304, 902), Offset(380, 890), Offset(450, 910), Offset(520, 960), Offset(540, 1010)],
    [Offset(540, 842), Offset(560, 900), Offset(520, 960)],
    [Offset(560, 900), Offset(660, 920), Offset(720, 1010)],
    [Offset(720, 842), Offset(740, 920), Offset(810, 940)],
  ]) {
    p.curve(crack, width: _d);
  }
  p.curve(const [Offset(328, 748), Offset(420, 744), Offset(520, 746), Offset(640, 742), Offset(810, 738)], width: _d);
  p.shape([
    ...top,
    const Offset(318, 760), const Offset(328, 800), const Offset(306, 850),
    const Offset(318, 905), const Offset(296, 960), const Offset(306, 1010),
    const Offset(810, 1010),
  ]);

  // The keeper's house: door, windows, the roof over the walls, the
  // chimney behind it.
  p.shape(const [Offset(372, 682), Offset(404, 682), Offset(404, 740), Offset(372, 740)]);
  for (final x in [344.0, 418.0]) {
    final r = Rect.fromLTWH(x, 664, 28, 30);
    p.path([r.topCenter, r.bottomCenter], width: _d);
    p.path([r.centerLeft, r.centerRight], width: _d);
    p.shape([r.topLeft, r.topRight, r.bottomRight, r.bottomLeft]);
  }
  p.shape(const [Offset(318, 644), Offset(395, 574), Offset(472, 644)]);
  p.shape(const [Offset(336, 640), Offset(456, 640), Offset(456, 740), Offset(336, 740)]);
  p.shape(const [Offset(426, 580), Offset(448, 580), Offset(448, 640), Offset(426, 640)]);

  // The lighthouse tower: from 300 to 735 high, narrower at the top.
  const x0 = 520.0;
  double half(double y) => 72 - (735 - y) * 26 / 435;
  // Arched door and windows.
  void archway(double cx, double topY, double bottomY, double r) => p.shape([
        Offset(cx - r, bottomY), ...Pen.arc(Offset(cx, topY + r), r, 180, 360),
        Offset(cx + r, bottomY),
      ]);
  archway(x0, 652, 714, 19);
  archway(x0, 420, 462, 12);
  archway(x0, 578, 620, 12);
  // Bands: below eye level (the horizon) they curve down, above it up.
  for (final y in [640.0, 560.0, 480.0, 400.0, 330.0]) {
    final sag = (y - horizon) * 0.06;
    p.curve([Offset(x0 - half(y), y), Offset(x0, y + sag), Offset(x0 + half(y), y)], width: 4);
  }
  p.shape(const [Offset(428, 712), Offset(612, 712), Offset(612, 740), Offset(428, 740)]);
  p.shape([Offset(x0 - half(300), 300), Offset(x0 + half(300), 300), Offset(x0 + half(740), 740), Offset(x0 - half(740), 740)]);
  // The gallery, its railing, the roof and the lantern.
  p.shape(const [Offset(448, 296), Offset(592, 296), Offset(592, 312), Offset(448, 312)]);
  for (var x = 468.0; x < 576; x += 13) {
    p.path([Offset(x, 264), Offset(x, 296)], width: 3);
  }
  p.shape(const [Offset(455, 262), Offset(585, 262), Offset(585, 296), Offset(455, 296)]);
  p.shape(const [Offset(472, 184), Offset(568, 184), Offset(568, 198), Offset(472, 198)]);
  p.circle(const Offset(x0, 130), 9);
  p.path(const [Offset(x0, 121), Offset(x0, 98)], width: 4);
  p.shape([...Pen.arc(const Offset(x0, 186), 42, 180, 360)]);
  for (final x in [507.0, 533.0]) {
    p.path([Offset(x, 198), Offset(x, 262)], width: _d);
  }
  p.shape(const [Offset(482, 196), Offset(558, 196), Offset(558, 262), Offset(482, 262)]);
  // Its light, both ways.
  p.shape(const [Offset(495, 214), Offset(250, 186), Offset(250, 272), Offset(495, 244)]);
  p.shape(const [Offset(545, 214), Offset(790, 186), Offset(790, 272), Offset(545, 244)]);

  _cloud(p, const Offset(150, 95), 1);
  _cloud(p, const Offset(680, 70), 0.7);

  // The sea: waves, the horizon, the sun's glitter; then the sun, half set.
  for (final (i, y) in [655.0, 715.0, 790.0, 870.0, 950.0].indexed) {
    p.path(_wave(y, amp: 5 + i * 1.5, length: 70 + i * 12, shift: i * 31), width: 4);
  }
  p.path(const [Offset(-10, horizon), Offset(810, horizon)]);
  for (final (y, r) in [(616.0, 38.0), (630.0, 28.0), (644.0, 20.0)]) {
    p.path([Offset(290 - r, y), Offset(290 + r, y)], width: 3);
  }
  p.cover(const [Offset(-10, horizon), Offset(810, horizon), Offset(810, 1010), Offset(-10, 1010)]);
  p.circle(const Offset(290, horizon), 46);
  for (var i = 0; i < 7; i++) {
    final d = Offset.fromDirection(math.pi + (i + 0.5) * math.pi / 7);
    p.path([const Offset(290, horizon) + d * 60, const Offset(290, horizon) + d * 82], width: 4);
  }
}
