import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

/// What to fill: the painting's pixels and where it was tapped.
class FillRequest {
  const FillRequest({
    required this.rgba,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    this.tolerance = 32,
    this.gap = 0,
  });

  /// RGBA bytes, row by row.
  final Uint8List rgba;
  final int width;
  final int height;

  /// The pixel tapped.
  final int x;
  final int y;

  /// How far (0–255, in any channel) a color may be from the tapped one
  /// and still be filled.
  final int tolerance;

  /// Gaps in a line up to about twice this many pixels are closed, so a
  /// shape that isn't quite closed still fills without leaking.
  final int gap;
}

/// The outlines of the area around the tapped pixel whose color is close
/// to the tapped one, in pixel coordinates: the outer one first, then its
/// holes. Fill them even-odd. Runs on its own (for `compute`).
///
/// The area reaches one pixel under the edges around it, so no light seam
/// shows along anti-aliased lines; holes smaller than a few pixels are
/// filled over (spray dots, specks).
List<List<Offset>> fillOutlines(FillRequest r) {
  final w = r.width, h = r.height;
  if (r.x < 0 || r.y < 0 || r.x >= w || r.y >= h) return const [];
  final n = w * h;
  final seed = r.y * w + r.x;
  final px = r.rgba;
  final s = seed * 4;
  // Everything that isn't (nearly) the tapped color stops the fill.
  final edge = Uint8List(n);
  for (var i = 0, j = 0; i < n; i++, j += 4) {
    final d = math.max(
        math.max((px[j] - px[s]).abs(), (px[j + 1] - px[s + 1]).abs()),
        math.max((px[j + 2] - px[s + 2]).abs(), (px[j + 3] - px[s + 3]).abs()));
    if (d > r.tolerance) edge[i] = 1;
  }
  // Gaps are closed by thickening the edges; a tap right next to an edge
  // fills without closing gaps instead.
  var gap = r.gap;
  var walls = _grow(edge, w, h, gap);
  if (walls[seed] == 1) {
    gap = 0;
    walls = edge;
  }
  var area = _flood(walls, w, h, seed);
  // Back out to the real edges, and one pixel under them.
  if (gap > 0) {
    area = _grow(area, w, h, gap);
    for (var i = 0; i < n; i++) {
      if (edge[i] == 1) area[i] = 0;
    }
  }
  area = _grow(area, w, h, 1);
  final loops = _outlines(area, w, h)
    ..removeWhere((l) => _area(l).abs() < 6)
    ..sort((a, b) => _area(b).abs().compareTo(_area(a).abs()));
  var eps = 0.75;
  var simple = [for (final l in loops) _simplify(l, eps)];
  // Keep very busy areas light enough to save and paint.
  while (simple.fold<int>(0, (t, l) => t + l.length) > 30000 && eps < 8) {
    eps *= 2;
    simple = [for (final l in loops) _simplify(l, eps)];
  }
  return [
    for (final l in simple)
      if (l.length >= 3) l,
  ];
}

/// [mask] grown by [k] pixels in every direction (a square).
Uint8List _grow(Uint8List mask, int w, int h, int k) {
  if (k <= 0) return mask;
  final across = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    final row = y * w;
    var count = 0;
    for (var x = 0; x <= math.min(k, w - 1); x++) {
      count += mask[row + x];
    }
    for (var x = 0; x < w; x++) {
      if (count > 0) across[row + x] = 1;
      if (x + k + 1 < w) count += mask[row + x + k + 1];
      if (x - k >= 0) count -= mask[row + x - k];
    }
  }
  final out = Uint8List(w * h);
  for (var x = 0; x < w; x++) {
    var count = 0;
    for (var y = 0; y <= math.min(k, h - 1); y++) {
      count += across[y * w + x];
    }
    for (var y = 0; y < h; y++) {
      if (count > 0) out[y * w + x] = 1;
      if (y + k + 1 < h) count += across[(y + k + 1) * w + x];
      if (y - k >= 0) count -= across[(y - k) * w + x];
    }
  }
  return out;
}

/// The pixels reachable from [seed] (up, down, left, right) without
/// crossing [walls].
Uint8List _flood(Uint8List walls, int w, int h, int seed) {
  final area = Uint8List(w * h);
  bool open(int i) => walls[i] == 0 && area[i] == 0;
  final todo = [seed];
  while (todo.isNotEmpty) {
    final i = todo.removeLast();
    if (!open(i)) continue;
    final y = i ~/ w, row = y * w;
    var left = i - row, right = left;
    while (left > 0 && open(row + left - 1)) {
      left--;
    }
    while (right < w - 1 && open(row + right + 1)) {
      right++;
    }
    for (var x = left; x <= right; x++) {
      area[row + x] = 1;
    }
    // One seed per run of open pixels above and below.
    for (final next in [row - w, row + w]) {
      if (next < 0 || next >= w * h) continue;
      var inRun = false;
      for (var x = left; x <= right; x++) {
        final o = open(next + x);
        if (o && !inRun) todo.add(next + x);
        inRun = o;
      }
    }
  }
  return area;
}

/// Every boundary of [area] as closed loops along pixel edges, each edge
/// used once (so even-odd filling them gives back exactly [area]).
List<List<Offset>> _outlines(Uint8List area, int w, int h) {
  final stride = w + 1;
  final next = <int, List<int>>{};
  void edge(int fx, int fy, int tx, int ty) =>
      (next[fy * stride + fx] ??= []).add(ty * stride + tx);
  bool inside(int x, int y) =>
      x >= 0 && y >= 0 && x < w && y < h && area[y * w + x] == 1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (area[y * w + x] == 0) continue;
      if (!inside(x, y - 1)) edge(x, y, x + 1, y);
      if (!inside(x + 1, y)) edge(x + 1, y, x + 1, y + 1);
      if (!inside(x, y + 1)) edge(x + 1, y + 1, x, y + 1);
      if (!inside(x - 1, y)) edge(x, y + 1, x, y);
    }
  }
  final loops = <List<Offset>>[];
  while (next.isNotEmpty) {
    final start = next.keys.first;
    final loop = <Offset>[];
    var at = start;
    do {
      loop.add(Offset((at % stride).toDouble(), (at ~/ stride).toDouble()));
      final outs = next[at]!;
      final to = outs.removeLast();
      if (outs.isEmpty) next.remove(at);
      at = to;
    } while (at != start && next.containsKey(at));
    loops.add(_dropStraight(loop));
  }
  return loops;
}

/// [loop] without the points in the middle of straight runs.
List<Offset> _dropStraight(List<Offset> loop) {
  if (loop.length < 4) return loop;
  final out = <Offset>[];
  for (var i = 0; i < loop.length; i++) {
    final a = loop[(i - 1 + loop.length) % loop.length];
    final b = loop[i];
    final c = loop[(i + 1) % loop.length];
    final cross = (b.dx - a.dx) * (c.dy - b.dy) - (b.dy - a.dy) * (c.dx - b.dx);
    if (cross != 0) out.add(b);
  }
  return out;
}

/// Twice the signed area of [loop].
double _area(List<Offset> loop) {
  var sum = 0.0;
  for (var i = 0; i < loop.length; i++) {
    final a = loop[i], b = loop[(i + 1) % loop.length];
    sum += a.dx * b.dy - b.dx * a.dy;
  }
  return sum;
}

/// [loop] with points closer than [eps] to the line between their
/// neighbours left out (Douglas–Peucker, for a closed loop).
List<Offset> _simplify(List<Offset> loop, double eps) {
  if (loop.length < 8) return loop;
  var far = 0;
  var most = -1.0;
  for (var i = 1; i < loop.length; i++) {
    final d = (loop[i] - loop[0]).distanceSquared;
    if (d > most) {
      most = d;
      far = i;
    }
  }
  final keep = List.filled(loop.length + 1, false);
  final pts = [...loop, loop[0]];
  keep[0] = keep[far] = keep[pts.length - 1] = true;
  final spans = [(0, far), (far, pts.length - 1)];
  while (spans.isNotEmpty) {
    final (a, b) = spans.removeLast();
    if (b - a < 2) continue;
    var worst = a;
    var dist = 0.0;
    for (var i = a + 1; i < b; i++) {
      final d = _distance(pts[i], pts[a], pts[b]);
      if (d > dist) {
        dist = d;
        worst = i;
      }
    }
    if (dist > eps) {
      keep[worst] = true;
      spans
        ..add((a, worst))
        ..add((worst, b));
    }
  }
  return [
    for (var i = 0; i < pts.length - 1; i++)
      if (keep[i]) pts[i],
  ];
}

double _distance(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len = ab.distance;
  if (len == 0) return (p - a).distance;
  return ((p.dx - a.dx) * ab.dy - (p.dy - a.dy) * ab.dx).abs() / len;
}
