import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jingyao_paint/drawing/stroke.dart';

import 'tarot_card.dart';

/// 0 · 愚人: a young traveler at the edge of a cliff at sunrise, bundle on
/// a staff over the shoulder and a white rose in hand, looking up at the
/// sky, cloak blowing in the wind, a little white dog jumping beside them.
/// Painted, not drawn: gradients for form, soft edges, shadow and light.
final theFool = TarotCard(
  number: 0,
  numeral: '0',
  zh: '愚人',
  en: 'The Fool',
  keywords: ['新的开始', '自由', '冒险'],
  scene: _paint,
);

/// The sun, up and to the right: everything is lit from there.
const _sun = Offset(515, 285);
const _warmLight = Color(0xFFFFE2B0);

void _paint(Artist a) {
  _sky(a);
  _mountains(a);
  _cloudSea(a);
  _cliff(a);
  _dog(a);
  _traveler(a);
}

void _sky(Artist a) {
  a.area(const [Offset(40, 120), Offset(660, 120), Offset(660, 940),
    Offset(40, 940)], const Fill.linear(Offset(0, 130), Offset(0, 790), [
    Color(0xFF244A86), Color(0xFF4A82BF), Color(0xFF8DBEDF),
    Color(0xFFD3E4EA), Color(0xFFF6E1BF), Color(0xFFF7CC97),
  ], [0, 0.25, 0.5, 0.68, 0.85, 1]));

  // Sunlight: a wide warm glow, rays, and the bright disc.
  a.glow(_sun, 330, const Color(0x55FFE9B8), blend: StrokeBlend.screen);
  for (final (deg, length, w) in const [
    (200.0, 430.0, 26.0), (215.0, 380.0, 16.0), (232.0, 460.0, 30.0),
    (250.0, 360.0, 18.0), (268.0, 420.0, 22.0), (186.0, 330.0, 14.0),
    (290.0, 300.0, 14.0), (160.0, 260.0, 12.0), (130.0, 220.0, 12.0),
    (20.0, 200.0, 12.0), (330.0, 240.0, 14.0), (60.0, 180.0, 10.0),
  ]) {
    final d = Offset.fromDirection(-deg * math.pi / 180);
    final n = Offset(-d.dy, d.dx);
    final end = _sun + d * length;
    a.area([_sun + n * 3, end + n * w, end - n * w, _sun - n * 3],
        Fill.linear(_sun, end,
            [const Color(0x66FFF3D2), const Color(0x00FFF3D2)]),
        blur: 5, blend: StrokeBlend.screen);
  }
  a.glow(_sun, 150, const Color(0x99FFF2CF), blend: StrokeBlend.screen);
  a.glow(_sun, 72, const Color(0xFFFFFBEC));
  a.oval(_sun, 36, 36, const Fill(Color(0xFFFFFEF7)), blur: 3);

  // High, thin clouds catching the light.
  for (final (c, r, angle, alpha) in const [
    (Offset(170, 300), 120.0, -0.08, 0.45), (Offset(250, 250), 90.0, -0.1, 0.35),
    (Offset(120, 360), 80.0, -0.05, 0.4), (Offset(600, 410), 90.0, 0.06, 0.4),
    (Offset(330, 200), 70.0, -0.12, 0.25),
  ]) {
    a.glow(c, r, Colors.white.withValues(alpha: alpha),
        squash: 0.1, angle: angle);
  }
  // A soft cloud bank on the left, lit from the right.
  for (final (c, r, squash) in const [
    (Offset(110, 470), 70.0, 0.45), (Offset(170, 455), 60.0, 0.55),
    (Offset(225, 475), 50.0, 0.45), (Offset(150, 490), 95.0, 0.25),
  ]) {
    a.glow(c, r, const Color(0xE6FFFFFF), squash: squash);
  }
  a.glow(const Offset(200, 448), 40, const Color(0x88FFE6C2),
      squash: 0.5, blend: StrokeBlend.screen);
  a.glow(const Offset(140, 500), 90, const Color(0x40A9A6CC),
      squash: 0.18, blend: StrokeBlend.multiply);
}

void _mountains(Artist a) {
  // The far range, hazy at its foot.
  const far = [
    Offset(40, 612), Offset(80, 586), Offset(118, 598), Offset(160, 560),
    Offset(205, 520), Offset(240, 548), Offset(280, 590), Offset(330, 574),
    Offset(380, 600), Offset(430, 584), Offset(470, 540), Offset(520, 492),
    Offset(548, 470), Offset(575, 500), Offset(612, 540), Offset(660, 574),
  ];
  a.area([...far, const Offset(660, 830), const Offset(40, 830)],
      const Fill.linear(Offset(0, 470), Offset(0, 800), [
        Color(0xFF8590C0), Color(0xFFB0B3D5), Color(0xFFE6DCE3),
      ]), spacing: 2);
  // Sunlit slopes face right; snow on the high peaks.
  for (final (peak, down, back) in const [
    (Offset(548, 470), Offset(612, 540), Offset(560, 560)),
    (Offset(205, 520), Offset(240, 548), Offset(214, 568)),
    (Offset(470, 540), Offset(520, 492), Offset(500, 560)),
    (Offset(160, 560), Offset(205, 520), Offset(190, 580)),
  ]) {
    a.area([peak, down, back], Fill.linear(peak, back,
        const [Color(0xCCE4E3F2), Color(0x00E4E3F2)]), blur: 1.5);
  }
  for (final (peak, l, r, depth) in const [
    (Offset(548, 470), Offset(520, 492), Offset(575, 500), 0.42),
    (Offset(205, 520), Offset(160, 560), Offset(240, 548), 0.3),
  ]) {
    Offset at(Offset to, double t) => Offset.lerp(peak, to, t)!;
    final snow = [
      peak, at(r, depth * 0.8), at(r, depth * 0.55) + const Offset(-6, 4),
      at(r, depth * 0.4) + const Offset(-4, 10), at(peak + const Offset(0, 60), depth * 0.5),
      at(l, depth * 0.45) + const Offset(6, 6), at(l, depth * 0.65),
    ];
    a.area(snow, Fill.linear(peak + const Offset(14, 0),
        peak - const Offset(14, 0), const [Color(0xFFFFFFFF), Color(0xFFC9D0E6)]),
        blur: 0.6);
  }

  // A nearer range behind the sea of clouds.
  a.area(const [
    Offset(360, 770), Offset(410, 720), Offset(462, 668), Offset(500, 646), Offset(538, 668),
    Offset(578, 632), Offset(616, 652), Offset(660, 622), Offset(660, 840),
    Offset(360, 840),
  ], const Fill.linear(Offset(0, 625), Offset(0, 790), [
    Color(0xFF6C77A8), Color(0xFFA3A6CA),
  ]));
  for (final (p, q, r) in const [
    (Offset(500, 646), Offset(538, 668), Offset(512, 700)),
    (Offset(578, 632), Offset(616, 652), Offset(590, 690)),
    (Offset(660, 622), Offset(660, 660), Offset(640, 668)),
  ]) {
    a.area([p, q, r], Fill.linear(p, r,
        const [Color(0xAAD9DAF0), Color(0x00D9DAF0)]), blur: 1.5);
  }
  // Morning haze where the mountains meet the clouds.
  a.glow(const Offset(540, 760), 260, const Color(0x99FFF6EC), squash: 0.2);
}

void _cloudSea(Artist a) {
  a.area(const [Offset(430, 796), Offset(660, 796), Offset(660, 945),
    Offset(430, 945)], const Fill.linear(Offset(0, 790), Offset(0, 945), [
    Color(0xFFF3EDF4), Color(0xFFD5CDE6),
  ]), blur: 8);
  // Billows of different sizes, farther ones smaller and paler; soft
  // shadow under each, warm light on top.
  final rnd = math.Random(11);
  for (var row = 0; row < 5; row++) {
    final y = 782.0 + row * 36 + row * row * 3;
    final k = 0.8 + row * 0.22;
    var x = 466.0 + rnd.nextDouble() * 30;
    while (x < 652) {
      final rx = math.min((26 + rnd.nextDouble() * 26) * k, 690 - x);
      final ry = rx * (0.42 + rnd.nextDouble() * 0.2);
      final c = Offset(x, y + rnd.nextDouble() * 16 - 8);
      a.glow(c + Offset(0, ry * 0.7), rx * 1.1, const Color(0x99B4AACF),
          squash: 0.45, blend: StrokeBlend.multiply);
      a.oval(c, rx, ry, Fill.radial(c + Offset(rx * 0.3, -ry * 0.7), rx * 1.4,
          const [Color(0xFFFFFFFF), Color(0xFFF1ECF5), Color(0xFFCFC6E2)],
          const [0, 0.5, 1]), blur: 3.5);
      a.glow(c + Offset(rx * 0.3, -ry * 0.5), rx * 0.7,
          const Color(0x77FFE7C4), squash: 0.45, blend: StrokeBlend.screen);
      x += rx * (1.1 + rnd.nextDouble() * 0.6);
    }
  }
  a.glow(const Offset(560, 790), 160, const Color(0x99FFF8EE), squash: 0.16);
}

const _top = [
  Offset(30, 782), Offset(90, 776), Offset(160, 770), Offset(230, 767),
  Offset(300, 764), Offset(370, 762), Offset(430, 759), Offset(470, 756),
  Offset(492, 758), Offset(500, 766),
];

/// How high the grass is at [x].
double _groundAt(double x) {
  for (var i = 0; i + 1 < _top.length; i++) {
    final p = _top[i], q = _top[i + 1];
    if (x <= q.dx) return p.dy + (q.dy - p.dy) * (x - p.dx) / (q.dx - p.dx);
  }
  return _top.last.dy;
}

void _cliff(Artist a) {
  const face = [
    Offset(506, 782), Offset(500, 806), Offset(514, 836), Offset(506, 866),
    Offset(524, 900), Offset(518, 945),
  ];
  a.area([const Offset(30, 945), ..._top, ...face],
      const Fill.linear(Offset(0, 760), Offset(0, 945), [
        Color(0xFFC6A07A), Color(0xFF9A7452), Color(0xFF5B4232),
      ]));
  // The face toward the drop catches the sun.
  a.area(const [
    Offset(470, 770), Offset(500, 766), ...face, Offset(470, 945),
    Offset(482, 900), Offset(466, 860), Offset(476, 820), Offset(460, 790),
  ], const Fill.linear(Offset(458, 0), Offset(524, 0), [
    Color(0xFF7F5C40), Color(0xFFB28D66), Color(0xFFE2C097),
  ]), blur: 0.8);
  // Broken planes of rock, each lit on top.
  for (final (pts, color) in const [
    ([Offset(60, 802), Offset(180, 794), Offset(232, 814), Offset(150, 838),
      Offset(70, 832)], Color(0x99B88F68)),
    ([Offset(240, 800), Offset(360, 792), Offset(422, 812), Offset(380, 842),
      Offset(262, 836)], Color(0x88B48A62)),
    ([Offset(78, 862), Offset(200, 852), Offset(302, 874), Offset(222, 902),
      Offset(90, 897)], Color(0x88866447)),
    ([Offset(300, 862), Offset(430, 852), Offset(462, 882), Offset(400, 912),
      Offset(312, 902)], Color(0x80775639)),
  ]) {
    a.area(pts, Fill(color), blur: 1.2);
    a.line(pts.take(3).toList(), const Color(0xFFE6C9A2),
        width: 2, opacity: 0.55, blur: 0.6, taper: true);
  }
  for (final crack in const [
    [Offset(150, 838), Offset(168, 862), Offset(162, 892)],
    [Offset(380, 842), Offset(370, 872)],
    [Offset(232, 814), Offset(252, 846)],
    [Offset(462, 882), Offset(448, 922)],
    [Offset(70, 832), Offset(58, 872)],
    [Offset(496, 806), Offset(486, 840), Offset(492, 868)],
  ]) {
    a.line(crack, const Color(0xFF3F2C20), width: 2.2, opacity: 0.75,
        taper: true);
  }
  a.spray([const Offset(70, 880), const Offset(440, 880)],
      const Color(0xFF4A3426), width: 60, opacity: 0.12);
  // Shadow under the lip of grass.
  a.area([
    for (final p in _top.take(9)) p + const Offset(0, 10),
    for (final p in _top.take(9).toList().reversed) p + const Offset(0, 30),
  ], const Fill(Color(0xFF6F523C)), blur: 5, blend: StrokeBlend.multiply,
      opacity: 0.7);

  // Grass along the top.
  a.area([
    for (final p in _top) p + const Offset(0, -5),
    for (final (i, p) in _top.indexed.toList().reversed)
      p + Offset(0, i.isEven ? 16 : 11),
  ], const Fill.linear(Offset(0, 752), Offset(0, 780), [
    Color(0xFFA2CC63), Color(0xFF5E8E3A),
  ]));
  // The traveler's shadow falls away from the sun.
  a.glow(const Offset(372, 766), 74, const Color(0x99355421),
      squash: 0.1, blend: StrokeBlend.multiply);
  a.glow(const Offset(286, 770), 34, const Color(0x88355421),
      squash: 0.14, blend: StrokeBlend.multiply);
  final rnd = math.Random(3);
  const greens = [
    Color(0xFF3F6E2A), Color(0xFF5B8F38), Color(0xFF79AE46), Color(0xFF98C95A),
    Color(0xFFBEE07C),
  ];
  for (var x = 34.0; x < 494; x += 2.6 + rnd.nextDouble() * 2.4) {
    final y = _groundAt(x) + 4 + rnd.nextDouble() * 6;
    final h = 8 + rnd.nextDouble() * 14;
    // The wind comes from the right.
    final lean = -3 - rnd.nextDouble() * 6;
    a.line([Offset(x, y), Offset(x + lean * 0.4, y - h * 0.6),
      Offset(x + lean, y - h)], greens[rnd.nextInt(greens.length)],
        width: 1.4 + rnd.nextDouble(), taper: true);
  }
  // Small wildflowers.
  for (final (x, color) in const [
    (60.0, Colors.white), (118.0, Color(0xFFFFE07A)), (176.0, Colors.white),
    (214.0, Color(0xFFB9C9FF)), (250.0, Colors.white), (432.0, Colors.white),
    (474.0, Color(0xFFFFE07A)), (140.0, Color(0xFFB9C9FF)),
  ]) {
    final c = Offset(x, _groundAt(x) - 4);
    for (var i = 0; i < 5; i++) {
      a.oval(c + Offset.fromDirection(i * 2 * math.pi / 5, 2.4), 1.9, 1.9,
          Fill(color));
    }
    a.oval(c, 1.3, 1.3, const Fill(Color(0xFFE8A93A)));
  }
}

void _dog(Artist a) {
  const fur = Fill.linear(Offset(262, 0), Offset(372, 0), [
    Color(0xFFBDB8CC), Color(0xFFEDEBF1), Color(0xFFFFFFFF),
  ]);
  // Tail and hind legs on the ground.
  a.curveLine(const [Offset(272, 730), Offset(258, 718), Offset(252, 702),
    Offset(257, 690)], const Color(0xFFE9E6EF), width: 7, taper: true);
  a.blob(const [Offset(274, 736), Offset(262, 752), Offset(262, 768),
    Offset(276, 770), Offset(282, 756), Offset(288, 744)], fur);
  a.blob(const [Offset(290, 738), Offset(287, 756), Offset(292, 769),
    Offset(306, 770), Offset(302, 754), Offset(304, 738)], fur);
  // Body rising to the right, then the head.
  a.blob(const [Offset(272, 744), Offset(266, 722), Offset(278, 700),
    Offset(298, 684), Offset(320, 676), Offset(336, 682), Offset(336, 698),
    Offset(322, 718), Offset(304, 736), Offset(288, 748)], fur);
  // Front paws reaching toward the traveler.
  for (final spine in const [
    [Offset(318, 704), Offset(334, 714), Offset(348, 712)],
    [Offset(326, 694), Offset(342, 700), Offset(354, 694)],
  ]) {
    a.area(Artist.spline(Artist.tube(spine, const [10, 8, 7]), closed: true),
        fur);
  }
  a.blob(const [Offset(322, 678), Offset(318, 662), Offset(328, 648),
    Offset(344, 642), Offset(358, 648), Offset(366, 656), Offset(374, 662),
    Offset(370, 670), Offset(358, 674), Offset(346, 682), Offset(332, 684)],
      Fill.radial(const Offset(352, 650), 40, const [
        Colors.white, Color(0xFFF1EEF4), Color(0xFFBDB8CC),
      ]));
  a.blob(const [Offset(332, 650), Offset(324, 640), Offset(316, 646),
    Offset(314, 662), Offset(320, 670), Offset(330, 662)],
      const Fill.linear(Offset(0, 640), Offset(0, 670), [
        Color(0xFFD29C63), Color(0xFF8C5A33),
      ]));
  a.oval(const Offset(349, 655), 2.8, 2.4, const Fill(Color(0xFF231A16)));
  a.oval(const Offset(350, 654), 0.9, 0.9, const Fill(Colors.white));
  a.oval(const Offset(373, 664), 3.4, 2.7, const Fill(Color(0xFF1E1714)));
  a.curveLine(const [Offset(358, 672), Offset(364, 673), Offset(369, 670)],
      const Color(0xFF3A2620), width: 1.4, taper: true);
  a.blob(const [Offset(361, 674), Offset(367, 673), Offset(368, 680),
    Offset(363, 683)], const Fill(Color(0xFFE58A93)));
  // Shade on the side away from the sun, and between the legs.
  for (final (pts, w) in const [
    ([Offset(270, 742), Offset(268, 722), Offset(280, 700)], 7.0),
    ([Offset(290, 748), Offset(308, 734), Offset(324, 716)], 6.0),
    ([Offset(324, 680), Offset(336, 684), Offset(350, 680)], 5.0),
    ([Offset(284, 744), Offset(286, 766)], 4.0),
  ]) {
    a.curveLine(pts, const Color(0xFF8F89A8), width: w, opacity: 0.45,
        blur: 2.5, blend: StrokeBlend.multiply, taper: true);
  }
  // A little fur texture along the shaded side.
  for (final pts in const [
    [Offset(276, 716), Offset(272, 726)], [Offset(284, 700), Offset(280, 708)],
    [Offset(296, 740), Offset(292, 748)], [Offset(326, 682), Offset(322, 690)],
    [Offset(320, 664), Offset(318, 672)],
  ]) {
    a.line(pts, const Color(0xFF9D98B2), width: 1.2, opacity: 0.6,
        taper: true);
  }
  a.glow(const Offset(360, 656), 18, const Color(0x66FFE2B8),
      blend: StrokeBlend.screen);
}

// --- The traveler -----------------------------------------------------------

const _skinBase = Color(0xFFE6B48C);
const _skinLight = Color(0xFFF8D7B8);
const _skinShade = Color(0xFFB07A58);

/// Ivory cloth, shaded on the left and lit on the right of [x0] to [x1].
Fill _ivory(double x0, double x1) => Fill.linear(Offset(x0, 0), Offset(x1, 0),
    const [Color(0xFFADA191), Color(0xFFE9E1D3), Color(0xFFFFFBF2)]);

Fill _skinAcross(double x0, double x1) => Fill.linear(Offset(x0, 0),
    Offset(x1, 0), const [_skinShade, _skinBase, _skinLight]);

void _traveler(Artist a) {
  _cape(a);
  _bundle(a);
  _roseArm(a);
  _legs(a);
  _tunic(a);
  _staffArm(a);
  _head(a);
  // Warm light along the edges facing the sun.
  for (final pts in const [
    [Offset(440, 520), Offset(436, 548), Offset(446, 600), Offset(456, 638)],
    [Offset(454, 708), Offset(456, 728), Offset(458, 744)],
    [Offset(428, 486), Offset(446, 504), Offset(456, 520)],
  ]) {
    a.curveLine(pts, _warmLight, width: 2.2, opacity: 0.4, blur: 1.5,
        blend: StrokeBlend.screen, taper: true);
  }
}

void _cape(Artist a) {
  // Streaming out to the left in the wind, rippling along its edge.
  const cape = [
    Offset(392, 466), Offset(360, 472), Offset(325, 484), Offset(292, 500),
    Offset(262, 516), Offset(238, 532), Offset(254, 540), Offset(272, 544),
    Offset(258, 558), Offset(272, 568), Offset(298, 564), Offset(318, 572),
    Offset(338, 588), Offset(356, 596), Offset(362, 566), Offset(368, 530),
    Offset(378, 496), Offset(404, 470),
  ];
  a.area(Artist.spline(cape, closed: true), const Fill.linear(
      Offset(240, 0), Offset(392, 0),
      [Color(0xFF6E4614), Color(0xFFAA7622), Color(0xFFDDA845)]));
  for (final (pts, dark) in const [
    ([Offset(378, 480), Offset(330, 498), Offset(270, 524)], true),
    ([Offset(372, 512), Offset(330, 532), Offset(282, 550)], true),
    ([Offset(368, 548), Offset(340, 566), Offset(310, 566)], true),
    ([Offset(374, 470), Offset(320, 488), Offset(258, 524)], false),
    ([Offset(372, 498), Offset(336, 514), Offset(290, 534)], false),
  ]) {
    a.curveLine(pts, dark ? const Color(0xFF4A2E0C) : const Color(0xFFF2C86A),
        width: dark ? 6 : 4, opacity: dark ? 0.5 : 0.4, blur: 2.5,
        blend: dark ? StrokeBlend.multiply : StrokeBlend.screen, taper: true);
  }
}

void _bundle(Artist a) {
  // The staff, from behind the bundle to the hand, resting on the shoulder.
  a.line(const [Offset(268, 360), Offset(432, 520)], const Color(0xFF5E3F24),
      width: 6);
  a.line(const [Offset(272, 361), Offset(432, 517)], const Color(0xFFB98F60),
      width: 1.6, opacity: 0.8);
  a.blob(const [Offset(264, 364), Offset(246, 374), Offset(236, 394),
    Offset(238, 416), Offset(252, 430), Offset(272, 432), Offset(288, 420),
    Offset(292, 398), Offset(282, 376), Offset(272, 366)],
      Fill.radial(const Offset(278, 390), 52, const [
        Color(0xFFC0504A), Color(0xFF842D2A), Color(0xFF461515),
      ]));
  for (final at in const [
    Offset(256, 392), Offset(272, 404), Offset(250, 414), Offset(266, 422),
    Offset(280, 390),
  ]) {
    a.oval(at, 2.2, 2.2, const Fill(Color(0xCCE4BC62)));
  }
  a.curveLine(const [Offset(262, 372), Offset(258, 398), Offset(262, 426)],
      const Color(0xFF3A1010), width: 3, opacity: 0.5, blur: 1.5,
      blend: StrokeBlend.multiply, taper: true);
  a.blob(const [Offset(262, 360), Offset(270, 354), Offset(276, 362),
    Offset(270, 370)], const Fill(Color(0xFF7A2826)));
}

void _roseArm(Artist a) {
  // The far arm, raised forward with the rose.
  a.area(Artist.spline(Artist.tube(const [
    Offset(426, 482), Offset(440, 502), Offset(452, 522), Offset(466, 512),
    Offset(478, 500),
  ], const [22, 22, 18, 14, 11]), closed: true), _ivory(424, 482));
  for (final pts in const [
    [Offset(432, 490), Offset(440, 506), Offset(446, 518)],
    [Offset(470, 496), Offset(475, 508)],
  ]) {
    a.curveLine(pts, const Color(0xFF6B6050), width: 3.5, opacity: 0.4,
        blur: 1.5, blend: StrokeBlend.multiply, taper: true);
  }
  a.blob(const [Offset(475, 494), Offset(484, 488), Offset(493, 490),
    Offset(495, 498), Offset(489, 505), Offset(478, 504)], _skinAcross(474, 496));
  // The white rose.
  a.curveLine(const [Offset(486, 506), Offset(488, 494), Offset(490, 484)],
      const Color(0xFF3F6B2F), width: 2.2);
  a.blob(const [Offset(486, 512), Offset(478, 516), Offset(472, 512),
    Offset(480, 508)], const Fill(Color(0xFF5E8F3E)));
  // Sepals, then the bloom: an open cup of petals around a curled heart.
  const rose = Offset(492, 477);
  for (final deg in const [215.0, 270.0, 325.0]) {
    final d = Offset.fromDirection(-deg * math.pi / 180);
    a.area([rose + d * 4 + Offset(d.dy, -d.dx) * 2.5, rose + d * 13,
      rose + d * 4 - Offset(d.dy, -d.dx) * 2.5], const Fill(Color(0xFF4E7F36)));
  }
  a.blob([for (var i = 0; i < 9; i++)
    rose + Offset.fromDirection(i * 2 * math.pi / 9, i.isEven ? 11 : 9.5)],
      Fill.radial(rose + const Offset(2, -4), 16, const [
        Colors.white, Color(0xFFF5EFE8), Color(0xFFD3C8C0),
      ]));
  for (final (from, to, r) in const [
    (200.0, 340.0, 10.0), (150.0, 250.0, 9.0), (290.0, 390.0, 9.0),
  ]) {
    a.area([...a.arc(rose, r, from, to, steps: 10),
      ...a.arc(rose + const Offset(0, -1.5), r * 0.62, to - 15, from + 15,
          steps: 8)], const Fill(Color(0xCCD6CBC4)), blur: 0.5);
  }
  a.oval(rose + const Offset(0, -2), 5.5, 4.2, Fill.radial(
      rose + const Offset(1, -4), 7, const [Colors.white, Color(0xFFE6DDD6)]));
  a.line(a.arc(rose + const Offset(0, -2), 2.6, 30, 330, steps: 12),
      const Color(0xFFB4A7A1), width: 0.9, taper: true);
  a.line(a.arc(rose + const Offset(0, -2), 5.2, 20, 160, steps: 8),
      const Color(0xFFBDB1AB), width: 1, taper: true);
  a.glow(rose + const Offset(2, -3), 14, const Color(0x88FFFFFF),
      blend: StrokeBlend.screen);
}

void _legs(Artist a) {
  const boot = Fill.linear(Offset(0, 736), Offset(0, 770), [
    Color(0xFFB57D49), Color(0xFF7A4E2A), Color(0xFF452A16),
  ]);
  // The back leg, then the front one stepping toward the edge.
  a.area(Artist.spline(Artist.tube(const [
    Offset(390, 598), Offset(386, 640), Offset(380, 676), Offset(374, 712),
    Offset(368, 746),
  ], const [26, 22, 16, 15, 11]), closed: true), Fill.linear(
      const Offset(364, 0), const Offset(400, 0),
      const [Color(0xFF8F8372), Color(0xFFCFC2AE), Color(0xFFEDE3D3)]));
  a.blob(const [Offset(358, 738), Offset(378, 738), Offset(382, 750),
    Offset(395, 760), Offset(392, 769), Offset(360, 769), Offset(356, 756)],
      boot);
  a.area(Artist.spline(Artist.tube(const [
    Offset(414, 598), Offset(426, 636), Offset(438, 672), Offset(446, 708),
    Offset(452, 742),
  ], const [27, 22, 16, 15, 11]), closed: true), Fill.linear(
      const Offset(420, 0), const Offset(462, 0),
      const [Color(0xFF9C8F7D), Color(0xFFDBCFBC), Color(0xFFF7EFE2)]));
  a.blob(const [Offset(442, 732), Offset(460, 732), Offset(465, 745),
    Offset(482, 751), Offset(486, 758), Offset(476, 763), Offset(450, 764),
    Offset(442, 752)], boot);
  for (final pts in const [
    [Offset(462, 736), Offset(466, 746), Offset(480, 752)],
    [Offset(380, 742), Offset(384, 752), Offset(392, 759)],
  ]) {
    a.curveLine(pts, const Color(0xFFF0C38E), width: 1.6, opacity: 0.6,
        blend: StrokeBlend.screen, taper: true);
  }
}

void _tunic(Artist a) {
  const hem = [
    Offset(336, 640), Offset(356, 650), Offset(378, 644), Offset(398, 652),
    Offset(420, 644), Offset(440, 650), Offset(456, 640),
  ];
  a.area(Artist.spline(const [
    Offset(392, 464), Offset(378, 472), Offset(368, 490), Offset(364, 520),
    Offset(366, 548), Offset(356, 584), Offset(344, 614), ...hem,
    Offset(448, 610), Offset(440, 580), Offset(434, 548), Offset(438, 520),
    Offset(434, 490), Offset(424, 474), Offset(410, 464),
  ], closed: true), const Fill.linear(Offset(352, 0), Offset(458, 0), [
    Color(0xFF4A1016), Color(0xFF7C2027), Color(0xFFA6343A), Color(0xFFCB4A4D),
  ], [0, 0.35, 0.7, 1]));
  // Folds: soft darks and lights running down the skirt.
  for (final (pts, dark) in const [
    ([Offset(372, 560), Offset(362, 600), Offset(352, 640)], true),
    ([Offset(392, 562), Offset(388, 604), Offset(384, 648)], true),
    ([Offset(416, 560), Offset(422, 604), Offset(428, 646)], true),
    ([Offset(404, 562), Offset(406, 604), Offset(410, 644)], false),
    ([Offset(432, 560), Offset(440, 600), Offset(446, 636)], false),
    ([Offset(380, 486), Offset(376, 516), Offset(378, 540)], true),
  ]) {
    a.curveLine(pts, dark ? const Color(0xFF2E080C) : const Color(0xFFE8858A),
        width: dark ? 6 : 4, opacity: dark ? 0.5 : 0.35, blur: 2.5,
        blend: dark ? StrokeBlend.multiply : StrokeBlend.screen, taper: true);
  }
  // Gold embroidery: the hem, and a vine across the chest.
  a.curveLine(hem, TarotFrame.gold, width: 3.5,
      fill: TarotFrame.goldAcross(336, 456));
  for (final p in hem.skip(1).take(5)) {
    a.oval(p + const Offset(0, -7), 1.8, 1.8, const Fill(TarotFrame.goldPale));
  }
  a.curveLine(const [Offset(384, 476), Offset(398, 494), Offset(418, 500),
    Offset(430, 488)], TarotFrame.gold, width: 1.6, opacity: 0.85, taper: true);
  for (final c in const [Offset(398, 494), Offset(418, 500)]) {
    a.oval(c, 2.6, 2.6, const Fill(TarotFrame.goldPale));
  }
  // Belt with a buckle.
  a.area(Artist.tube(const [Offset(364, 550), Offset(400, 553),
    Offset(437, 548)], const [9, 9, 9]), const Fill.linear(Offset(0, 545),
      Offset(0, 558), [Color(0xFF6E4627), Color(0xFF3B2414)]));
  a.area(const [Offset(398, 546), Offset(410, 546), Offset(410, 559),
    Offset(398, 559)], Fill.linear(const Offset(398, 546),
      const Offset(410, 559), const [TarotFrame.goldPale, TarotFrame.goldDeep]));
  // The shirt's collar.
  a.blob(const [Offset(392, 460), Offset(410, 459), Offset(416, 470),
    Offset(403, 478), Offset(389, 471)], _ivory(388, 416));
}

void _staffArm(Artist a) {
  // The near arm, crossing the chest to hold the staff.
  a.area(Artist.spline(Artist.tube(const [
    Offset(382, 480), Offset(378, 506), Offset(377, 530), Offset(396, 522),
    Offset(412, 511),
  ], const [23, 21, 17, 14, 12]), closed: true), _ivory(366, 414));
  a.curveLine(const [Offset(370, 492), Offset(368, 516), Offset(372, 534)],
      const Color(0xFF6B6050), width: 5, opacity: 0.45, blur: 2,
      blend: StrokeBlend.multiply, taper: true);
  a.curveLine(const [Offset(404, 504), Offset(408, 516)],
      const Color(0xFF6B6050), width: 3, opacity: 0.4, blur: 1.2,
      blend: StrokeBlend.multiply, taper: true);
  // The staff over the hand and shoulder, then the fist around it.
  a.line(const [Offset(378, 470), Offset(434, 522)], const Color(0xFF5E3F24),
      width: 6);
  a.line(const [Offset(381, 469), Offset(434, 519)], const Color(0xFFB98F60),
      width: 1.6, opacity: 0.8);
  a.blob(const [Offset(410, 502), Offset(421, 497), Offset(429, 503),
    Offset(428, 514), Offset(417, 518), Offset(409, 512)], _skinAcross(408, 430));
  for (final pts in const [
    [Offset(414, 506), Offset(424, 503)],
    [Offset(414, 511), Offset(425, 509)],
  ]) {
    a.line(pts, _skinShade, width: 1, opacity: 0.8, taper: true);
  }
}

/// The head, tilted back to look up at the sky. Shapes are given in the
/// head's own coordinates (x toward the face, y down) and turned into place.
void _head(Artist a) {
  const center = Offset(418, 424), tilt = -0.32;
  final cos = math.cos(tilt), sin = math.sin(tilt);
  Offset h(double u, double v) =>
      center + Offset(cos * u - sin * v, sin * u + cos * v);
  List<Offset> hs(List<(double, double)> pts) =>
      [for (final (u, v) in pts) h(u, v)];

  // Neck, with the jaw's shadow on it.
  a.area(Artist.spline(Artist.tube([const Offset(404, 472), h(4, 20)],
      const [15, 14]), closed: true), _skinAcross(396, 420));
  a.glow(h(2, 26), 12, const Color(0x99915C42),
      squash: 0.6, blend: StrokeBlend.multiply);

  // Hair blowing back behind the head.
  const hairDark = Color(0xFF7A3F22), hairMid = Color(0xFFB0703B);
  const hairLight = Color(0xFFE4B06C);
  a.area(Artist.spline(hs(const [
    (-6, -30), (-20, -28), (-32, -20), (-41, -10), (-51, -3), (-62, 0),
    (-55, 7), (-64, 13), (-51, 16), (-46, 24), (-32, 29), (-20, 31),
    (-12, 26), (-9, 12), (-4, -6),
  ]), closed: true), Fill.linear(h(-50, 10), h(0, -28),
      const [hairDark, hairMid, hairLight]));
  // Locks flowing back, inside the hair.
  final locks = math.Random(5);
  for (var i = 0; i < 22; i++) {
    final t = i / 21;
    final start = (6 - t * 16, -29 + t * 22);
    final end = (-58 + t * 30 + locks.nextDouble() * 4, 2 + t * 26);
    // A gentle wave along each lock.
    final m1 = (start.$1 + (end.$1 - start.$1) * 0.35, start.$2 + (end.$2 - start.$2) * 0.35 - 3);
    final m2 = (start.$1 + (end.$1 - start.$1) * 0.7, start.$2 + (end.$2 - start.$2) * 0.7 + 2);
    a.curveLine(hs([start, m1, m2, end]),
        i % 3 == 0 ? hairLight : (i.isEven ? hairMid : hairDark),
        width: 1 + locks.nextDouble() * 0.8, opacity: 0.55, taper: true);
  }

  // Face and skull, lit from the front and above.
  a.area(Artist.spline(hs(const [
    (-20, -14), (-14, -24), (-2, -29), (10, -27), (17, -20), (20, -12),
    (21, -6), (25.5, 3), (22, 6), (23, 10), (21.5, 12.5), (22.5, 15),
    (19, 20), (13, 25), (4, 26), (-6, 22), (-14, 14), (-20, 2),
  ]), closed: true), Fill.radial(h(14, -8), 44,
      const [_skinLight, _skinBase, _skinShade], const [0, 0.45, 1]));
  a.glow(h(-10, 12), 16, const Color(0x80A86A4C),
      blend: StrokeBlend.multiply);
  a.glow(h(12, 4), 7, const Color(0x59E07D6E));

  // Ear.
  a.oval(h(-7, 4), 4.6, 7, Fill.radial(h(-6, 3), 8,
      const [_skinBase, _skinShade]), angle: tilt);
  a.curveLine(hs(const [(-6, 0), (-8.5, 4), (-6.5, 8)]), _skinShade,
      width: 1.2, taper: true);

  // Eye looking up, brow, nose and a quiet smile.
  a.area(Artist.spline(hs(const [(9, -6), (12.5, -8.3), (16.2, -6.5),
    (12.5, -4.6)]), closed: true), const Fill(Color(0xFFF3ECE6)));
  a.oval(h(14, -7.1), 2.3, 2.3, Fill.radial(h(13.6, -7.6), 3,
      const [Color(0xFF7A5232), Color(0xFF3A2414)]));
  a.oval(h(14.4, -7.5), 0.6, 0.6, const Fill(Colors.white));
  a.line(hs(const [(8.4, -6.2), (12, -9.1), (16.9, -6.6)]),
      const Color(0xFF3B2416), width: 1.6, taper: true);
  a.line(hs(const [(10, -4.8), (13, -4.3), (15.6, -5.4)]),
      const Color(0xFF8C5A44), width: 0.8, opacity: 0.6, taper: true);
  a.line(hs(const [(7.5, -12.4), (12.5, -14.3), (17.8, -12.2)]), hairDark,
      width: 2, taper: true);
  a.line(hs(const [(19.6, -4), (23, 1), (24.6, 4.2)]), _skinShade,
      width: 1.6, opacity: 0.7, blur: 0.6, taper: true);
  a.oval(h(21.6, 5.4), 1, 0.7, const Fill(Color(0xFF7A4532)), angle: tilt);
  a.area(Artist.spline(hs(const [(18, 11.6), (22.6, 10.9), (22.4, 15),
    (19, 14.6)]), closed: true), const Fill(Color(0x99C46A62)), blur: 0.5);
  a.line(hs(const [(17.4, 12.6), (20, 13.1), (22.3, 12.1)]),
      const Color(0xFF7E322C), width: 1.3, taper: true);
  // Sunlight along the profile.
  a.curveLine(hs(const [(17, -20), (20.5, -11), (21.5, -5), (25.8, 3),
    (23, 10), (22.6, 15), (19.4, 20.5)]), _warmLight,
      width: 2, opacity: 0.7, blur: 1, blend: StrokeBlend.screen, taper: true);

  // Hair over the top of the head, with strands.
  a.area(Artist.spline(hs(const [
    (-18, -22), (-8, -31), (8, -31), (16, -25), (19.5, -17), (12, -19.5),
    (4, -17.5), (-4, -14), (-12, -8), (-19, -4),
  ]), closed: true), Fill.linear(h(-16, -4), h(14, -30),
      const [hairDark, hairMid, hairLight]));
  for (var i = 0; i < 8; i++) {
    final v0 = -27 + i * 2.2;
    a.curveLine(hs([(14 - i * 2.5, v0), (0 - i * 2, v0 + 1),
      (-14 - i * 1.5, v0 + 6)]), i.isEven ? hairLight : hairDark,
        width: 1.1, opacity: 0.6, taper: true);
  }
  // A few loose strands lifted by the wind.
  for (final pts in const <List<(double, double)>>[
    [(-30, -16), (-44, -14), (-58, -6)],
    [(-40, 6), (-54, 6), (-64, 12)],
  ]) {
    a.curveLine(hs(pts), hairLight, width: 0.9, opacity: 0.6, taper: true);
  }

  // A green cap tilted back, with a long red feather.
  a.area(Artist.spline(hs(const [
    (-10, -33), (-26, -45), (-46, -55), (-70, -60), (-62, -51), (-44, -43),
    (-26, -37),
  ]), closed: true), Fill.linear(h(-50, -62), h(-40, -38), const [
    Color(0xFFE97563), Color(0xFFC0392B), Color(0xFF7A1A1A),
  ]));
  a.curveLine(hs(const [(-10, -34), (-30, -43), (-50, -52), (-68, -58)]),
      const Color(0xFFF7C2B4), width: 1, opacity: 0.85, taper: true);
  for (var i = 1; i < 9; i++) {
    final u = -12.0 - i * 6.5, v = -34.0 - i * 2.9;
    a.line(hs([(u, v), (u - 4, v + 5)]), const Color(0xFF8E2219),
        width: 0.8, opacity: 0.6, taper: true);
  }
  a.area(Artist.spline(hs(const [
    (-22, -20), (-14, -32), (0, -38), (16, -34), (24, -26), (20, -21),
    (8, -24), (-6, -24), (-18, -17),
  ]), closed: true), Fill.linear(h(0, -38), h(0, -20), const [
    Color(0xFF5E8F5A), Color(0xFF2F5A35), Color(0xFF1C3A22),
  ]));
  a.area(Artist.spline(Artist.tube(hs(const [(-20, -19), (0, -23.5),
    (21, -22.5)]), const [4, 4.5, 4]), closed: true),
      const Fill(Color(0xFF1A321E)));
  a.curveLine(hs(const [(-10, -31), (4, -36), (16, -33)]),
      const Color(0xFFA6D19A), width: 1.5, opacity: 0.5, blur: 1,
      blend: StrokeBlend.screen, taper: true);
}
