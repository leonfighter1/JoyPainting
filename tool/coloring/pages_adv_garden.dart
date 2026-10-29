part of 'pages_adv.dart';

/// A long, low cloud.
void _scrollCloud(Pen p, Offset c, double s) {
  p.blob([
    for (final q in const [Offset(-64, 14), Offset(-62, -6), Offset(-42, -20), Offset(-14, -30), Offset(14, -24), Offset(40, -26), Offset(62, -10), Offset(66, 12), Offset(30, 22), Offset(-30, 22)])
      c + q * s,
  ]);
}

/// The page outside the circle round [c]: drawn after it's covered, a
/// line only shows inside the circle.
List<Offset> _outside(Offset c, double r) => [
      Offset(-20, c.dy), const Offset(-20, -20), const Offset(820, -20),
      const Offset(820, 1020), const Offset(-20, 1020), Offset(-20, c.dy),
      Offset(c.dx - r, c.dy),
      ...Pen.arc(c, r, 180, -180),
      Offset(c.dx - r, c.dy),
    ];

void _pavilion(Pen p) {
  // Lotus in the near water.
  _lotus(p, const Offset(190, 800), 0.5);
  p.path(const [Offset(190, 806), Offset(196, 880)], width: _w);
  _pad(p, const Offset(130, 900), 120, 38, 300);
  _pad(p, const Offset(320, 960), 96, 30, 250);
  p.shape(Pen.joined(const [
    [Offset(392, 880), Offset(376, 858), Offset(380, 830), Offset(394, 806)],
    [Offset(394, 806), Offset(408, 830), Offset(410, 858), Offset(392, 880)],
  ]));
  p.path(const [Offset(392, 880), Offset(398, 930)], width: _w);
  // A scholar's rock, worn into holes and ridges.
  for (final (x, y, rx, ry, a) in [(700.0, 806.0, 16.0, 26.0, 0.6), (752.0, 884.0, 13.0, 9.0, -0.2), (648.0, 940.0, 9.0, 15.0, -0.3), (770.0, 760.0, 8.0, 6.0, 0.0)]) {
    p.oval(Offset(x, y), rx, ry, angle: a);
  }
  for (final line in const [
    [Offset(624, 870), Offset(650, 850), Offset(668, 820), Offset(664, 780)],
    [Offset(724, 846), Offset(760, 830), Offset(784, 800)],
    [Offset(676, 900), Offset(700, 930), Offset(716, 980)],
    [Offset(610, 980), Offset(630, 960), Offset(624, 930)],
  ]) {
    p.curve(line, width: _d);
  }
  p.shape(const [
    Offset(612, 1010), Offset(602, 944), Offset(622, 884), Offset(608, 826), Offset(632, 774),
    Offset(668, 744), Offset(702, 760), Offset(720, 722), Offset(758, 702), Offset(792, 728),
    Offset(800, 790), Offset(782, 852), Offset(804, 920), Offset(792, 1010),
  ]);

  // A willow at the left: a stout trunk, branches spreading from it,
  // fronds hanging from their tops and drifting right in the breeze.
  const branches = [
    [Offset(64, 590), Offset(58, 420), Offset(84, 260), Offset(150, 150)],
    [Offset(76, 580), Offset(130, 420), Offset(210, 290), Offset(300, 210)],
    [Offset(56, 600), Offset(24, 450), Offset(20, 300), Offset(40, 200)],
  ];
  for (final (i, branch) in branches.indexed) {
    final s = Artist.spline(branch);
    for (var t = 0.45 + i * 0.03; t <= 1.0; t += 0.09) {
      final base = s[((s.length - 1) * t).round()];
      final len = math.min(120 + 120 * ((t * 13 + i * 0.37) % 1), 500 - base.dy);
      if (len > 60) p.leaf(base, base + Offset(10 + 16 * t, len), 13, width: _d);
    }
  }
  for (final branch in branches) {
    p.shape(Pen.rounded(Pen.tube(branch, (t) => 20 - 14 * t)), width: _d + 0.4);
  }
  for (final bark in const [
    [Offset(40, 980), Offset(52, 900), Offset(46, 830)],
    [Offset(80, 760), Offset(84, 700), Offset(76, 640)],
  ]) {
    p.curve(bark, width: _d - 0.4);
  }
  p.shape(Pen.tube(const [Offset(46, 1010), Offset(66, 860), Offset(58, 720), Offset(68, 580)], (t) => 76 - 26 * t));

  // The pavilion: its finial, the tiled roof sweeping up at the corners,
  // the board under the eaves, frieze, benches, pillars, the terrace.
  const x0 = 545.0;
  p.path(const [Offset(x0, 230), Offset(x0, 206)], width: 3);
  p.oval(const Offset(x0, 238), 6, 8, width: _d);
  p.circle(const Offset(x0, 256), 10);
  const apex = Offset(x0, 264);
  const tipL = Offset(370, 372), tipR = Offset(720, 372);
  const cornerL = Offset(478, 446), cornerR = Offset(612, 446);
  for (var i = 1; i < 5; i++) {
    final e = Offset.lerp(cornerL, cornerR, i / 5)! + const Offset(0, 6);
    p.curve([Offset.lerp(apex, e, 0.1)!, Offset.lerp(apex, e, 0.55)! + const Offset(0, 10), e], width: _d - 0.4);
  }
  for (final (corner, tip) in [(cornerL, tipL), (cornerR, tipR)]) {
    for (var i = 1; i < 3; i++) {
      final e = Offset.lerp(corner, tip, i / 3)! + Offset(0, 14 - 6 * i.toDouble());
      p.curve([Offset.lerp(apex, e, 0.15)!, Offset.lerp(apex, e, 0.55)! + const Offset(0, 12), e], width: _d - 0.4);
    }
    p.curve([apex, Offset.lerp(apex, corner, 0.5)! + Offset((corner.dx - x0) * 0.06, 16), corner], width: _w + 1);
  }
  final eaveL = Artist.spline(const [tipL, Offset(398, 394), Offset(440, 428), cornerL]);
  final eaveFront = Artist.spline(const [cornerL, Offset(545, 456), cornerR]);
  final eaveR = Artist.spline(const [cornerR, Offset(650, 428), Offset(692, 394), tipR]);
  p.shape([
    ...Artist.spline(const [apex, Offset(500, 304), Offset(440, 346), Offset(400, 364), tipL]),
    ...eaveL, ...eaveFront, ...eaveR,
    ...Artist.spline(const [tipR, Offset(690, 364), Offset(650, 346), Offset(590, 304), apex]),
  ]);
  final eave = [...eaveL, ...eaveFront, ...eaveR];
  double drop(Offset q) => 12 * math.min(1, math.min(q.dx - tipL.dx, tipR.dx - q.dx) / 40);
  p.shape([
    for (final q in eave) q - const Offset(0, 2),
    for (final q in eave.reversed) q + Offset(0, drop(q)),
  ]);
  for (final (l, r, top) in [(485.0, 605.0, 470.0), (419.0, 469.0, 456.0), (621.0, 671.0, 456.0)]) {
    for (var x = l + 20; x < r - 8; x += 20) {
      p.path([Offset(x, top + 4), Offset(x, top + 20)], width: _d - 0.6);
    }
    p.shape([Offset(l + 4, top + 4), Offset(r - 4, top + 4), Offset(r - 4, top + 20), Offset(l + 4, top + 20)], width: _d - 0.6);
    p.shape([Offset(l, top), Offset(r, top), Offset(r, top + 24), Offset(l, top + 24)], width: _d);
  }
  for (final (l, r, seat) in [(485.0, 605.0, 578.0), (419.0, 469.0, 566.0), (621.0, 671.0, 566.0)]) {
    for (var x = l + 12; x < r - 4; x += 12) {
      p.path([Offset(x, seat - 30), Offset(x, seat)], width: _d - 0.6);
    }
    p.curve([Offset(l, seat - 30), Offset((l + r) / 2, seat - 38), Offset(r, seat - 30)], width: _d);
    p.shape([Offset(l, seat), Offset(r, seat), Offset(r, seat + 28), Offset(l, seat + 28)], width: _d);
    p.shape([Offset(l + 8, seat + 7), Offset(r - 8, seat + 7), Offset(r - 8, seat + 21), Offset(l + 8, seat + 21)], width: _d - 0.6);
  }
  for (final (x, top, bottom, half) in [(478.0, 452.0, 620.0, 7.0), (612.0, 452.0, 620.0, 7.0), (412.0, 420.0, 606.0, 6.0), (678.0, 420.0, 606.0, 6.0)]) {
    p.shape([Offset(x - half, top), Offset(x + half, top), Offset(x + half, bottom), Offset(x - half, bottom)]);
  }
  for (final (l, r, top) in [(496.0, 594.0, 656.0), (486.0, 604.0, 668.0)]) {
    p.shape([Offset(l, top), Offset(r, top), Offset(r, top + 12), Offset(l, top + 12)]);
  }
  for (var x = 410.0; x < 700; x += 46) {
    p.path([Offset(x, 620), Offset(x, 637)], width: _d - 0.4);
    p.path([Offset(x + 23, 637), Offset(x + 23, 656)], width: _d - 0.4);
  }
  p.path(const [Offset(386, 637), Offset(704, 637)], width: _d - 0.4);
  p.shape(const [Offset(386, 618), Offset(704, 618), Offset(704, 656), Offset(386, 656)]);
  p.shape(const [Offset(398, 606), Offset(692, 606), Offset(704, 618), Offset(386, 618)]);
  // Its reflection, broken by the ripples.
  for (final (y, l, r) in [(690.0, 420.0, 470.0), (700.0, 620.0, 680.0), (716.0, 450.0, 520.0), (730.0, 580.0, 640.0)]) {
    p.path([Offset(l, y), Offset(r, y)], width: _d - 0.6);
  }

  // The arched bridge: posts and rails, the deck, the stones round its
  // arch, its face; the arch's reflection completes the circle.
  const bridge = Offset(205, 650);
  double deck(double x) => 600 - 70 * math.pow(math.cos((x - bridge.dx) / 165 * math.pi / 2), 1.6).toDouble();
  for (var x = 56.0; x <= 354; x += 33) {
    p.path([Offset(x, deck(x) - 30), Offset(x, deck(x))], width: _d);
  }
  p.path([for (var x = 50.0; x <= 360; x += 4) Offset(x, deck(x) - 30)], width: _d);
  p.path([for (var x = 50.0; x <= 360; x += 4) Offset(x, deck(x) - 22)], width: _d - 0.6);
  for (var a = 190.0; a < 360; a += 17) {
    p.path([_polar(bridge, 92, a), _polar(bridge, 108, a)], width: _d - 0.4);
  }
  p.path(Pen.arc(bridge, 108, 180, 360), width: _d);
  p.shape([
    for (var x = 40.0; x <= 370; x += 4) Offset(x, deck(x)),
    const Offset(370, 650),
    ...Pen.arc(bridge, 92, 360, 180),
    const Offset(40, 650),
  ]);
  for (var i = 0; i < 8; i++) {
    final a = 10 + i * 20.0;
    p.path([for (var k = 0.0; k <= 12; k += 2) _polar(bridge, 92 + math.sin(k + i) * 3, a + k)], width: _d);
  }
  for (final (x, y, half) in [(205.0, 770.0, 40.0), (450.0, 760.0, 60.0), (560.0, 790.0, 70.0), (300.0, 830.0, 50.0), (500.0, 880.0, 64.0), (420.0, 980.0, 70.0), (110.0, 700.0, 30.0)]) {
    p.curve([Offset(x - half, y), Offset(x - half / 2, y - 4), Offset(x, y), Offset(x + half / 2, y + 4), Offset(x + half, y)], width: _d - 0.4);
  }
  // The far bank with shrubs; a pagoda on the hill; the hills.
  p.path(const [Offset(-10, 650), Offset(810, 650)], width: _d);
  for (final (x, r) in [(360.0, 22.0), (390.0, 18.0), (740.0, 26.0), (780.0, 20.0)]) {
    _crown(p, Offset(x, 640 - r * 0.4), r, width: _d);
  }
  p.cover(const [Offset(-10, 650), Offset(810, 650), Offset(810, 1010), Offset(-10, 1010)]);
  {
    const t = Offset(330, 330);
    for (var i = 0; i < 4; i++) {
      final y = t.dy + 18 - i * 22.0, half = 22 - i * 4.0;
      p.shape([Offset(t.dx - half - 6, y), Offset(t.dx + half + 6, y), Offset(t.dx + half - 2, y - 8), Offset(t.dx - half + 2, y - 8)], width: _d);
      p.shape([Offset(t.dx - half + 4, y), Offset(t.dx + half - 4, y), Offset(t.dx + half - 4, y + 16), Offset(t.dx - half + 4, y + 16)], width: _d);
    }
    p.path([t + const Offset(0, -48), t + const Offset(0, -70)], width: _d);
  }
  for (final (ridge, ink) in [
    (const [Offset(-10, 480), Offset(120, 420), Offset(240, 370), Offset(330, 362), Offset(420, 410), Offset(560, 380), Offset(700, 430), Offset(810, 400)], _w),
    (const [Offset(-10, 380), Offset(150, 300), Offset(260, 330), Offset(400, 250), Offset(520, 300), Offset(640, 260), Offset(810, 320)], _d),
  ]) {
    p.curve(ridge, width: ink);
    p.cover([...Artist.spline(ridge), const Offset(810, 1010), const Offset(-10, 1010)]);
  }
  // The moon and curling clouds.
  p.circle(const Offset(660, 130), 50);
  _scrollCloud(p, const Offset(470, 150), 1);
  _scrollCloud(p, const Offset(750, 210), 0.75);
}

/// A tea bowl on a saucer: [c] is the middle of its rim, [s] its size.
void _teaBowl(Pen p, Offset c, double s) {
  Offset at(double x, double y) => c + Offset(x, y) * s;
  p.oval(at(0, 6), 52 * s, 11 * s, width: _d);
  p.oval(c, 62 * s, 15 * s);
  // A band of little waves under the rim.
  p.path([for (var x = -56.0; x <= 56; x += 3) at(x, 26 + 13 * (1 - (x / 60) * (x / 60)) + 3 * math.sin(x / 5))], width: _d - 0.6);
  p.path([for (var x = -54.0; x <= 54; x += 3) at(x, 36 + 13 * (1 - (x / 58) * (x / 58)))], width: _d - 0.6);
  p.path([at(-34, 80), at(34, 80)], width: _d);
  p.shape(Pen.joined([
    [at(-62, 0), at(-58, 34), at(-40, 66), at(-34, 80)],
    [at(-34, 80), at(-36, 90), at(36, 90)],
    [at(36, 90), at(34, 80)],
    [at(34, 80), at(40, 66), at(58, 34), at(62, 0)],
  ]));
  p.oval(at(0, 92), 62 * s, 14 * s, width: _d - 0.4);
  p.oval(at(0, 92), 96 * s, 26 * s);
}

void _teaset(Pen p) {
  // Two tea bowls in front.
  _teaBowl(p, const Offset(190, 790), 1.05);
  _teaBowl(p, const Offset(610, 760), 0.9);

  // The teapot: knob, lid, the plum spray and the band of diamonds on
  // its belly, its foot, body, then the spout and handle behind it.
  const pot = Offset(380, 560);
  p.circle(const Offset(380, 424), 13);
  p.path(const [Offset(372, 436), Offset(388, 436)], width: _d);
  p.shape([...Pen.arc(const Offset(380, 474), 62, 180, 360), const Offset(442, 476), const Offset(318, 476)]);
  p.oval(const Offset(380, 476), 74, 16);
  for (final (c, r) in const [(Offset(330, 604), 13.0), (Offset(372, 592), 15.0), (Offset(420, 610), 12.0)]) {
    _blossom(p, c, r * 2);
  }
  for (final (x, y) in const [(306.0, 616.0), (446.0, 594.0)]) {
    p.circle(Offset(x, y), 6, width: _d - 0.4);
  }
  p.curve(const [Offset(290, 630), Offset(330, 612), Offset(380, 596), Offset(440, 600), Offset(470, 585)], width: _d + 1);
  double bulge(double x) => 12 * (1 - ((x - pot.dx) / 140) * ((x - pot.dx) / 140));
  for (var x = 264.0; x <= 500; x += 26) {
    final y = 547 + bulge(x);
    p.shape([Offset(x, y - 11), Offset(x + 10, y), Offset(x, y + 11), Offset(x - 10, y)], width: _d - 0.6);
  }
  for (final y in [532.0, 562.0]) {
    p.path([for (var x = 236.0; x <= 524; x += 4) Offset(x, y + bulge(x))], width: _d);
  }
  p.path([for (var x = 300.0; x <= 460; x += 4) Offset(x, 648 + bulge(x) * 0.4)], width: _d);
  final body = Artist.spline(const [Offset(310, 478), Offset(262, 510), Offset(240, 565), Offset(256, 620), Offset(296, 652), Offset(306, 668), Offset(380, 674), Offset(454, 668), Offset(464, 652), Offset(504, 620), Offset(520, 565), Offset(498, 510), Offset(450, 478)]);
  p.shape(body);
  p.oval(const Offset(156, 470), 13, 7, angle: -0.5, width: _d);
  p.shape(Pen.tube(const [Offset(268, 598), Offset(214, 576), Offset(178, 530), Offset(158, 472)], (t) => 48 - 28 * t));
  p.blob(const [Offset(512, 526), Offset(554, 518), Offset(578, 548), Offset(572, 592), Offset(530, 614), Offset(512, 606)]);
  p.blob(const [Offset(500, 500), Offset(562, 488), Offset(606, 530), Offset(600, 600), Offset(542, 638), Offset(508, 628)]);

  // A plum branch in a vase at the back.
  for (final (c, r) in const [(Offset(600, 240), 20.0), (Offset(538, 186), 18.0), (Offset(470, 150), 16.0), (Offset(690, 196), 17.0), (Offset(652, 300), 15.0), (Offset(712, 140), 13.0)]) {
    _blossom(p, c, r * 2);
  }
  for (final (x, y) in const [(500.0, 168.0), (430.0, 136.0), (668.0, 168.0), (624.0, 268.0), (720.0, 300.0)]) {
    p.circle(Offset(x, y), 7, width: _d - 0.4);
  }
  p.shape(Pen.rounded(Pen.tube(const [Offset(690, 368), Offset(670, 300), Offset(600, 240), Offset(520, 180), Offset(420, 130)], (t) => 14 - 9 * t)));
  p.shape(Pen.rounded(Pen.tube(const [Offset(666, 290), Offset(690, 230), Offset(700, 170), Offset(730, 120)], (t) => 9 - 5 * t)));
  p.shape(Pen.rounded(Pen.tube(const [Offset(686, 340), Offset(720, 320), Offset(740, 290)], (t) => 7 - 3 * t)));
  // The vase: rim, bands of waves and petals, its body. Each band runs
  // just from one side of it to the other.
  final vase = Artist.spline(const [Offset(674, 362), Offset(676, 378), Offset(640, 400), Offset(626, 440), Offset(634, 520), Offset(650, 600), Offset(654, 650), Offset(726, 650), Offset(730, 600), Offset(746, 520), Offset(754, 440), Offset(740, 400), Offset(704, 378), Offset(706, 362)]);
  List<Offset> across(double Function(double x) y) => [
        for (var x = 600.0; x <= 780; x += 2)
          if (Pen.inside(Offset(x, y(x)), vase)) Offset(x, y(x)),
      ];
  p.oval(const Offset(690, 364), 18, 5, width: _d);
  p.path(across((x) => 600 + 6 * math.sin((x - 640) / 8) + 4 * (1 - ((x - 690) / 50) * ((x - 690) / 50))), width: _d - 0.6);
  for (final y0 in [430.0, 470.0, 584.0, 616.0]) {
    p.path(across((x) => y0 + 12 - 6 * ((x - 690) / 70) * ((x - 690) / 70)), width: _d);
  }
  for (var i = 0; i < 5; i++) {
    final x = 646 + i * 22.0;
    p.shape(Pen.joined([
      [Offset(x - 9, 444), Offset(x - 6, 456), Offset(x, 470)],
      [Offset(x, 470), Offset(x + 6, 456), Offset(x + 9, 444)],
    ]), width: _d - 0.6);
  }
  p.shape(vase);

  // The table with a runner on it.
  p.shape(const [Offset(126, 702), Offset(674, 702), Offset(722, 888), Offset(78, 888)], width: _d);
  p.shape(const [Offset(110, 690), Offset(690, 690), Offset(742, 902), Offset(58, 902)]);
  for (final y in [956.0, 980.0]) {
    p.curve([Offset(-10, y), Offset(200, y - 4), Offset(500, y + 3), Offset(810, y - 2)], width: _d - 0.6);
  }
  p.path(const [Offset(-10, 930), Offset(810, 930)]);
  p.path(const [Offset(-10, 660), Offset(810, 660)]);
  p.cover(const [Offset(-10, 660), Offset(810, 660), Offset(810, 1010), Offset(-10, 1010)]);
  // A round moon window in the wall behind, bamboo outside it.
  const window = Offset(360, 300);
  p.circle(window, 220, covers: false);
  p.circle(window, 240, covers: false);
  p.cover(_outside(window, 220));
  for (final (x, lean) in [(250.0, 0.08), (430.0, -0.05), (520.0, 0.03)]) {
    Offset on(double y) => Offset(x + (600 - y) * lean, y);
    for (var y = 520.0; y > 60; y -= 110) {
      p.curve([on(y) + const Offset(-14, 4), on(y), on(y) + const Offset(14, 4)], width: _d - 0.4);
      final k = ((y / 110).round().isEven ? 1.0 : -1.0);
      p.leaf(on(y), on(y) + Offset(k * 72, -40), 20, width: _d);
      p.leaf(on(y - 10), on(y - 10) + Offset(k * 60, -64), 18, width: _d);
    }
    p.shape([on(600) + const Offset(-14, 0), on(40) + const Offset(-14, 0), on(40) + const Offset(14, 0), on(600) + const Offset(14, 0)], width: _d);
  }
}
