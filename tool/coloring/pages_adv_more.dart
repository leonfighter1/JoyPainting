part of 'pages_adv.dart';

/// A simple blossom: five round petals round a middle.
void _blossom(Pen p, Offset c, double r) {
  p.circle(c, r * 0.32, width: _d);
  for (var i = 0; i < 5; i++) {
    p.circle(c + Offset.fromDirection(i * 2 * math.pi / 5 - math.pi / 2, r * 0.62), r * 0.46, width: _d);
  }
}

void _peacock(Pen p) {
  // The head: eye and its white stripes, beak, head, then the crest.
  const head = Offset(250, 196);
  p.circle(const Offset(244, 193), 5, width: _d);
  p.curve(const [Offset(230, 186), Offset(248, 182), Offset(266, 189)], width: _d);
  p.curve(const [Offset(232, 201), Offset(250, 205), Offset(266, 198)], width: _d);
  p.shape(const [Offset(230, 189), Offset(200, 199), Offset(230, 207)]);
  p.oval(head, 26, 20, angle: -0.15);
  const crown = Offset(258, 178);
  for (var i = 0; i < 5; i++) {
    final a = -128 + i * 17.0;
    p.oval(_polar(crown, 60, a), 6, 9, angle: (a + 90) * math.pi / 180, width: _d);
    p.path([crown, _polar(crown, 52, a)], width: _d - 0.6);
  }
  // The wing over the body, the body, the neck curving down into it.
  final wing = Pen.joined(const [
    [Offset(300, 382), Offset(362, 364), Offset(420, 398), Offset(486, 470)],
    [Offset(486, 470), Offset(410, 452), Offset(330, 436), Offset(300, 382)],
  ]);
  // Rows of little feathers on the wing, long ones at its end.
  for (var y = 386.0; y < 450; y += 15) {
    for (var x = 318.0 + ((y ~/ 15).isOdd ? 10 : 0); x < 470; x += 20) {
      final c = Offset(x, y);
      if ([for (final q in Pen.arc(c, 11, 10, 170)) Pen.inside(q, wing)].every((ok) => ok) &&
          Pen.inside(c + const Offset(0, -6), wing)) {
        p.path(Pen.arc(c, 10, 10, 170), width: _d - 0.6);
      }
    }
  }
  for (final k in [0.0, 12.0, 24.0]) {
    p.curve([Offset(402, 418 + k * 0.6), Offset(440, 440 + k * 0.4), Offset(478 - k * 0.3, 466)], width: _d - 0.4);
  }
  p.shape(wing);
  p.blob(const [Offset(276, 352), Offset(330, 338), Offset(392, 362), Offset(442, 420), Offset(436, 464), Offset(380, 480), Offset(310, 470), Offset(270, 420)]);
  p.shape(Pen.tube(const [Offset(258, 210), Offset(270, 256), Offset(262, 302), Offset(290, 372)], (t) => 30 + 30 * t));
  // Legs and toes on the branch.
  for (final x in [336.0, 372.0]) {
    for (final dx in [-12.0, 0.0, 12.0]) {
      p.curve([Offset(x, 504), Offset(x + dx, 500), Offset(x + dx * 1.6, 510)], width: 3);
    }
    p.shape([Offset(x - 4, 470), Offset(x + 4, 470), Offset(x + 3, 504), Offset(x - 3, 504)], width: 3);
  }
  // The branch with blossoms and leaves.
  _blossom(p, const Offset(96, 474), 30);
  _blossom(p, const Offset(176, 462), 24);
  _blossom(p, const Offset(60, 548), 22);
  for (final (base, tip) in const [
    (Offset(130, 500), Offset(110, 430)),
    (Offset(210, 498), Offset(250, 444)),
    (Offset(30, 520), Offset(-10, 470)),
    (Offset(120, 520), Offset(160, 580)),
  ]) {
    p.leaf(base, tip, 30, width: _d);
  }
  p.shape([
    ...Artist.spline(const [Offset(-10, 506), Offset(150, 500), Offset(300, 496), Offset(440, 488), Offset(540, 474)]),
    ...Pen.arc(const Offset(540, 482), 8, 270, 450),
    ...Artist.spline(const [Offset(540, 490), Offset(440, 510), Offset(300, 520), Offset(150, 526), Offset(-10, 532)]),
  ]);

  // The tail, flowing down from under the body: short feathers on top,
  // then the long ones, the middle ones in front.
  const rump = Offset(420, 452);
  void feather(double angle, double len, double eye) {
    final d = Offset.fromDirection(angle * math.pi / 180);
    final n = Offset(-d.dy, d.dx);
    Offset along(double t) => rump + d * (len * t) + n * (len * 0.05 * math.sin(t * math.pi));
    final e = along(0.85);
    final ang = math.atan2((along(0.86) - along(0.8)).dy, (along(0.86) - along(0.8)).dx);
    final ed = Offset(math.cos(ang), math.sin(ang)), en = Offset(-ed.dy, ed.dx);
    p.oval(e + ed * 4 * eye, 9 * eye, 7 * eye, angle: ang, width: _d - 0.4);
    p.oval(e + ed * 2 * eye, 18 * eye, 13 * eye, angle: ang, width: _d);
    p.shape(Pen.joined([
      [e - ed * (34 * eye), e - ed * (12 * eye) + en * (21 * eye), e + ed * (20 * eye) + en * (17 * eye), e + ed * (28 * eye)],
      [e + ed * (28 * eye), e + ed * (20 * eye) - en * (17 * eye), e - ed * (12 * eye) - en * (21 * eye), e - ed * (34 * eye)],
    ]), width: _d);
    for (final t in [0.5, 0.62]) {
      for (final k in [-1.0, 1.0]) {
        p.path([along(t), along(t + 0.07) + n * (k * 9 * eye)], width: 1.6);
      }
    }
    p.path([for (var t = 0.12; t <= 0.74; t += 0.02) along(t)], width: 1.8);
    double across(double t) => t < 0.55 ? 4 + 14 * t / 0.55 : 18 + 22 * math.sin(math.min(1.0, (t - 0.55) / 0.36) * math.pi / 2);
    final spine = [for (var t = 0.0; t <= 0.94; t += 0.02) along(t)];
    p.shape(Pen.rounded(Artist.tube(spine, [for (var i = 0; i < spine.length; i++) across(i * 0.02) * eye])), width: _d);
  }

  for (var i = 0; i < 9; i++) {
    final k = i.isEven ? 4 + i ~/ 2 : 4 - (i + 1) ~/ 2;
    feather(34 + k * 9.0, 280 - (k - 4).abs() * 10.0, 0.72);
  }
  for (var i = 0; i < 11; i++) {
    final k = i.isEven ? 5 + i ~/ 2 : 5 - (i + 1) ~/ 2;
    feather(36 + k * 6.6, 500 - (k - 5).abs() * 14.0, 1);
  }
  // A blossoming sprig below.
  _blossom(p, const Offset(90, 880), 30);
  _blossom(p, const Offset(190, 930), 24);
  _blossom(p, const Offset(60, 960), 20);
  for (final (base, tip) in const [(Offset(130, 950), Offset(170, 880)), (Offset(110, 1000), Offset(60, 1010)), (Offset(220, 990), Offset(280, 960))]) {
    p.leaf(base, tip, 28, width: _d);
  }
  p.curve(const [Offset(20, 1010), Offset(80, 960), Offset(150, 930), Offset(260, 910)], width: _w + 2);
}

void _street(Pen p) {
  // One-point perspective: eyes 1.6 m up, looking down the street.
  const vp = Offset(400, 520);
  const f = 420.0;
  Offset pr(double x, double y, double z) => Offset(vp.dx + f * x / z, vp.dy + f * y / z);
  // A rectangle on the plane x = [x], from z0 to z1 deep, y0 to y1 high
  // (y points down; the ground is at 1.6).
  List<Offset> wall(double x, double z0, double z1, double y0, double y1) =>
      [pr(x, y0, z0), pr(x, y0, z1), pr(x, y1, z1), pr(x, y1, z0)];
  const left = -5.0, right = 5.0, curb = 3.2, ground = 1.6;

  // A street lamp at the right kerb.
  {
    const z = 4.6, x = 3.5;
    final top = pr(x, -2.7, z);
    final u = f / z;
    p.shape([top + Offset(-0.2 * u, -0.05 * u), top + Offset(0.2 * u, -0.05 * u), top + Offset(0, -0.3 * u)]);
    p.shape([top + Offset(-0.18 * u, 0), top + Offset(0.18 * u, 0), top + Offset(0.13 * u, 0.5 * u), top + Offset(-0.13 * u, 0.5 * u)]);
    p.path([top + Offset(0, 0.02 * u), top + Offset(0, 0.48 * u)], width: _d - 0.6);
    p.shape([top + Offset(-0.15 * u, 0.5 * u), top + Offset(0.15 * u, 0.5 * u), top + Offset(0.06 * u, 0.6 * u), top + Offset(-0.06 * u, 0.6 * u)]);
    final foot = pr(x, ground, z);
    p.shape([foot + Offset(-0.16 * u, 0), foot + Offset(0.16 * u, 0), foot + Offset(0.1 * u, -0.5 * u), foot + Offset(-0.1 * u, -0.5 * u)]);
    p.shape([top + Offset(-0.05 * u, 0.6 * u), top + Offset(0.05 * u, 0.6 * u), foot + Offset(0.05 * u, -0.5 * u), foot + Offset(-0.05 * u, -0.5 * u)]);
  }
  // A café table under a parasol, with two chairs.
  {
    const x = 4.0, z = 6.6;
    final rim = [for (var a = 0; a <= 180; a += 10) pr(x + 0.9 * math.cos(a * math.pi / 180), -0.5, z - 0.9 * math.sin(a * math.pi / 180))];
    final apex = pr(x, -1.25, z);
    for (final q in rim.where((q) => rim.indexOf(q) % 3 == 0)) {
      p.path([apex, q], width: _d - 0.6);
    }
    p.shape([apex, ...rim.reversed]);
    // A round top seen from just above: a thin ellipse.
    const r = 0.5 * f / z;
    p.oval(pr(x, 0.82, z), r, math.max(7, r * 0.82 / z));
    p.path([pr(x, 0.85, z), pr(x, ground, z)], width: _w);
    for (final (cx, cz, k) in [(3.35, 6.1, -1.0), (4.6, 7.2, 1.0)]) {
      final seat = [pr(cx - 0.22, 1.12, cz - 0.22), pr(cx + 0.22, 1.12, cz - 0.22), pr(cx + 0.22, 1.12, cz + 0.22), pr(cx - 0.22, 1.12, cz + 0.22)];
      final bx = cx + k * 0.22;
      p.shape([pr(bx, 1.12, cz - 0.22), pr(bx, 0.55, cz - 0.22), pr(bx, 0.55, cz + 0.22), pr(bx, 1.12, cz + 0.22)], width: _d);
      p.shape(seat, width: _d);
      for (final (lx, lz) in [(cx - 0.2, cz - 0.2), (cx + 0.2, cz - 0.2)]) {
        p.path([pr(lx, 1.12, lz), pr(lx, ground, lz)], width: _d);
      }
    }
    p.path([pr(x, 0.82, z), pr(x, -0.5, z)], width: 3);
  }
  // A striped awning over the shop at the left, scalloped at the front.
  {
    const z0 = 3.6, z1 = 7.6;
    p.shape([
      pr(left + 1.2, -0.3, z0), pr(left + 1.2, -0.3, z1),
      for (var z = z1; z >= z0 - 0.01; z -= 0.05) pr(left + 1.2, -0.12 + 0.1 * math.sin(((z - z0) / 0.5 % 1) * math.pi), z),
    ]);
    for (var z = z0 + 0.5; z < z1; z += 0.5) {
      p.path([pr(left, -0.95, z), pr(left + 1.2, -0.3, z)], width: _d);
    }
    p.shape([pr(left, -0.95, z0), pr(left, -0.95, z1), pr(left + 1.2, -0.3, z1), pr(left + 1.2, -0.3, z0)]);
  }
  // A hanging sign further along.
  {
    const z = 10.5;
    p.shape([pr(left + 0.25, -2.0, z), pr(left + 1.05, -2.0, z), pr(left + 1.05, -1.3, z), pr(left + 0.25, -1.3, z)]);
    p.path([pr(left, -2.2, z), pr(left + 1.15, -2.2, z)], width: 3);
  }
  // The houses on both sides: windows with shutters and flower boxes,
  // doors, a shop window, cornices; then each front.
  void house(double x, double z0, double z1, double h, {bool shop = false}) {
    final floors = ((h - 1) / 3).floor();
    final near = z1 < 22;
    final count = math.max(1, ((z1 - z0) / 2.4).floor());
    for (var i = 0; i < count; i++) {
      final zc = z0 + (z1 - z0) * (i + 0.5) / count;
      for (var k = 1; k < floors && near; k++) {
        final sill = ground - 3 * k - 0.8, head = sill - 1.6;
        if (z1 < 13) {
          for (final dz in [-0.32, -0.08, 0.16, 0.4]) {
            p.circle(pr(x, sill - 0.12, zc + dz), 0.09 * f / zc, width: 2);
          }
          p.shape(wall(x, zc - 0.55, zc + 0.55, sill, sill + 0.28), width: _d);
        }
        p.path([pr(x, head, zc), pr(x, sill, zc)], width: _d - 0.6);
        p.path([pr(x, (sill + head) / 2, zc - 0.45), pr(x, (sill + head) / 2, zc + 0.45)], width: _d - 0.6);
        p.shape(wall(x, zc - 0.45, zc + 0.45, sill, head), width: _d);
        if (z1 < 22) {
          p.shape(wall(x, zc - 0.85, zc - 0.5, sill, head), width: _d);
          p.shape(wall(x, zc + 0.5, zc + 0.85, sill, head), width: _d);
        }
      }
      if (!near) continue;
      if (shop && i == 0) {
        for (final dz in [-0.4, 0.4]) {
          p.path([pr(x, ground - 0.5, zc + dz), pr(x, ground - 2.4, zc + dz)], width: _d - 0.6);
        }
        p.shape(wall(x, zc - 1.1, zc + 1.1, ground - 0.5, ground - 2.4), width: _d);
      } else {
        p.path([pr(x, ground, zc), pr(x, -0.2, zc)], width: _d - 0.6);
        p.shape([
          pr(x, ground, zc - 0.55),
          for (var a = 180; a >= 0; a -= 10) pr(x, -0.2 - 0.55 * math.sin(a * math.pi / 180), zc + 0.55 * math.cos(a * math.pi / 180)),
          pr(x, ground, zc + 0.55),
        ], width: _d);
      }
    }
    p.path([pr(x, ground - h + 0.4, z0), pr(x, ground - h + 0.4, z1)], width: _d);
    p.shape(wall(x, z0, z1, ground, ground - h));
  }

  for (final (z0, z1, h, shop) in const [(2.5, 8.0, 9.5, true), (8.0, 13.0, 11.0, false), (13.0, 19.0, 8.5, false), (19.0, 27.0, 10.0, false), (27.0, 40.0, 9.0, false)]) {
    house(left, z0, z1, h, shop: shop);
  }
  for (final (z0, z1, h) in const [(2.5, 7.8, 8.8), (7.8, 12.0, 10.5), (12.0, 18.0, 9.2), (18.0, 26.0, 11.0), (26.0, 40.0, 9.0)]) {
    house(right, z0, z1, h);
  }
  // At the end of the street, a church tower over the rooftops.
  {
    const z = 40.0;
    p.shape([pr(-0.6, -12.0, z), ...Pen.arc(pr(0, -13.4, z), 0.6 * f / z, 180, 360), pr(0.6, -12.0, z)], width: 2);
    p.shape([pr(-1.3, -15.5, z), pr(0, -22.0, z), pr(1.3, -15.5, z)]);
    p.shape([pr(-1.1, -15.5, z), pr(1.1, -15.5, z), pr(1.1, -7.0, z), pr(-1.1, -7.0, z)]);
    for (final x in [-3.4, 3.4]) {
      p.shape([pr(x - 0.7, -3.6, z), pr(x + 0.7, -3.6, z), pr(x + 0.7, -0.8, z), pr(x - 0.7, -0.8, z)], width: 2);
    }
    p.shape([pr(left, ground, z), pr(right, ground, z), pr(right, -7.0, z), pr(left, -7.0, z)]);
  }
  // Pavements: kerbs and paving slabs.
  for (final s in [-1.0, 1.0]) {
    for (var z = 4.0; z < 30; z *= 1.18) {
      p.path([pr(s * curb, ground - 0.15, z), pr(s * (right - 0.01), ground, z)], width: _d - 0.6);
    }
    p.path([pr(s * curb, ground, 2.0), pr(s * curb, ground, 40)], width: _d);
    p.path([pr(s * curb, ground - 0.15, 2.0), pr(s * curb, ground - 0.15, 40)], width: _d);
  }
  p.cover([pr(-curb, ground - 0.15, 2.0), pr(-curb, ground - 0.15, 40), pr(left - 1, ground, 40), pr(left - 1, -30, 0.5)]);
  p.cover([pr(curb, ground - 0.15, 2.0), pr(curb, ground - 0.15, 40), pr(right + 1, ground, 40), pr(right + 1, -30, 0.5)]);
  // Cobblestones, smaller as they go.
  final rows = [for (var z = 1.3; z < 16; z *= 1.1) z];
  for (var k = 0; k + 1 < rows.length; k++) {
    p.path([pr(-curb, ground, rows[k]), pr(curb, ground, rows[k])], width: _d - 0.6);
    for (var x = -curb + (k.isOdd ? 0.25 : 0.5); x < curb; x += 0.5) {
      p.path([pr(x, ground, rows[k]), pr(x, ground, rows[k + 1])], width: _d - 0.6);
    }
  }
  p.path([pr(-curb, ground, 16), pr(curb, ground, 16)], width: _d - 0.6);
  // The sky: clouds and birds.
  for (final (c, s) in [(const Offset(400, 140), 1.0), (const Offset(470, 290), 0.6)]) {
    p.blob([for (final q in const [Offset(-90, 20), Offset(-70, -10), Offset(-35, -22), Offset(-10, -45), Offset(30, -40), Offset(55, -18), Offset(85, -12), Offset(100, 12), Offset(70, 30), Offset(0, 32), Offset(-60, 32)]) c + q * s]);
  }
  for (final (x, y, s) in [(330.0, 250.0, 1.0), (360.0, 228.0, 0.8), (300.0, 280.0, 0.7)]) {
    p.curve([Offset(x - 16 * s, y + 3 * s), Offset(x - 8 * s, y - 5 * s), Offset(x, y + 2 * s)], width: 2.4);
    p.curve([Offset(x, y + 2 * s), Offset(x + 8 * s, y - 5 * s), Offset(x + 16 * s, y + 3 * s)], width: 2.4);
  }
}
