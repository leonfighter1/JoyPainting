import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shapes nature makes, for painting landscapes: fractal ridges, jagged
/// edges and clusters of cloud puffs. All take a seeded [math.Random], so a
/// card comes out the same every time.
abstract final class Nature {
  /// A ridge through [keys] with fractal detail between them (midpoint
  /// displacement): each segment's middle moves up or down by up to
  /// [rough] times its length, until segments are [step] pixels long.
  static List<Offset> ridge(math.Random rnd, List<Offset> keys,
      {double rough = 0.4, double step = 4}) {
    final out = <Offset>[keys.first];
    void split(Offset a, Offset b) {
      final len = (b - a).distance;
      if (len <= step) {
        out.add(b);
        return;
      }
      final mid = Offset.lerp(a, b, 0.5)! +
          Offset(
              (rnd.nextDouble() - 0.5) * len * rough * 0.3,
              (rnd.nextDouble() - 0.5) * len * rough);
      split(a, mid);
      split(mid, b);
    }

    for (var i = 0; i + 1 < keys.length; i++) {
      split(keys[i], keys[i + 1]);
    }
    return out;
  }

  /// A line from [a] to [b] that wanders sideways by up to [rough] times
  /// its length, like a crack, a gully or a fold.
  static List<Offset> wander(math.Random rnd, Offset a, Offset b,
      {double rough = 0.3, double step = 3}) {
    final out = <Offset>[a];
    void split(Offset p, Offset q) {
      final d = q - p;
      final len = d.distance;
      if (len <= step) {
        out.add(q);
        return;
      }
      final n = Offset(-d.dy, d.dx) / len;
      final mid = Offset.lerp(p, q, 0.5)! +
          n * ((rnd.nextDouble() - 0.5) * len * rough);
      split(p, mid);
      split(mid, q);
    }

    split(a, b);
    return out;
  }

  /// The indexes of the peaks in [ridge] (y smallest), each standing at
  /// least [prominence] above the lowest point between it and the next.
  static List<int> peaks(List<Offset> ridge, {double prominence = 12}) {
    final out = <int>[];
    for (var i = 1; i + 1 < ridge.length; i++) {
      final y = ridge[i].dy;
      if (y > ridge[i - 1].dy || y > ridge[i + 1].dy) continue;
      // Highest within a neighborhood.
      var highest = true;
      for (var j = math.max(0, i - 12);
          j < math.min(ridge.length, i + 12);
          j++) {
        if (ridge[j].dy < y) highest = false;
      }
      if (!highest) continue;
      if (out.isNotEmpty) {
        final low = ridge
            .sublist(out.last, i + 1)
            .map((p) => p.dy)
            .reduce(math.max);
        if (low - y < prominence) {
          if (y < ridge[out.last].dy) out[out.length - 1] = i;
          continue;
        }
      }
      out.add(i);
    }
    return out;
  }

  /// The index of the lowest point of [ridge] between [from] and [to].
  static int valley(List<Offset> ridge, int from, int to) {
    var best = from;
    for (var i = from; i <= to; i++) {
      if (ridge[i].dy > ridge[best].dy) best = i;
    }
    return best;
  }

  /// Points around an ellipse, each pushed out or in by up to [jag] times
  /// the radius: an uneven, natural blob.
  static List<Offset> lump(math.Random rnd, Offset c, double rx, double ry,
      {double jag = 0.12, int count = 18, double angle = 0}) {
    final phase = rnd.nextDouble() * math.pi * 2;
    return [
      for (var i = 0; i < count; i++)
        () {
          final t = phase + i * 2 * math.pi / count;
          final k = 1 + (rnd.nextDouble() - 0.5) * 2 * jag;
          final p = Offset(math.cos(t) * rx * k, math.sin(t) * ry * k);
          return c +
              Offset(p.dx * math.cos(angle) - p.dy * math.sin(angle),
                  p.dx * math.sin(angle) + p.dy * math.cos(angle));
        }(),
    ];
  }

  /// A color between [a] and [b], [t] of the way, as a whole 8-bit color.
  static Color mix(Color a, Color b, double t) =>
      Color(Color.lerp(a, b, t.clamp(0.0, 1.0))!.toARGB32());

  /// [c] with its alpha set to [alpha], as a whole 8-bit color.
  static Color fade(Color c, double alpha) =>
      Color(c.withValues(alpha: alpha.clamp(0.0, 1.0)).toARGB32());
}
