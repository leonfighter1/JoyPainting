// Line art that hides what's behind, as on a real drawing: draw what's in
// front first, and every closed shape covers what's drawn after it, so
// lines stop at its edge instead of running through it. Used by the
// intermediate and advanced coloring pages.
import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../samples/artist.dart';

class Pen {
  Pen(this.a, {this.width = 5, this.color = const Color(0xFF222222)});

  final Artist a;

  /// The width lines get unless they ask for another.
  double width;
  final Color color;

  final _covers = <({Rect box, List<Offset> outline})>[];

  /// From now on, nothing drawn shows inside [outline].
  void cover(List<Offset> outline) =>
      _covers.add((box: Artist.boxOf(outline), outline: outline));

  bool _hidden(Offset p) {
    for (final c in _covers) {
      if (c.box.contains(p) && inside(p, c.outline)) return true;
    }
    return false;
  }

  /// Whether [p] is inside the outline [poly].
  static bool inside(Offset p, List<Offset> poly) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final a = poly[i], b = poly[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// A line straight between [pts], wherever it isn't covered.
  void path(List<Offset> pts, {double? width}) {
    final dense = Artist.densify(pts, 1);
    var run = <Offset>[];
    void flush() {
      if (run.length > 1) a.line(_thin(run), color, width: width ?? this.width);
      run = [];
    }

    for (final p in dense) {
      if (_hidden(p)) {
        flush();
      } else {
        run.add(p);
      }
    }
    flush();
  }

  /// [run] with a point every 3 pixels or so: plenty for a smooth line,
  /// and the files stay small.
  static List<Offset> _thin(List<Offset> run) {
    final out = [run.first];
    for (final p in run.skip(1)) {
      if ((p - out.last).distance >= 3) out.add(p);
    }
    if (out.last != run.last) out.add(run.last);
    return out;
  }

  /// A smooth line through [corners].
  void curve(List<Offset> corners, {double? width}) =>
      path(Artist.spline(corners), width: width);

  /// The outline of [pts] (closed with straight sides); it then covers
  /// what's drawn later, unless [covers] is false.
  void shape(List<Offset> pts, {double? width, bool covers = true}) {
    path([...pts, pts.first, if (pts.length > 1) pts[1]], width: width);
    if (covers) cover(pts);
  }

  /// A smooth closed outline through [corners].
  void blob(List<Offset> corners, {double? width, bool covers = true}) =>
      shape(Artist.spline(corners, closed: true),
          width: width, covers: covers);

  /// An ellipse turned by [angle] (radians, clockwise).
  void oval(Offset c, double rx, double ry,
          {double angle = 0, double? width, bool covers = true}) =>
      shape(ovalPoints(c, rx, ry, angle: angle), width: width, covers: covers);

  void circle(Offset c, double r, {double? width, bool covers = true}) =>
      oval(c, r, r, width: width, covers: covers);

  static List<Offset> ovalPoints(Offset c, double rx, double ry,
      {double angle = 0}) {
    final n = math.max(24, (math.max(rx, ry) * 0.8).round());
    final cos = math.cos(angle), sin = math.sin(angle);
    return [
      for (var i = 0; i < n; i++)
        () {
          final t = i * 2 * math.pi / n;
          final x = rx * math.cos(t), y = ry * math.sin(t);
          return c + Offset(x * cos - y * sin, x * sin + y * cos);
        }(),
    ];
  }

  /// A five-pointed star.
  void star(Offset c, double r, {double inner = 0.45, double? width}) =>
      shape([
        for (var i = 0; i < 10; i++)
          c +
              Offset.fromDirection(
                  i * math.pi / 5 - math.pi / 2, i.isEven ? r : r * inner),
      ], width: width);

  /// Points on a circle's arc, angles in degrees clockwise from the right
  /// (y points down).
  static List<Offset> arc(Offset c, double r, double from, double to,
          {int? steps}) =>
      [
        for (var i = 0, n = steps ?? math.max(8, ((to - from).abs() * r / 120).round());
            i <= n;
            i++)
          c + Offset.fromDirection((from + (to - from) * i / n) * math.pi / 180, r),
      ];

  /// Smooth pieces joined at sharp corners: each piece is a spline, and
  /// one ends where the next starts.
  static List<Offset> joined(List<List<Offset>> pieces) =>
      [for (final piece in pieces) ...Artist.spline(piece)];

  /// A pointed leaf from [base] to [tip], [across] wide, with its midrib
  /// ([vein] wide, thinner than the outline unless asked).
  void leaf(Offset base, Offset tip, double across,
      {double? width, double? vein}) {
    final d = tip - base;
    final n = Offset(-d.dy, d.dx) / d.distance * across;
    path([base + d * 0.08, base + d * 0.8],
        width: vein ?? (width ?? this.width) * 0.6);
    shape(
        joined([
          [base, base + d * 0.35 + n * 0.5, base + d * 0.72 + n * 0.32, tip],
          [tip, base + d * 0.72 - n * 0.32, base + d * 0.35 - n * 0.5, base],
        ]),
        width: width);
  }

  /// A tube's outline (one side, then the other side back) with its far
  /// end rounded off.
  static List<Offset> rounded(List<Offset> tube) {
    final n = tube.length ~/ 2;
    final a = tube[n - 1], b = tube[n];
    final mid = (a + b) / 2;
    final r = (a - b).distance / 2;
    final from = math.atan2(a.dy - mid.dy, a.dx - mid.dx) * 180 / math.pi;
    // Round the outside: the way the tube was heading.
    final along = tube[n - 1] - tube[n - 2];
    var turn = math.atan2(along.dy, along.dx) * 180 / math.pi - from;
    while (turn > 180) {
      turn -= 360;
    }
    while (turn < -180) {
      turn += 360;
    }
    return [
      ...tube.take(n),
      ...arc(mid, r, from, from + (turn > 0 ? 180 : -180)),
      ...tube.skip(n),
    ];
  }

  /// The outline around [spine], [widths] wide at each point (see
  /// [Artist.tube]), smoothed.
  static List<Offset> tube(List<Offset> spine, double Function(double t) width) {
    final s = Artist.spline(spine);
    return Artist.tube(s, [
      for (var i = 0; i < s.length; i++) width(i / (s.length - 1)),
    ]);
  }
}
