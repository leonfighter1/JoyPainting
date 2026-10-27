import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jingyao_paint/drawing/stroke.dart';

import 'artist.dart';
import 'nature.dart';

/// The advanced sample, 湖畔晨光 (Dawn on the Lake): a realistic painting
/// made with everything the app has (textures, the blender, light and
/// shadow, gradients, soft edges), to show how far the tools go. The sun
/// rises between two snowy ranges; the lake mirrors them through the
/// morning mist, and a wooden dock with a rowboat leads the eye in.
abstract final class DawnOnTheLake {
  static const size = Size(1200, 800);
  static const paper = Color(0xFF1A2A4E);

  static List<Stroke> strokes() {
    final a = Artist();
    _paint(a);
    return a.strokes;
  }
}

const _sun = Offset(705, 318);
const _water = 458.0;

void _paint(Artist a) {
  _sky(a);
  _clouds(a);
  _mountains(a);
  _farShore(a);
  _lake(a);
  _leftShore(a);
  _dock(a);
  _boat(a);
  _reeds(a);
  _finish(a);
}

// --- Sky ---------------------------------------------------------------------

void _sky(Artist a) {
  a.area(
    const [Offset(0, 0), Offset(1200, 0), Offset(1200, 470), Offset(0, 470)],
    const Fill.linear(
      Offset(0, 0),
      Offset(0, 460),
      [
        Color(0xFF15233F),
        Color(0xFF34507C),
        Color(0xFF8193AE),
        Color(0xFFE2BFA2),
        Color(0xFFF7CE96),
      ],
      [0, 0.26, 0.56, 0.82, 1],
    ),
    spacing: 6,
  );
  a.glow(
    _sun,
    640,
    const Color(0x55F2A766),
    blend: StrokeBlend.screen,
    squash: 0.6,
  );
  a.glow(
    _sun,
    280,
    const Color(0x99FFD69C),
    blend: StrokeBlend.screen,
    squash: 0.75,
  );
  a.glow(_sun, 110, const Color(0xEEFFF0CC), blend: StrokeBlend.screen);
  a.oval(_sun, 26, 26, const Fill(Color(0xFFFFFCEE)), blur: 3);
  a.area(
    const [Offset(0, 0), Offset(1200, 0), Offset(1200, 470), Offset(0, 470)],
    const Fill(Color(0xFF9AA6BC)),
    opacity: 0.12,
    blend: StrokeBlend.softLight,
    texture: StrokeTexture.paper,
    spacing: 6,
  );
}

// --- Clouds ------------------------------------------------------------------

List<Offset> _cloudOutline(
  math.Random rnd,
  Offset center,
  List<(Offset, double)> puffs,
  double base,
) {
  return [
    for (var deg = 0.0; deg < 360; deg += 2.5)
      () {
        final d = Offset.fromDirection(deg * math.pi / 180);
        var reach = 0.0;
        for (final (c, r) in puffs) {
          final co = center - c;
          final b = -(co.dx * d.dx + co.dy * d.dy);
          final disc = b * b - (co.distanceSquared - r * r);
          if (disc >= 0) reach = math.max(reach, b + math.sqrt(disc));
        }
        final p = center + d * reach * (1 + (rnd.nextDouble() - 0.5) * 0.03);
        return Offset(p.dx, math.min(p.dy, base + rnd.nextDouble() * 3));
      }(),
  ];
}

/// A cumulus lit from the low sun: warm on the side facing it, cool
/// lavender away from it, soft where its puffs meet.
void _cumulus(
  Artist a,
  math.Random rnd,
  Offset center,
  List<(Offset, double)> puffs,
  double base,
) {
  const shade = Color(0xFF4E5578), body = Color(0xFFA592A2);
  const lit = Color(0xFFF7BE8A), rim = Color(0xFFFFE8C6);
  final outline = _cloudOutline(rnd, center, puffs, base);
  final box = Artist.boxOf(outline);
  final toSun = (_sun - center) / (_sun - center).distance;
  a.area(
    outline,
    Fill.linear(
      box.center - toSun * box.longestSide * 0.5,
      box.center + toSun * box.longestSide * 0.5,
      const [shade, body, lit],
      const [0, 0.55, 1],
    ),
    blur: 1.5,
  );
  a.area(
    outline,
    Fill.linear(Offset(0, box.top), Offset(0, box.bottom), [
      Nature.fade(shade, 0),
      Nature.fade(shade, 0.5),
    ]),
    blend: StrokeBlend.multiply,
    blur: 1.5,
  );
  final sunAngle = math.atan2(toSun.dy, toSun.dx) * 180 / math.pi;
  for (final (c, r) in puffs) {
    a.line(
      a.arc(c, r * 0.82, -sunAngle + 110, -sunAngle + 230, steps: 16),
      shade,
      width: r * 0.3,
      opacity: 0.4,
      blur: r * 0.12,
      blend: StrokeBlend.multiply,
      taper: true,
    );
    a.line(
      a.arc(c, r * 0.8, -sunAngle - 70, -sunAngle + 70, steps: 16),
      lit,
      width: r * 0.28,
      opacity: 0.45,
      blur: r * 0.1,
      blend: StrokeBlend.screen,
      taper: true,
      texture: StrokeTexture.paper,
    );
  }
  a.smudgeArea(outline, radius: 3.5, strength: 0.75);
  final rimSide =
      [
        for (final p in outline)
          if (((p - center).dx * toSun.dx + (p - center).dy * toSun.dy) /
                  (p - center).distance >
              0.45)
            p,
      ]..sort(
        (p, q) => _turn(p - center, toSun).compareTo(_turn(q - center, toSun)),
      );
  if (rimSide.length > 3) {
    a.line(
      rimSide,
      rim,
      width: 2.4,
      opacity: 0.75,
      blur: 1.2,
      blend: StrokeBlend.screen,
      taper: true,
    );
  }
}

void _clouds(Artist a) {
  final rnd = math.Random(17);
  for (var i = 0; i < 40; i++) {
    final y = 40 + rnd.nextDouble() * 230;
    final x = -60 + rnd.nextDouble() * 1200;
    final len = 80 + rnd.nextDouble() * 260;
    final warm = (y - 40) / 230;
    a.curveLine(
      [
        Offset(x, y),
        Offset(x + len * 0.5, y - 4 + rnd.nextDouble() * 8),
        Offset(x + len, y - 6 + rnd.nextDouble() * 6),
      ],
      Nature.mix(const Color(0xFF61709A), const Color(0xFFE9A894), warm),
      width: 4 + rnd.nextDouble() * 9,
      opacity: 0.2 + warm * 0.35,
      texture: StrokeTexture.bristle,
      taper: true,
      blur: 0.8,
    );
  }
  a.smudgeArea(
    const [Offset(0, 20), Offset(1200, 20), Offset(1200, 300), Offset(0, 300)],
    radius: 2.5,
    strength: 0.6,
  );
  _cumulus(a, rnd, const Offset(1030, 200), const [
    (Offset(960, 230), 50),
    (Offset(1030, 222), 58),
    (Offset(1100, 232), 48),
    (Offset(990, 180), 40),
    (Offset(1060, 166), 44),
    (Offset(1130, 196), 36),
    (Offset(1030, 128), 30),
    (Offset(1170, 238), 34),
    (Offset(910, 246), 30),
  ], 258);
  _cumulus(a, rnd, const Offset(200, 150), const [
    (Offset(150, 170), 34),
    (Offset(200, 160), 40),
    (Offset(250, 172), 30),
    (Offset(180, 128), 26),
    (Offset(226, 124), 22),
  ], 186);
}

// --- Mountains ---------------------------------------------------------------

/// A range along [keys], lit from the sun on its [sunSide] (1 right, -1
/// left): faces turned to the sun warm, others cool, built from streaks
/// down the fall lines, snow in the gullies above [snowLine], haze rising
/// from [base]. Returns its ridge, for the reflection.
List<Offset> _range(
  Artist a,
  math.Random rnd,
  List<Offset> keys,
  double base, {
  required Color shade,
  required Color lit,
  required Color haze,
  required double snowLine,
  required double sunSide,
  double light = 1,
  double rough = 0.45,
}) {
  final ridge = Nature.ridge(rnd, keys, rough: rough, step: 3);
  final top = keys.map((k) => k.dy).reduce(math.min);
  final outline = [
    ...ridge,
    Offset(ridge.last.dx, base),
    Offset(ridge.first.dx, base),
  ];
  a.area(
    outline,
    Fill.linear(Offset(0, top), Offset(0, base), [
      shade,
      Nature.mix(shade, haze, 0.55),
    ]),
    spacing: 4,
  );
  final tops = Nature.peaks(ridge, prominence: 8);
  for (final (k, i) in tops.indexed) {
    // The slope down from this peak toward the sun.
    final int from, to;
    if (sunSide > 0) {
      final next = k + 1 < tops.length ? tops[k + 1] : ridge.length - 1;
      from = i;
      to = Nature.valley(ridge, i, next);
    } else {
      final prev = k > 0 ? tops[k - 1] : 0;
      from = Nature.valley(ridge, prev, i);
      to = i;
    }
    if (to - from < 2) continue;
    final p = ridge[i], h = base - p.dy;
    final low = sunSide > 0 ? ridge[to] : ridge[from];
    a.area(
      [
        ...ridge.sublist(from, to + 1),
        ...(sunSide > 0
            ? [
                ...Nature.wander(rnd, low, low + Offset(h * 0.12, h * 0.8)),
                ...Nature.wander(rnd, p + Offset(-h * 0.1, h * 0.8), p),
              ]
            : [
                ...Nature.wander(rnd, p, p + Offset(h * 0.1, h * 0.8)),
                ...Nature.wander(rnd, low + Offset(-h * 0.12, h * 0.8), low),
              ]),
      ],
      Fill.linear(p, p + Offset(0, h), [
        Nature.fade(lit, 0.75 * light),
        Nature.fade(lit, 0),
      ]),
      blur: 2,
    );
  }
  for (var i = 1; i + 1 < ridge.length; i += 2) {
    final p = ridge[i];
    final slope = (ridge[i + 1].dy - ridge[i - 1].dy) * sunSide;
    final facesSun = slope + (rnd.nextDouble() - 0.5) * 3 > 0;
    final h = base - p.dy;
    final down = (ridge[i + 1].dy - ridge[i - 1].dy).sign;
    final dir = Offset(down * 0.25, 1);
    final streak = Nature.wander(
      rnd,
      p + const Offset(0, 1),
      p + dir * (h * (0.25 + rnd.nextDouble() * 0.6)),
      rough: 0.25,
    );
    final depth = (p.dy - top) / (base - top);
    a.line(
      streak,
      facesSun ? lit : Nature.mix(shade, const Color(0xFF1C1D30), 0.3),
      width: 1.2 + rnd.nextDouble() * 3.5,
      opacity: facesSun
          ? (0.35 + rnd.nextDouble() * 0.4) * light * (1 - depth * 0.5)
          : 0.3 + rnd.nextDouble() * 0.3,
      taper: true,
      texture: StrokeTexture.charcoal,
    );
    if (p.dy < snowLine) {
      a.line(
        Nature.wander(
          rnd,
          p + const Offset(0, 1),
          p + dir * ((snowLine - p.dy) * (0.6 + rnd.nextDouble()) + 6),
          rough: 0.3,
        ),
        facesSun ? const Color(0xFFFFF1E2) : const Color(0xFFB4BEDA),
        width: 1 + rnd.nextDouble() * 2.6,
        opacity: facesSun ? 0.85 : 0.6,
        taper: true,
        texture: StrokeTexture.charcoal,
      );
    }
  }
  a.smudgeArea(outline, radius: 0.8, strength: 0.5);
  // Haze thickening toward the foot, only over the mountains themselves.
  final hazeTop = base - (base - top) * 0.7;
  a.area(
    [
      for (final p in ridge) Offset(p.dx, math.max(p.dy, hazeTop)),
      Offset(ridge.last.dx, base),
      Offset(ridge.first.dx, base),
    ],
    Fill.linear(Offset(0, hazeTop), Offset(0, base), [
      Nature.fade(haze, 0),
      Nature.fade(haze, 0.95),
    ]),
    spacing: 4,
  );
  return ridge;
}

final _ridges = <(List<Offset>, Color)>[];

void _mountains(Artist a) {
  final rnd = math.Random(9);
  _ridges.clear();
  // Far, pale peaks behind the sun.
  final far = _range(
    a,
    rnd,
    const [
      Offset(-10, 380),
      Offset(120, 352),
      Offset(260, 370),
      Offset(420, 340),
      Offset(560, 366),
      Offset(700, 356),
      Offset(840, 372),
      Offset(980, 344),
      Offset(1210, 366),
    ],
    470,
    shade: const Color(0xFFA997AC),
    lit: const Color(0xFFF4CDB0),
    haze: const Color(0xFFF2CDAD),
    snowLine: 356,
    sunSide: 1,
    light: 0.5,
    rough: 0.3,
  );
  _ridges.add((far, const Color(0xFFC9A9A8)));
  // The great peak on the left, lit on its right.
  final left = _range(
    a,
    rnd,
    const [
      Offset(-10, 330),
      Offset(60, 280),
      Offset(130, 244),
      Offset(210, 170),
      Offset(256, 196),
      Offset(330, 236),
      Offset(420, 300),
      Offset(520, 360),
      Offset(640, 430),
    ],
    474,
    shade: const Color(0xFF545677),
    lit: const Color(0xFFE5A47E),
    haze: const Color(0xFFE6BEA6),
    snowLine: 300,
    sunSide: 1,
  );
  _ridges.add((left, const Color(0xFF6E6680)));
  // The range on the right, lit on its left.
  final right = _range(
    a,
    rnd,
    const [
      Offset(760, 430),
      Offset(840, 372),
      Offset(900, 330),
      Offset(960, 262),
      Offset(1010, 286),
      Offset(1070, 240),
      Offset(1130, 268),
      Offset(1210, 300),
    ],
    474,
    shade: const Color(0xFF5B5878),
    lit: const Color(0xFFEDAE84),
    haze: const Color(0xFFE9C0A2),
    snowLine: 310,
    sunSide: -1,
  );
  _ridges.add((right, const Color(0xFF746A84)));
}

// --- Far shore and lake --------------------------------------------------------

void _pine(
  Artist a,
  math.Random rnd,
  Offset base,
  double h,
  Color color, {
  Color? rim,
  double rimSide = 1,
}) {
  a.line([base, base - Offset(0, h)], color, width: math.max(1, h * 0.025));
  final tiers = (h / 14).clamp(5, 16).round();
  for (var k = 0; k < tiers; k++) {
    final t = (k + 1) / tiers;
    final y = base.dy - h + h * 0.95 * t;
    final w = h * 0.22 * t * (0.8 + rnd.nextDouble() * 0.35);
    final top = Offset(base.dx, y - h * 0.95 / tiers * 1.6);
    final edge = Nature.ridge(
      rnd,
      [
        Offset(base.dx - w, y + rnd.nextDouble() * 3),
        Offset(base.dx, y - h * 0.02),
        Offset(base.dx + w, y + rnd.nextDouble() * 3),
      ],
      rough: 0.5,
      step: math.max(2, h * 0.02),
    );
    a.area([top, ...edge], Fill(color), spacing: 2);
    if (rim != null) {
      final r = [
        for (final p in edge)
          if ((p.dx - base.dx) * rimSide > w * 0.3) p,
      ];
      if (r.length > 1) {
        a.line(
          [top, ...rimSide > 0 ? r : r.reversed],
          rim,
          width: math.max(0.8, h * 0.006),
          opacity: 0.35,
          taper: true,
          blend: StrokeBlend.screen,
        );
      }
    }
  }
}

void _farShore(Artist a) {
  final rnd = math.Random(21);
  // A low wooded shore along the water, in the haze.
  a.area(
    Nature.ridge(rnd, const [
          Offset(-10, 446),
          Offset(1210, 446),
        ], rough: 0.05) +
        const [Offset(1210, 462), Offset(-10, 462)],
    const Fill(Color(0xFF5E5E78)),
  );
  for (var x = -10.0; x < 1210; x += 5 + rnd.nextDouble() * 9) {
    final h = 10 + rnd.nextDouble() * 20;
    _pine(
      a,
      rnd,
      Offset(x, 458),
      h,
      Nature.mix(
        const Color(0xFF4A4E6A),
        const Color(0xFF8E8AA0),
        1 - (x - _sun.dx).abs() / 700,
      ),
    );
  }
  // Morning mist lying on the water and the trees.
  for (var k = 0; k < 9; k++) {
    final c = Offset(rnd.nextDouble() * 1200, 446 + rnd.nextDouble() * 24);
    a.glow(
      c,
      140 + rnd.nextDouble() * 160,
      const Color(0x99F6DCC4),
      squash: 0.12,
    );
  }
}

void _lake(Artist a) {
  final rnd = math.Random(33);
  // The water mirrors the sky: bright at the far shore, deep near us.
  a.area(
    const [
      Offset(0, _water),
      Offset(1200, _water),
      Offset(1200, 800),
      Offset(0, 800),
    ],
    const Fill.linear(
      Offset(0, _water),
      Offset(0, 800),
      [
        Color(0xFFEAC6A6),
        Color(0xFF9EA4B8),
        Color(0xFF3E5274),
        Color(0xFF15233C),
      ],
      [0, 0.18, 0.55, 1],
    ),
    spacing: 6,
  );
  // The mountains upside down in it, darker and softer.
  for (final (ridge, color) in _ridges) {
    final flipped = [
      for (final p in ridge) Offset(p.dx, 2 * _water - p.dy + 10),
    ];
    a.area(
      [
        Offset(ridge.first.dx - 60, _water),
        ...flipped,
        Offset(ridge.last.dx + 60, _water),
      ],
      Fill.linear(
        const Offset(0, _water),
        Offset(0, flipped.map((p) => p.dy).reduce(math.max)),
        [Nature.fade(color, 0.85), Nature.fade(color, 0.35)],
      ),
      spacing: 4,
    );
  }
  a.glow(
    Offset(_sun.dx, 2 * _water - _sun.dy),
    260,
    const Color(0x77FFD09A),
    blend: StrokeBlend.screen,
    squash: 0.7,
  );
  // Still water smears a reflection sideways.
  for (var y = _water + 4; y < 800; y += 10) {
    a.smudge(
      [Offset(-20, y), Offset(600, y + 1), Offset(1220, y)],
      width: 14,
      strength: 0.55,
    );
  }
  // The sun's path: glints breaking up as the ripples grow toward us.
  for (var y = _water + 3; y < 800; y += 3 + (y - _water) * 0.03) {
    final t = (y - _water) / 340;
    final half = 30 + t * 120;
    for (var k = 0; k < 2 + rnd.nextInt(3); k++) {
      final x = _sun.dx + (rnd.nextDouble() - 0.5) * 2 * half;
      final len = 6 + rnd.nextDouble() * 30 * (1 - t * 0.4);
      a.line(
        [Offset(x - len / 2, y), Offset(x + len / 2, y)],
        Nature.mix(const Color(0xFFFFF4D6), const Color(0xFFFFC27E), t),
        width: 1 + t * 2.5,
        opacity: 0.9 - t * 0.5,
        taper: true,
        blend: StrokeBlend.screen,
      );
    }
  }
  // Ripples: dark troughs and lit crests, wider apart close by.
  for (var y = _water + 8; y < 800; y += 5 + (y - _water) * 0.06) {
    final t = (y - _water) / 340;
    var x = rnd.nextDouble() * 60 - 30;
    while (x < 1200) {
      final len = 30 + t * 140 + rnd.nextDouble() * 60;
      a.line(
        [Offset(x, y), Offset(x + len, y + rnd.nextDouble() - 0.5)],
        const Color(0xFF0E1830),
        width: 1 + t * 3,
        opacity: 0.3 + t * 0.2,
        taper: true,
        texture: StrokeTexture.bristle,
      );
      a.line(
        [
          Offset(x + len * 0.2, y - 1.5 - t * 2),
          Offset(x + len * 0.8, y - 1.5 - t * 2),
        ],
        const Color(0xFFDCC6C2),
        width: 0.6 + t * 1.2,
        opacity: 0.25 + t * 0.15,
        taper: true,
      );
      x += len + 10 + rnd.nextDouble() * 60;
    }
  }
  // Mist drifting low over the water.
  for (var k = 0; k < 7; k++) {
    final c = Offset(rnd.nextDouble() * 1200, 470 + rnd.nextDouble() * 80);
    a.glow(
      c,
      160 + rnd.nextDouble() * 200,
      const Color(0x66F4E0D2),
      squash: 0.1,
    );
  }
}

// --- Foreground ----------------------------------------------------------------

void _leftShore(Artist a) {
  final rnd = math.Random(45);
  // Tall pines on the left, dark against the dawn with their edges lit,
  // and their reflections.
  const trees = [
    (Offset(70, 690), 560.0),
    (Offset(190, 660), 470.0),
    (Offset(280, 640), 330.0),
    (Offset(20, 720), 620.0),
    (Offset(340, 625), 240.0),
  ];
  for (final (base, h) in trees) {
    final reflection = Artist();
    _pine(
      reflection,
      math.Random(base.dx.round()),
      base,
      h,
      const Color(0xFF0A1220),
    );
    for (final s in reflection.strokes) {
      a.strokes.add(
        s
            .transformed(StrokeTransform(1, 0, 0, -0.85, 0, base.dy * 1.85 - 6))
            .copyWith(opacity: 0.45),
      );
    }
  }
  // The bank they stand on.
  a.blob(
    const [
      Offset(-20, 600),
      Offset(120, 640),
      Offset(260, 650),
      Offset(380, 640),
      Offset(440, 660),
      Offset(380, 700),
      Offset(240, 730),
      Offset(80, 760),
      Offset(-20, 780),
    ],
    const Fill.linear(Offset(0, 620), Offset(0, 780), [
      Color(0xFF2E2A28),
      Color(0xFF14110F),
    ]),
  );
  _grain(
    a,
    Artist.spline(const [
      Offset(-20, 600),
      Offset(120, 640),
      Offset(260, 650),
      Offset(380, 640),
      Offset(440, 660),
      Offset(380, 700),
      Offset(240, 730),
      Offset(80, 760),
      Offset(-20, 780),
    ], closed: true),
    o: 0.3,
  );
  for (final (base, h) in trees) {
    _pine(
      a,
      math.Random(base.dx.round()),
      base,
      h,
      const Color(0xFF0C1418),
      rim: const Color(0xFFFFC890),
      rimSide: 1,
    );
  }
  for (final (c, w) in const [
    (Offset(360, 660), 70.0),
    (Offset(250, 690), 90.0),
    (Offset(420, 668), 40.0),
  ]) {
    final rock = Nature.lump(rnd, c, w / 2, w * 0.28, jag: 0.2, count: 9);
    a.area(
      rock,
      Fill.linear(
        c - Offset(w / 2, 0),
        c + Offset(w / 2, 0),
        const [Color(0xFF1C1816), Color(0xFF3A3230), Color(0xFFB08060)],
        const [0, 0.6, 1],
      ),
    );
    _grain(a, rock, o: 0.3);
    a.line(
      [
        for (final p in rock)
          if (p.dx > c.dx && p.dy < c.dy) p,
      ]..sort((p, q) => p.dy.compareTo(q.dy)),
      const Color(0xFFFFC890),
      width: 1.4,
      opacity: 0.7,
      taper: true,
      blend: StrokeBlend.screen,
    );
  }
}

void _dock(Artist a) {
  // An old wooden dock running out toward the sun.
  const nearL = Offset(470, 820), nearR = Offset(700, 820);
  const farL = Offset(596, 588), farR = Offset(646, 588);
  // Posts under it, and their wavering reflections.
  for (var k = 0; k <= 5; k++) {
    final t = k / 5;
    for (final (from, to) in const [(nearL, farL), (nearR, farR)]) {
      final top = Offset.lerp(from, to, t)!;
      final w = 10 - t * 7, h = 40 - t * 28;
      a.line([top, top + Offset(0, h)], const Color(0xFF16100C), width: w);
      a.line(
        [top + Offset(0, h), top + Offset(1, h * 1.8)],
        const Color(0xFF16100C),
        width: w * 0.9,
        opacity: 0.4,
        taper: true,
        texture: StrokeTexture.bristle,
      );
    }
  }
  // The deck: planks across it, closer together far away.
  final deck = [farL, farR, nearR, nearL];
  a.area(
    deck,
    const Fill.linear(
      Offset(0, 588),
      Offset(0, 820),
      [Color(0xFFB98A68), Color(0xFF6E4E3A), Color(0xFF3A2A20)],
      [0, 0.4, 1],
    ),
    spacing: 2,
  );
  a.area(
    deck,
    const Fill(Color(0xFF000000)),
    opacity: 0.25,
    blend: StrokeBlend.multiply,
    texture: StrokeTexture.bristle,
  );
  for (var k = 0; k < 34; k++) {
    final t = math.pow(k / 34, 1.6).toDouble();
    final l = Offset.lerp(farL, nearL, t)!, r = Offset.lerp(farR, nearR, t)!;
    a.line([l, r], const Color(0xFF1A120C), width: 0.6 + t * 1.6, opacity: 0.7);
  }
  // Sun on the far boards, and along the edge toward us.
  a.area(
    [
      farL,
      farR,
      Offset.lerp(farR, nearR, 0.35)!,
      Offset.lerp(farL, nearL, 0.35)!,
    ],
    const Fill.linear(Offset(0, 588), Offset(0, 680), [
      Color(0xAAFFD7A4),
      Color(0x00FFD7A4),
    ]),
    blend: StrokeBlend.screen,
  );
  a.line(
    [farR, nearR],
    const Color(0xFFFFCB94),
    width: 2,
    opacity: 0.6,
    taper: true,
    blend: StrokeBlend.screen,
  );
  a.line([farL, nearL], const Color(0xFF0E0906), width: 3, opacity: 0.6);
  // A mooring post at the end, with a coil of rope.
  a.line(
    [farR + const Offset(-4, -26), farR + const Offset(-4, 10)],
    const Color(0xFF1A120C),
    width: 6,
  );
  a.line(
    [farR + const Offset(-3, -26), farR + const Offset(-3, 8)],
    const Color(0xFFFFC890),
    width: 1,
    opacity: 0.6,
    blend: StrokeBlend.screen,
  );
}

void _boat(Artist a) {
  // A rowboat tied to the dock, resting on still water.
  final hull = Artist.spline(const [
    Offset(660, 606),
    Offset(700, 600),
    Offset(760, 600),
    Offset(812, 594),
    Offset(806, 610),
    Offset(780, 626),
    Offset(720, 630),
    Offset(676, 622),
  ], closed: true);
  // Its reflection first.
  a.blob(
    const [
      Offset(668, 624),
      Offset(720, 632),
      Offset(790, 628),
      Offset(808, 640),
      Offset(760, 652),
      Offset(690, 648),
    ],
    const Fill(Color(0xFF0E0A0C)),
    opacity: 0.5,
    blur: 2,
  );
  a.area(
    hull,
    const Fill.linear(
      Offset(660, 0),
      Offset(812, 0),
      [Color(0xFF2A1A14), Color(0xFF4E3022), Color(0xFFB0704A)],
      [0, 0.6, 1],
    ),
  );
  _grain(a, hull, o: 0.2);
  // The inside, a seat and the gunwale catching the light.
  a.blob(const [
    Offset(676, 606),
    Offset(720, 602),
    Offset(790, 600),
    Offset(780, 610),
    Offset(720, 612),
    Offset(684, 612),
  ], const Fill(Color(0xFF1A100C)));
  a.line(
    const [Offset(728, 601), Offset(734, 611)],
    const Color(0xFF6E4A34),
    width: 4,
  );
  a.curveLine(
    const [
      Offset(660, 606),
      Offset(700, 600),
      Offset(760, 600),
      Offset(812, 594),
    ],
    const Color(0xFFFFCF9A),
    width: 1.6,
    opacity: 0.8,
    taper: true,
    blend: StrokeBlend.screen,
  );
  // The rope to the post.
  a.curveLine(
    const [Offset(662, 606), Offset(652, 600), Offset(644, 572)],
    const Color(0xFFCDB08A),
    width: 1.2,
    opacity: 0.8,
  );
  a.smudge(
    const [Offset(660, 640), Offset(740, 642), Offset(810, 640)],
    width: 16,
    strength: 0.6,
  );
}

void _reeds(Artist a) {
  final rnd = math.Random(57);
  // Reeds at the water's edge on the right, dark with lit tips.
  for (var k = 0; k < 120; k++) {
    final x = 880 + rnd.nextDouble() * 340;
    final base = Offset(x, 800 - rnd.nextDouble() * 50 + (x - 880) * -0.05);
    final h = 40 + rnd.nextDouble() * 110;
    final tip = base + Offset(-h * (0.05 + rnd.nextDouble() * 0.15), -h);
    a.curveLine(
      [base, Offset.lerp(base, tip, 0.6)! + const Offset(-2, 0), tip],
      Nature.mix(
        const Color(0xFF14160E),
        const Color(0xFF3A3A22),
        rnd.nextDouble(),
      ),
      width: 1.2 + rnd.nextDouble() * 1.6,
      taper: true,
    );
    if (rnd.nextDouble() < 0.3) {
      a.oval(
        tip + const Offset(0, 8),
        2,
        7,
        const Fill(Color(0xFF3A2416)),
        angle: -0.1,
      );
      a.line(
        [tip + const Offset(-1, 2), tip + const Offset(-1, 12)],
        const Color(0xFFFFC890),
        width: 0.8,
        opacity: 0.6,
        blend: StrokeBlend.screen,
      );
    }
  }
}

void _finish(Artist a) {
  a.glow(
    _sun,
    420,
    const Color(0x33FFC98A),
    blend: StrokeBlend.screen,
    squash: 0.6,
  );
  for (final c in const [
    Offset(0, 800),
    Offset(0, 0),
    Offset(1200, 800),
    Offset(1200, 0),
  ]) {
    a.glow(c, 420, const Color(0x6610080A), blend: StrokeBlend.multiply);
  }
  a.area(
    const [Offset(0, 0), Offset(1200, 0), Offset(1200, 800), Offset(0, 800)],
    const Fill(Color(0xFFD9CFC0)),
    opacity: 0.35,
    blend: StrokeBlend.multiply,
    texture: StrokeTexture.canvas,
    spacing: 6,
  );
}

/// How far [v] is turned from [from], in radians from -π to π: sorts the
/// points along a cloud's sunlit edge without a jump where angles wrap.
double _turn(Offset v, Offset from) {
  var d = v.direction - from.direction;
  while (d > math.pi) {
    d -= 2 * math.pi;
  }
  while (d < -math.pi) {
    d += 2 * math.pi;
  }
  return d;
}

/// A grain over [outline], darkening it here and there, with nothing
/// showing through it.
void _grain(Artist a, List<Offset> outline, {double o = 0.2}) => a.area(
  outline,
  const Fill(Color(0xFF000000)),
  opacity: o,
  blend: StrokeBlend.multiply,
  texture: StrokeTexture.charcoal,
);
