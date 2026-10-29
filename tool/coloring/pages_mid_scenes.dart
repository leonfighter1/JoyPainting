part of 'pages_mid.dart';

/// A crescent: the part of circle [c1] outside circle [c2].
List<Offset> _crescent(Offset c1, double r1, Offset c2, double r2) {
  final ring = Pen.ovalPoints(c1, r1, r1);
  final keep = [for (final q in ring) (q - c2).distance >= r2];
  // Start right after the cut, so the outer arc runs tip to tip.
  var start = 0;
  for (var i = 0; i < ring.length; i++) {
    if (!keep[i] && keep[(i + 1) % ring.length]) start = (i + 1) % ring.length;
  }
  final outer = [
    for (var i = 0; i < ring.length; i++)
      if (keep[(start + i) % ring.length]) ring[(start + i) % ring.length],
  ];
  double deg(Offset v) => math.atan2(v.dy, v.dx) * 180 / math.pi;
  final from = deg(outer.last - c2);
  var span = deg(outer.first - c2) - from;
  while (span > 180) {
    span -= 360;
  }
  while (span < -180) {
    span += 360;
  }
  return [...outer, ...Pen.arc(c2, r2, from, from + span)];
}

/// Crenellations along the top of a wall from [x0] to [x1] at [y]: [n]
/// merlons [h] high, as the wall's top edge, left to right.
List<Offset> _merlons(double x0, double x1, double y, int n, double h) {
  final m = (x1 - x0) / (n * 1.4 - 0.4);
  return [
    for (var i = 0; i < n; i++) ...[
      Offset(x0 + i * m * 1.4, y),
      Offset(x0 + i * m * 1.4, y - h),
      Offset(x0 + i * m * 1.4 + m, y - h),
      Offset(x0 + i * m * 1.4 + m, y),
    ],
  ];
}

/// An arched opening, [r] wide each side, from [top] down to [bottom].
List<Offset> _arch(double cx, double top, double bottom, double r) => [
      Offset(cx - r, bottom),
      ...Pen.arc(Offset(cx, top + r), r, 180, 360),
      Offset(cx + r, bottom),
    ];

/// A small five-petal flower on a stem, with a leaf.
void _flower(Pen p, Offset c, double r) {
  p.circle(c, r * 0.7);
  for (var i = 0; i < 5; i++) {
    p.circle(c + Offset.fromDirection(i * 2 * math.pi / 5 - math.pi / 2, r * 1.15), r * 0.8);
  }
  p.leaf(c + Offset(0, r * 3.2), c + Offset(r * 2.4, r * 1.9), r * 0.9);
  p.path([c + Offset(0, r * 1.5), c + Offset(0, r * 5)], width: 4);
}

/// A leafy crown: a big ball of leaves with smaller ones behind it.
void _crown(Pen p, Offset c, double r, {double? width}) {
  p.circle(c, r, width: width);
  for (final a in [-160.0, -122.0, -86.0, -52.0, -18.0, 16.0, 164.0]) {
    p.circle(c + Offset.fromDirection(a * math.pi / 180, r * 0.8), r * 0.5, width: width);
  }
}

/// A round tree on a trunk standing at [base].
void _tree(Pen p, Offset base, double s) {
  _crown(p, base + Offset(0, -118 * s), 56 * s);
  p.shape([base + Offset(-12 * s, -60 * s), base + Offset(12 * s, -60 * s), base + Offset(16 * s, 0), base + Offset(-16 * s, 0)]);
}

void _castle(Pen p) {
  // Flowers and trees in front, the path with its stones, then the hill.
  for (final (x, y, r) in [(60.0, 920.0, 15.0), (140.0, 955.0, 12.0), (680.0, 940.0, 14.0), (750.0, 905.0, 12.0)]) {
    _flower(p, Offset(x, y), r);
  }
  for (final (x, y, rx, ry) in [(398.0, 712.0, 16.0, 6.0), (380.0, 748.0, 20.0, 7.0), (396.0, 790.0, 24.0, 9.0), (432.0, 836.0, 28.0, 10.0), (418.0, 888.0, 32.0, 12.0), (400.0, 944.0, 38.0, 14.0)]) {
    p.oval(Offset(x, y), rx, ry, width: _d);
  }
  p.curve(const [Offset(362, 690), Offset(342, 760), Offset(372, 840), Offset(330, 920), Offset(290, 1010)]);
  p.curve(const [Offset(438, 690), Offset(430, 760), Offset(480, 840), Offset(470, 920), Offset(540, 1010)]);
  _tree(p, const Offset(110, 860), 1);
  _tree(p, const Offset(690, 850), 0.9);
  const hill = [Offset(-10, 702), Offset(200, 690), Offset(400, 684), Offset(600, 690), Offset(810, 700)];
  p.curve(hill);
  p.cover([...Artist.spline(hill), const Offset(810, 1010), const Offset(-10, 1010)]);
  // Bushes on the hill.
  for (final (x, r) in [(52.0, 34.0), (748.0, 36.0)]) {
    _crown(p, Offset(x, 700 - r * 0.4), r);
  }

  // Flags, flying right, on the roofs' tips.
  for (final (x, y) in [(200.0, 196.0), (600.0, 196.0), (400.0, 116.0)]) {
    p.shape([Offset(x, y - 44), Offset(x + 44, y - 36), Offset(x + 30, y - 28), Offset(x + 44, y - 20), Offset(x, y - 14)]);
    p.path([Offset(x, y), Offset(x, y - 48)], width: 4);
  }
  // Cone roofs, with bands across, over the towers.
  void roof(Offset tip, double left, double right, double y) {
    final base = [Offset(left, y), Offset((left + right) / 2, y + 8), Offset(right, y)];
    for (final t in [0.4, 0.7]) {
      p.curve([Offset.lerp(tip, base[0], t)!, Offset.lerp(tip, base[1], t)!, Offset.lerp(tip, base[2], t)!], width: _d);
    }
    p.shape([tip, ...Artist.spline(base)]);
  }

  roof(const Offset(200, 196), 132, 268, 332);
  roof(const Offset(600, 196), 532, 668, 332);
  roof(const Offset(400, 116), 330, 470, 252);
  for (final x in [200.0, 600.0]) {
    p.shape([Offset(x - 56, 334), Offset(x + 56, 334), Offset(x + 56, 352), Offset(x - 56, 352)]);
  }
  // Windows, a round one with a cross, a few bricks.
  for (final (x, top, r) in [(200.0, 400.0, 16.0), (200.0, 520.0, 16.0), (600.0, 400.0, 16.0), (600.0, 520.0, 16.0), (338.0, 446.0, 12.0), (462.0, 446.0, 12.0)]) {
    p.shape(_arch(x, top, top + r * 3.2, r));
  }
  p.path(const [Offset(400, 296), Offset(400, 336)], width: _d);
  p.path(const [Offset(380, 316), Offset(420, 316)], width: _d);
  p.circle(const Offset(400, 316), 20);
  for (final (x, y) in [(166.0, 640.0), (212.0, 470.0), (258.0, 600.0), (316.0, 540.0), (452.0, 520.0), (612.0, 630.0), (512.0, 610.0), (566.0, 470.0)]) {
    p.shape([Offset(x, y), Offset(x + 28, y), Offset(x + 28, y + 13), Offset(x, y + 13)], width: 3);
  }
  // The gate with its portcullis.
  for (final x in [376.0, 392.0, 408.0, 424.0]) {
    p.path([Offset(x, 620 - math.sqrt(40 * 40 - (x - 400) * (x - 400))), Offset(x, 700)], width: 3);
  }
  for (final y in [628.0, 660.0]) {
    p.path([Offset(360, y), Offset(440, y)], width: 3);
  }
  p.shape(_arch(400, 580, 700, 40));
  // The keep, the towers, the walls between, the tall tower behind.
  p.shape([const Offset(300, 720), ..._merlons(300, 500, 400, 5, 20), const Offset(500, 720)]);
  for (final x in [200.0, 600.0]) {
    p.shape([Offset(x - 50, 352), Offset(x + 50, 352), Offset(x + 50, 720), Offset(x - 50, 720)]);
  }
  p.shape([const Offset(250, 720), ..._merlons(250, 300, 500, 2, 16), const Offset(300, 720)]);
  p.shape([const Offset(500, 720), ..._merlons(500, 550, 500, 2, 16), const Offset(550, 720)]);
  p.shape(const [Offset(346, 252), Offset(454, 252), Offset(454, 420), Offset(346, 420)]);

  // Far hills; clouds; a rainbow behind everything; birds.
  for (final far in const [
    [Offset(-10, 620), Offset(120, 570), Offset(260, 600), Offset(340, 640)],
    [Offset(470, 640), Offset(560, 590), Offset(690, 560), Offset(810, 600)],
  ]) {
    p.curve(far);
    p.cover([...Artist.spline(far), Offset(far.last.dx, 1010), Offset(far.first.dx, 1010)]);
  }
  _cloud(p, const Offset(150, 135), 0.9);
  _cloud(p, const Offset(660, 95), 0.75);
  for (var i = 0; i < 5; i++) {
    p.path(Pen.arc(const Offset(400, 760), 300.0 + i * 24, 180, 360));
  }
  _gull(p, const Offset(300, 180), 0.8);
  _gull(p, const Offset(345, 150), 0.6);
  _gull(p, const Offset(520, 150), 0.7);
}

void _underwater(Pen p) {
  // Bubbles, a jellyfish, a little school of fish.
  for (final (x, y, r) in [(196.0, 300.0, 13.0), (180.0, 262.0, 9.0), (194.0, 232.0, 6.0), (296.0, 650.0, 10.0), (310.0, 618.0, 7.0), (640.0, 600.0, 12.0), (656.0, 566.0, 8.0), (700.0, 420.0, 15.0), (690.0, 378.0, 10.0)]) {
    p.circle(Offset(x, y), r, width: 3);
  }
  {
    const j = Offset(350, 140);
    p.path(Pen.arc(j + const Offset(0, 6), 30, 200, 340), width: 3);
    p.shape([
      ...Pen.arc(j, 48, 180, 360),
      for (final dx in [36.0, 12.0, -12.0, -36.0]) ...Pen.arc(j + Offset(dx, 0), 12, 0, 180),
    ]);
    for (final dx in [-30.0, -10.0, 10.0, 30.0]) {
      p.path([for (var y = 12.0; y <= 130 - dx.abs(); y += 4) j + Offset(dx + 6 * math.sin(y / 14 + dx), y)], width: 3);
    }
  }
  for (final (x, y, s) in [(90.0, 150.0, 1.0), (160.0, 120.0, 0.85), (150.0, 185.0, 0.9), (240.0, 150.0, 0.8)]) {
    final c = Offset(x, y);
    p.circle(c + Offset(-14 * s, -3 * s), 3.5, width: 2.5);
    p.oval(c, 26 * s, 12 * s, width: 4);
    p.shape([c + Offset(22 * s, 0), c + Offset(42 * s, -12 * s), c + Offset(42 * s, 12 * s)], width: 4);
  }

  // A clownfish, facing right.
  {
    const c = Offset(170, 720);
    p.circle(c + const Offset(46, -8), 3.5, width: 3);
    p.circle(c + const Offset(46, -8), 9, width: 3.5);
    p.curve([c + const Offset(60, 10), c + const Offset(68, 14), c + const Offset(74, 8)], width: 3);
    p.oval(c + const Offset(4, 18), 20, 10, angle: 0.5, width: _d);
    for (final x in [-36.0, 8.0, 44.0]) {
      final h = 40 * math.sqrt(math.max(0, 1 - (x / 72) * (x / 72)));
      p.curve([c + Offset(x - 6, -h), c + Offset(x + 2, 0), c + Offset(x - 6, h)], width: _d);
      p.curve([c + Offset(x + 8, -h), c + Offset(x + 16, 0), c + Offset(x + 8, h)], width: _d);
    }
    p.oval(c, 72, 40);
    p.blob([c + const Offset(-20, -36), c + const Offset(-6, -62), c + const Offset(24, -60), c + const Offset(40, -34)]);
    p.blob([c + const Offset(-10, 36), c + const Offset(4, 58), c + const Offset(26, 38)]);
    p.blob([c + const Offset(-64, -6), c + const Offset(-104, -40), c + const Offset(-94, 0), c + const Offset(-104, 40), c + const Offset(-64, 6)]);
  }

  // An angelfish, facing left, with long fins.
  {
    const c = Offset(650, 230);
    p.circle(c + const Offset(-34, -10), 3.5, width: 3);
    p.circle(c + const Offset(-34, -10), 9, width: 3.5);
    for (final x in [-8.0, 16.0]) {
      p.curve([c + Offset(x + 4, -50 + x.abs() * 0.4), c + Offset(x, 0), c + Offset(x + 4, 50 - x.abs() * 0.4)], width: _d);
    }
    p.blob([c + const Offset(-64, 4), c + const Offset(-30, -40), c + const Offset(4, -54), c + const Offset(40, -30), c + const Offset(46, 0), c + const Offset(40, 30), c + const Offset(4, 54), c + const Offset(-30, 40)]);
    for (final s in [-1.0, 1.0]) {
      p.shape(Pen.joined([
        [c + Offset(-10, s * 46), c + Offset(30, s * 100), c + Offset(84, s * 150)],
        [c + Offset(84, s * 150), c + Offset(64, s * 80), c + Offset(40, s * 28)],
      ]));
    }
    p.blob([c + const Offset(44, 0), c + const Offset(84, -34), c + const Offset(94, 0), c + const Offset(84, 34)]);
  }

  // The sea turtle, swimming up and left: the shell's plates, the shell,
  // then the head and flippers under it.
  {
    const c = Offset(440, 430);
    const turn = 200 * math.pi / 180;
    Offset at(double x, double y) =>
        c + Offset(x * math.cos(turn) - y * math.sin(turn), x * math.sin(turn) + y * math.cos(turn));
    List<Offset> all(List<Offset> pts) => [for (final q in pts) at(q.dx, q.dy)];
    List<Offset> hex(double x) => [for (var i = 0; i < 6; i++) Offset(x, 0) + Offset.fromDirection(i * math.pi / 3, 36)];
    for (final x in [72.0, 0.0, -72.0]) {
      p.shape(all(hex(x)), width: _d);
    }
    // Side plates: from the middle plates' corners out to the rim.
    for (final y in [1.0, -1.0]) {
      for (final (x0, x1) in [(90.0, 96.0), (18.0, 22.0), (-54.0, -56.0), (-90.0, -100.0)]) {
        final hw = 85 * math.sqrt(math.max(0, 1 - (x1 / 118) * (x1 / 118)));
        p.path(all([Offset(x0, y * 31), Offset(x1, y * hw)]), width: _d);
      }
    }
    for (var i = 0; i < 14; i++) {
      final t = i * 2 * math.pi / 14 + 0.1;
      p.path(all([Offset(118 * math.cos(t), 85 * math.sin(t)), Offset(140 * math.cos(t), 105 * math.sin(t))]), width: _d);
    }
    p.shape(all(Pen.ovalPoints(Offset.zero, 118, 85)), width: _d);
    p.shape(all(Pen.ovalPoints(Offset.zero, 140, 105)));
    // Head with eyes, then the flippers with a crease each, and the tail.
    for (final y in [-17.0, 17.0]) {
      p.circle(at(204, y), 3, width: 3);
      p.oval(at(200, y), 9, 7, angle: turn, width: 3.5);
    }
    p.blob(all(const [Offset(120, -36), Offset(176, -40), Offset(222, -24), Offset(236, 0), Offset(222, 24), Offset(176, 40), Offset(120, 36)]));
    for (final y in [1.0, -1.0]) {
      p.shape(Pen.joined([
        all([Offset(96, y * 70), Offset(110, y * 140), Offset(70, y * 200), Offset(-24, y * 232)]),
        all([Offset(-24, y * 232), Offset(10, y * 170), Offset(20, y * 110), Offset(30, y * 80)]),
      ]));
      p.blob(all([Offset(-110, y * 60), Offset(-150, y * 110), Offset(-186, y * 112), Offset(-160, y * 70)]));
    }
    p.shape(all(const [Offset(-130, -14), Offset(-176, 0), Offset(-130, 14)]));
  }

  // The seabed: a shell, a starfish, stones, corals and kelp, then the
  // sand's edge.
  {
    const s = Offset(500, 940);
    for (var i = 1; i < 6; i++) {
      p.path([s + const Offset(0, 22), s + Offset.fromDirection(math.pi + i * math.pi / 6, 48)], width: 3);
    }
    p.shape([s + const Offset(-14, 22), ...Pen.arc(s, 50, 180, 360), s + const Offset(14, 22)]);
    p.star(const Offset(220, 930), 44, inner: 0.5);
    p.blob(const [Offset(570, 975), Offset(590, 948), Offset(630, 946), Offset(650, 975)]);
    p.blob(const [Offset(60, 985), Offset(80, 955), Offset(120, 958), Offset(130, 990)]);
    // Brain coral: a dome with wiggly grooves.
    for (final y in [850.0, 880.0, 910.0]) {
      final half = math.sqrt(100 * 100 - (y - 920) * (y - 920)) - 8;
      p.path([for (var x = 660 - half; x <= 660 + half; x += 4) Offset(x, y + 7 * math.sin(x / 9))], width: 3);
    }
    p.shape([...Pen.arc(const Offset(660, 920), 100, 180, 360), const Offset(760, 930), const Offset(560, 930)]);
    // A sea anemone waving its arms.
    p.shape(const [Offset(434, 846), Offset(486, 846), Offset(494, 900), Offset(426, 900)]);
    for (var i = 0; i < 7; i++) {
      final a = (-165 + i * 25) * math.pi / 180;
      final d = Offset(math.cos(a), math.sin(a));
      final side = Offset(-d.dy, d.dx);
      p.shape(Pen.rounded(Pen.tube([
        const Offset(460, 850),
        const Offset(460, 850) + d * 30 + side * 6,
        const Offset(460, 850) + d * (58 - (i - 3).abs() * 3) - side * 6,
      ], (t) => 14 - 4 * t)));
    }
    // Tube sponges, the short ones in front.
    for (final (x, top, w) in [(282.0, 812.0, 36.0), (380.0, 800.0, 38.0), (330.0, 750.0, 46.0)]) {
      final rim = Offset(x, top);
      p.oval(rim, w * 0.3, w * 0.09, width: 3);
      p.oval(rim, w / 2, w * 0.18);
      p.shape([rim + Offset(-w / 2, 0), rim + Offset(w / 2, 0), Offset(x + w * 0.58, 900), Offset(x - w * 0.58, 900)]);
    }
    // Kelp swaying at the sides.
    for (final (x, top, phase) in [(60.0, 430.0, 0.0), (130.0, 600.0, 1.4), (745.0, 520.0, 2.2)]) {
      final spine = [for (var y = 1010.0; y >= top; y -= 30) Offset(x + 18 * math.sin(y / 70 + phase), y)];
      p.curve(spine.sublist(0, spine.length - 1), width: 3);
      p.shape(Pen.tube(spine, (t) => 34 - 30 * t));
    }
    const sand = [Offset(-10, 880), Offset(150, 868), Offset(320, 884), Offset(480, 872), Offset(640, 886), Offset(810, 874)];
    p.curve(sand);
    p.cover([...Artist.spline(sand), const Offset(810, 1010), const Offset(-10, 1010)]);
  }

  // The surface far above.
  p.path(_wave(56, amp: 6, length: 90));
}

/// A hot-air balloon at [c] (the middle of its round top), [s] times the
/// big one's size: panels, bands, ropes and a woven basket.
void _balloon(Pen p, Offset c, double s) {
  Offset at(double x, double y) => c + Offset(x, y) * s;
  double half(double y) => y <= 65
      ? math.sqrt(math.max(0, 130 * 130 - y * y))
      : 112.6 + (32 - 112.6) * math.pow((y - 65) / 135, 0.8);
  final lw = math.max(3.0, _w * math.sqrt(s));
  final dw = math.max(2.5, _d * math.sqrt(s));
  // The basket: weave, rim, body; ropes; the skirt.
  for (final x in [-13.0, 13.0]) {
    p.path([at(x, 298), at(x, 344)], width: dw);
  }
  p.path([at(-40, 321), at(40, 321)], width: dw);
  p.shape([at(-44, 284), at(44, 284), at(44, 298), at(-44, 298)], width: lw);
  p.shape([at(-40, 298), at(40, 298), at(36, 344), at(-36, 344)], width: lw);
  for (final (x0, x1) in [(-28.0, -38.0), (-10.0, -12.0), (10.0, 12.0), (28.0, 38.0)]) {
    p.path([at(x0, 222), at(x1, 284)], width: dw);
  }
  p.shape([at(-32, 200), at(32, 200), at(26, 224), at(-26, 224)], width: lw);
  // Bands bulge up: the balloon is above our eyes.
  for (final y in [-30.0, 70.0]) {
    p.curve([at(-half(y), y), at(0, y - 14), at(half(y), y)], width: dw);
  }
  for (final k in [-0.72, -0.38, 0.0, 0.38, 0.72]) {
    p.path([for (var y = -129.0; y <= 200; y += 4) at(k * half(y), y)], width: dw);
  }
  p.shape([
    for (var y = -130.0; y <= 200; y += 3) at(half(y), y),
    for (var y = 200.0; y >= -130; y -= 3) at(-half(y), y),
  ], width: lw);
}

void _balloons(Pen p) {
  _gull(p, const Offset(470, 120), 0.6);
  _gull(p, const Offset(505, 98), 0.5);
  _balloon(p, const Offset(330, 330), 1);
  _balloon(p, const Offset(130, 640), 0.42);
  _balloon(p, const Offset(615, 240), 0.62);
  _cloud(p, const Offset(120, 140), 0.85);
  _cloud(p, const Offset(640, 520), 0.8);
  _cloud(p, const Offset(700, 70), 0.6);

  // The countryside: trees and a farmhouse, a river, fields on the near
  // hill, the far hills.
  for (final (x, y, r) in [(80.0, 820.0, 30.0), (150.0, 806.0, 24.0), (700.0, 812.0, 28.0), (560.0, 760.0, 18.0), (250.0, 745.0, 16.0)]) {
    p.circle(Offset(x, y), r);
    p.path([Offset(x, y + r), Offset(x, y + r * 2)], width: 4);
  }
  p.shape(const [Offset(612, 846), Offset(650, 812), Offset(688, 846)]);
  p.shape(const [Offset(642, 862), Offset(658, 862), Offset(658, 892), Offset(642, 892)], width: _d);
  p.shape(const [Offset(620, 846), Offset(680, 846), Offset(680, 892), Offset(620, 892)]);
  const riverL = [Offset(470, 742), Offset(440, 800), Offset(470, 880), Offset(380, 1010)];
  const riverR = [Offset(490, 742), Offset(480, 800), Offset(530, 880), Offset(500, 1010)];
  for (final y in [820.0, 900.0, 960.0]) {
    final x = 470 + (y - 800) * 0.1;
    p.curve([Offset(x, y), Offset(x + 12, y - 6), Offset(x + 24, y)], width: 3);
  }
  p.curve(riverL);
  p.curve(riverR);
  p.cover([...Artist.spline(riverL), ...Artist.spline(riverR).reversed]);
  for (final field in const [
    [Offset(-10, 900), Offset(160, 880), Offset(300, 900), Offset(452, 870)],
    [Offset(200, 1010), Offset(230, 940), Offset(300, 900)],
    [Offset(500, 860), Offset(620, 900), Offset(810, 880)],
    [Offset(560, 1010), Offset(600, 940), Offset(620, 900)],
  ]) {
    p.curve(field, width: _d);
  }
  const near = [Offset(-10, 780), Offset(150, 770), Offset(300, 790), Offset(460, 760), Offset(640, 790), Offset(810, 770)];
  p.curve(near);
  p.cover([...Artist.spline(near), const Offset(810, 1010), const Offset(-10, 1010)]);
  p.curve(const [Offset(-10, 740), Offset(120, 700), Offset(260, 730), Offset(420, 690), Offset(580, 720), Offset(700, 690), Offset(810, 710)]);
}

void _owl(Pen p) {
  // Toes gripping the branch.
  for (final x in [360.0, 440.0]) {
    for (final dx in [-17.0, 0.0, 17.0]) {
      p.oval(Offset(x + dx, 786 + (dx == 0 ? 4 : 0)), 8, 17, width: 4);
    }
  }
  // The face: beak, eyes, brows, the facial disc.
  p.blob(const [Offset(384, 404), Offset(416, 404), Offset(400, 448)], width: 4);
  for (final x in [340.0, 460.0]) {
    final e = Offset(x, 370);
    p.circle(e + const Offset(-7, -8), 7, width: 3);
    p.circle(e, 18, width: 4);
    p.circle(e, 34, width: 4);
    p.circle(e, 50);
  }
  for (final s in [-1.0, 1.0]) {
    p.curve([Offset(400 + s * 8, 316), Offset(400 + s * 50, 300), Offset(400 + s * 100, 316)], width: _d);
  }
  p.blob(const [Offset(400, 296), Offset(340, 276), Offset(282, 296), Offset(258, 360), Offset(282, 430), Offset(340, 460), Offset(400, 476), Offset(460, 460), Offset(518, 430), Offset(542, 360), Offset(518, 296), Offset(460, 276)]);
  // The belly with rows of little feathers.
  for (var row = 0; row < 6; row++) {
    final y = 520.0 + row * 38;
    for (var x = 318.0 + (row.isOdd ? 20 : 0); x <= 482; x += 40) {
      p.path(Pen.arc(Offset(x, y), 15, 20, 160), width: 3);
    }
  }
  p.oval(const Offset(400, 620), 112, 140);
  // Wings with long feathers at the tips.
  for (final s in [-1.0, 1.0]) {
    for (final y in [660.0, 700.0]) {
      p.curve([Offset(400 + s * 150, y - 60), Offset(400 + s * 128, y), Offset(400 + s * 112, y + 50)], width: _d);
    }
    p.curve([Offset(400 + s * 160, 440), Offset(400 + s * 126, 560), Offset(400 + s * 110, 680), Offset(400 + s * 84, 762)]);
  }
  p.shape(Pen.joined(const [
    [Offset(400, 248), Offset(330, 236), Offset(266, 172)],
    [Offset(266, 172), Offset(262, 280), Offset(236, 390), Offset(230, 520), Offset(256, 650), Offset(310, 744), Offset(400, 772), Offset(490, 744), Offset(544, 650), Offset(570, 520), Offset(564, 390), Offset(538, 280), Offset(534, 172)],
    [Offset(534, 172), Offset(470, 236), Offset(400, 248)],
  ]));
  // The branch: a knot and bark, its outline, the tail behind it.
  p.oval(const Offset(180, 806), 18, 8, width: _d);
  for (final bark in const [
    [Offset(40, 812), Offset(90, 806), Offset(130, 812)],
    [Offset(560, 790), Offset(620, 782), Offset(680, 784)],
    [Offset(240, 822), Offset(300, 816)],
  ]) {
    p.curve(bark, width: 3);
  }
  const branchTop = [Offset(-10, 788), Offset(200, 782), Offset(400, 774), Offset(600, 764), Offset(810, 752)];
  const branchBottom = [Offset(810, 798), Offset(600, 810), Offset(400, 822), Offset(200, 830), Offset(-10, 838)];
  p.shape([...Artist.spline(branchTop), ...Artist.spline(branchBottom)]);
  for (final x in [372.0, 400.0, 428.0]) {
    p.blob([Offset(x - 14, 800), Offset(x - 12, 860), Offset(x, 884), Offset(x + 12, 860), Offset(x + 14, 800)]);
  }
  // A twig with leaves, growing up and right, and two on the branch.
  for (final (base, tip) in const [
    (Offset(668, 690), Offset(610, 640)),
    (Offset(700, 640), Offset(760, 600)),
    (Offset(722, 600), Offset(680, 540)),
    (Offset(650, 740), Offset(720, 720)),
    (Offset(120, 790), Offset(60, 730)),
    (Offset(160, 788), Offset(200, 720)),
  ]) {
    p.leaf(base, tip, 34);
  }
  p.curve(const [Offset(620, 770), Offset(668, 690), Offset(700, 640), Offset(726, 590)], width: 6);
  // The night: a crescent moon and stars.
  p.shape(_crescent(const Offset(640, 150), 82, const Offset(676, 122), 74));
  for (final (x, y, r) in [(120.0, 120.0, 26.0), (250.0, 190.0, 18.0), (84.0, 330.0, 20.0), (706.0, 330.0, 22.0), (480.0, 100.0, 18.0), (150.0, 530.0, 18.0), (670.0, 470.0, 18.0)]) {
    p.star(Offset(x, y), r, inner: 0.5, width: 4);
  }
}

void _panda(Pen p) {
  // Paws round the bamboo it's eating.
  p.oval(const Offset(330, 590), 34, 28, angle: -0.5);
  p.oval(const Offset(398, 478), 32, 26, angle: -0.4);
  // The head: eyes in their patches, nose, mouth, then the ears behind.
  for (final s in [-1.0, 1.0]) {
    final e = Offset(400 + s * 52, 316);
    p.circle(e + const Offset(-3, -4), 4, width: 2.5);
    p.circle(e, 11, width: 4);
    p.oval(Offset(400 + s * 56, 322), 40, 28, angle: s * 0.65);
  }
  p.blob(const [Offset(380, 362), Offset(420, 362), Offset(400, 384)], width: 4);
  p.curve(const [Offset(370, 392), Offset(386, 404), Offset(400, 384)], width: 4);
  p.curve(const [Offset(400, 384), Offset(414, 404), Offset(430, 392)], width: 4);
  p.oval(const Offset(400, 330), 138, 118);
  for (final s in [-1.0, 1.0]) {
    p.circle(Offset(400 + s * 108, 226), 22, width: _d);
    p.circle(Offset(400 + s * 110, 224), 42);
  }
  // The bamboo it holds, going into its mouth, with leaves.
  const held = [Offset(268, 700), Offset(430, 400)];
  for (final t in [0.22, 0.5, 0.78]) {
    final q = Offset.lerp(held.first, held.last, t)!;
    p.path([q + const Offset(-14, -8), q + const Offset(14, 8)], width: 3);
  }
  p.leaf(const Offset(284, 664), const Offset(192, 612), 36);
  p.leaf(const Offset(278, 676), const Offset(196, 704), 30);
  p.shape(Artist.tube(held, const [28, 28]));
  // Arms from the shoulders down to the paws, the legs with their paw
  // pads, the body.
  p.blob(const [Offset(300, 425), Offset(250, 462), Offset(224, 530), Offset(236, 594), Offset(290, 630), Offset(342, 616), Offset(354, 560), Offset(338, 480)]);
  p.blob(const [Offset(500, 425), Offset(552, 462), Offset(568, 526), Offset(540, 562), Offset(470, 550), Offset(410, 502), Offset(430, 462), Offset(470, 440)]);
  for (final s in [-1.0, 1.0]) {
    final f = Offset(400 + s * 118, 800);
    for (var i = 0; i < 4; i++) {
      p.oval(f + Offset((i - 1.5) * 22, -42 - (i == 1 || i == 2 ? 8 : 0)), 9, 11, width: 3.5);
    }
    p.oval(f + const Offset(0, 6), 36, 28, width: _d);
    p.oval(f + Offset(-s * 6, -12), 92, 82);
  }
  p.blob(const [Offset(300, 420), Offset(240, 520), Offset(214, 640), Offset(226, 760), Offset(400, 820), Offset(574, 760), Offset(586, 640), Offset(560, 520), Offset(500, 420)]);
  // Grass and stones, the ground, bamboo growing behind.
  for (final x in [30.0, 120.0, 210.0, 600.0, 690.0, 770.0]) {
    for (final (dx, tip) in [(-10.0, const Offset(-16, -26)), (0.0, const Offset(2, -36)), (10.0, const Offset(18, -24))]) {
      p.curve([Offset(x + dx * 0.4, 902), Offset(x + dx * 0.6 + tip.dx * 0.4, 902 + tip.dy * 0.6), Offset(x, 902) + tip], width: 3);
    }
  }
  p.blob(const [Offset(600, 930), Offset(630, 896), Offset(690, 892), Offset(730, 930)]);
  p.blob(const [Offset(60, 950), Offset(80, 920), Offset(130, 918), Offset(150, 952)]);
  const ground = [Offset(-10, 880), Offset(200, 870), Offset(400, 876), Offset(600, 868), Offset(810, 878)];
  p.curve(ground);
  p.cover([...Artist.spline(ground), const Offset(810, 1010), const Offset(-10, 1010)]);
  for (final (x, lean, top) in [(70.0, 0.04, -10.0), (168.0, -0.03, 170.0), (640.0, 0.03, 130.0), (738.0, -0.04, -10.0)]) {
    Offset on(double y) => Offset(x + (900 - y) * lean, y);
    var i = x < 400 ? 0 : 1;
    for (var y = 800.0; y > top + 40; y -= 120, i++) {
      p.leaf(on(y), on(y) + Offset(i.isEven ? 66 : -66, -34), 22);
    }
    for (var y = 820.0; y > top; y -= 120) {
      p.curve([on(y) + const Offset(-14, 4), on(y), on(y) + const Offset(14, 4)], width: 3);
    }
    p.shape([on(900) + const Offset(-14, 0), on(top) + const Offset(-14, 0), on(top) + const Offset(14, 0), on(900) + const Offset(14, 0)]);
  }
}
