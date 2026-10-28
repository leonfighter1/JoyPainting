import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The surface a stroke is painted with: the grain that shows through
/// its paint, like canvas weave, paper, charcoal or the hairs of a brush.
///
/// A texture only takes paint away (it masks the stroke), so whatever is
/// underneath shows through the gaps, as with real paint.
enum StrokeTexture {
  none,

  /// Woven canvas, as under an oil painting.
  canvas,

  /// The soft, uneven grain of drawing paper.
  paper,

  /// Rough and broken, like charcoal or chalk dragged over paper.
  charcoal,

  /// Streaks of a bristle brush, running along the stroke.
  bristle,

  // Since 6.0; older versions paint these without a texture.

  /// Wax crayon: streaky, catching only the tops of the paper's tooth.
  crayon,

  /// Watercolor: pigment pooling in soft blotches.
  watercolor,

  /// Dots of paint side by side (点彩).
  stipple,

  /// Pen lines crossing each other (排线).
  hatch,

  /// The rings of wood grain.
  wood,

  /// Fine grit, like sandpaper.
  sand;

  static StrokeTexture fromName(String? name) =>
      values.firstWhere((t) => t.name == name, orElse: () => none);

  /// Tile pixels per paper pixel: fine enough for pictures exported at 2×.
  static const _density = 2.0;
  static const _tileSize = 256;
  static final _tiles = <StrokeTexture, ui.Image>{};

  /// Masks what was just painted in [area] with this texture, its grain
  /// turned by [angle] (radians). Call inside a layer holding the stroke.
  /// With another [mode] (srcOver), paints the grain as a mask instead:
  /// opaque where the paint stays.
  void mask(Canvas canvas, Rect area,
      {double angle = 0, BlendMode mode = BlendMode.dstIn}) {
    if (this == none) return;
    final tile = _tiles[this] ??= _makeTile(this);
    final m = Matrix4.identity()
      ..rotateZ(angle)
      ..scaleByDouble(1 / _density, 1 / _density, 1, 1);
    canvas.drawRect(
      area,
      Paint()
        ..blendMode = mode
        ..shader = ImageShader(
            tile, TileMode.repeated, TileMode.repeated, m.storage,
            filterQuality: FilterQuality.low),
    );
  }

  /// How much paint stays at each tile pixel (0 to 1), made from tiling
  /// noise so the tiles join without seams.
  static ui.Image _makeTile(StrokeTexture t) {
    const n = _tileSize;
    final fine = _Noise(n, 3), mid = _Noise(n, 5), coarse = _Noise(n, 9);
    double fbm(int x, int y) =>
        fine.at(x, y, 4) * 0.35 +
        mid.at(x, y, 8) * 0.3 +
        coarse.at(x, y, 32) * 0.2 +
        coarse.at(x, y, 64) * 0.15;
    double smooth(double e0, double e1, double v) {
      final k = ((v - e0) / (e1 - e0)).clamp(0.0, 1.0);
      return k * k * (3 - 2 * k);
    }

    // Threads 4 paper pixels wide, over and under each other.
    double weave(int x, int y) {
      const cell = 8;
      final across = math.sin(math.pi * (y % cell + 0.5) / cell);
      final down = math.sin(math.pi * (x % cell + 0.5) / cell);
      return ((x ~/ cell) + (y ~/ cell)).isEven ? across : down;
    }

    // Dots on an 8-pixel grid, nudged a little, soft-edged; each stays
    // inside its cell so the tile joins without seams.
    double stipple(int x, int y) {
      const cell = 8;
      final gx = (x ~/ cell) * cell, gy = (y ~/ cell) * cell;
      final cx = gx + cell / 2 + (mid.at(gx, gy, 8) - 0.5);
      final cy = gy + cell / 2 + (coarse.at(gx, gy, 8) - 0.5);
      final d = math.sqrt(
          math.pow(x + 0.5 - cx, 2) + math.pow(y + 0.5 - cy, 2));
      return 1 - smooth(2.4, 3.5, d) * 0.85;
    }

    // Lines 8 pixels apart in both diagonals.
    double hatch(int x, int y) {
      double lineAt(int v) {
        final d = v % 8;
        return 1 - smooth(0.9, 1.9, math.min(d, 8 - d).toDouble());
      }

      final lines = math.max(lineAt(x + y), lineAt(x - y + 256) * 0.85);
      return 0.12 + 0.88 * lines;
    }

    double alpha(int x, int y) => switch (t) {
          StrokeTexture.none => 1,
          StrokeTexture.canvas =>
            0.62 + 0.26 * weave(x, y) + 0.12 * fine.at(x, y, 2),
          StrokeTexture.paper => 0.66 + 0.34 * smooth(0.2, 0.8, fbm(x, y)),
          StrokeTexture.charcoal =>
            smooth(0.36, 0.56, fbm(x, y) * 0.8 + fine.at(x, y, 2) * 0.2),
          // Long streaks across x, thin across y.
          StrokeTexture.bristle => 0.3 +
              0.7 *
                  smooth(0.2, 0.8,
                      coarse.stretched(x, y, 128, 2) * 0.6 +
                          mid.stretched(x, y, 64, 4) * 0.4),
          StrokeTexture.crayon => 0.1 +
              0.9 *
                  smooth(0.3, 0.5,
                      coarse.stretched(x, y, 64, 4) * 0.35 +
                          fine.at(x, y, 2) * 0.65),
          StrokeTexture.watercolor => 0.5 +
              0.5 *
                  smooth(0.15, 0.85,
                      coarse.at(x, y, 64) * 0.6 + mid.at(x, y, 16) * 0.4),
          StrokeTexture.stipple => stipple(x, y),
          StrokeTexture.hatch => hatch(x, y),
          // Rings 16 pixels apart, wavering with the noise.
          StrokeTexture.wood => 0.4 +
              0.6 *
                  smooth(0.2, 0.8,
                      0.5 +
                          0.5 *
                              math.sin(2 *
                                  math.pi *
                                  (y / 16 +
                                      coarse.at(x, y, 64) * 1.8 +
                                      mid.stretched(x, y, 64, 8) * 0.3))),
          StrokeTexture.sand => 1 -
              0.75 *
                  smooth(0.58, 0.7,
                      fine.at(x, y, 2) * 0.7 + mid.at(x, y, 4) * 0.3),
        };

    // Group pixels by how much paint stays, and draw each group at once.
    const levels = 48;
    final groups = List.generate(levels + 1, (_) => <double>[]);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final level = (alpha(x, y).clamp(0.0, 1.0) * levels).round();
        groups[level]
          ..add(x + 0.5)
          ..add(y + 0.5);
      }
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final (level, points) in groups.indexed) {
      if (level == 0 || points.isEmpty) continue;
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(points),
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, level / levels)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.square
          ..isAntiAlias = false,
      );
    }
    return recorder.endRecording().toImageSync(n, n);
  }
}

/// Smooth random values (0 to 1) over a square of [size] pixels that wraps
/// around at its edges: gradient noise, which has no blocky look.
class _Noise {
  _Noise(this.size, int seed) {
    final rnd = math.Random(seed);
    for (var i = 0; i < _angles.length; i++) {
      _angles[i] = rnd.nextDouble() * 2 * math.pi;
    }
  }

  final int size;
  final _angles = Float64List(256 * 256);

  /// The noise at pixel ([x], [y]) with lattice points [cell] pixels apart.
  double at(int x, int y, int cell) => stretched(x, y, cell, cell);

  /// Like [at], with lattice points [cx] apart across and [cy] down.
  double stretched(int x, int y, int cx, int cy) {
    final px = size ~/ cx, py = size ~/ cy;
    final gx = x / cx, gy = y / cy;
    final x0 = gx.floor(), y0 = gy.floor();
    final fx = gx - x0, fy = gy - y0;
    // The slope at a lattice corner, toward the point.
    double corner(int i, int j, double dx, double dy) {
      final a = _angles[((y0 + j) % py) * 256 + (x0 + i) % px];
      return math.cos(a) * dx + math.sin(a) * dy;
    }

    double fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);
    final u = fade(fx), v = fade(fy);
    final top = corner(0, 0, fx, fy) +
        (corner(1, 0, fx - 1, fy) - corner(0, 0, fx, fy)) * u;
    final bottom = corner(0, 1, fx, fy - 1) +
        (corner(1, 1, fx - 1, fy - 1) - corner(0, 1, fx, fy - 1)) * u;
    return (0.5 + (top + (bottom - top) * v) * 0.75).clamp(0.0, 1.0);
  }
}
