import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A 2D move, turn and resize applied to a finished stroke when it's
/// painted: `x' = a·x + c·y + tx`, `y' = b·x + d·y + ty`.
///
/// Transforming the canvas (instead of the stroke's points) keeps every
/// brush exact: filled shapes stay crisp, spray and stamps keep their look,
/// and a mirrored pair turns as one piece.
@immutable
class StrokeTransform {
  const StrokeTransform(this.a, this.b, this.c, this.d, this.tx, this.ty);

  /// Scales by [scale] and turns by [angle] (radians, clockwise on screen)
  /// around [center].
  factory StrokeTransform.around(Offset center,
      {double scale = 1, double angle = 0}) {
    final a = scale * math.cos(angle), b = scale * math.sin(angle);
    return StrokeTransform(a, b, -b, a, center.dx - a * center.dx + b * center.dy,
        center.dy - b * center.dx - a * center.dy);
  }

  factory StrokeTransform.translation(Offset delta) =>
      StrokeTransform(1, 0, 0, 1, delta.dx, delta.dy);

  final double a, b, c, d, tx, ty;

  /// How much bigger than the original it is drawn.
  double get scale => math.sqrt(a * a + b * b);

  /// How far it is turned, in radians.
  double get angle => math.atan2(b, a);

  Offset apply(Offset p) =>
      Offset(a * p.dx + c * p.dy + tx, b * p.dx + d * p.dy + ty);

  /// This transform followed by [next].
  StrokeTransform then(StrokeTransform next) => StrokeTransform(
        next.a * a + next.c * b,
        next.b * a + next.d * b,
        next.a * c + next.c * d,
        next.b * c + next.d * d,
        next.a * tx + next.c * ty + next.tx,
        next.b * tx + next.d * ty + next.ty,
      );

  StrokeTransform get inverse {
    final det = a * d - b * c;
    final ia = d / det, ib = -b / det, ic = -c / det, id = a / det;
    return StrokeTransform(
        ia, ib, ic, id, -(ia * tx + ic * ty), -(ib * tx + id * ty));
  }

  /// The upright box around [r] once transformed.
  Rect applyRect(Rect r) {
    final corners = [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]
        .map(apply)
        .toList();
    var out = Rect.fromPoints(corners[0], corners[0]);
    for (final p in corners.skip(1)) {
      out = out.expandToInclude(Rect.fromPoints(p, p));
    }
    return out;
  }

  /// Column-major 4x4 matrix for [Canvas.transform].
  Float64List get matrix4 => Float64List.fromList(
      [a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1]);

  List<double> toJson() => [
        for (final v in [a, b, c, d]) (v * 10000).round() / 10000,
        for (final v in [tx, ty]) (v * 10).round() / 10,
      ];

  static StrokeTransform? fromJson(Object? json) {
    if (json is! List || json.length != 6) return null;
    final v = [for (final n in json.cast<num>()) n.toDouble()];
    return StrokeTransform(v[0], v[1], v[2], v[3], v[4], v[5]);
  }

  @override
  bool operator ==(Object other) =>
      other is StrokeTransform &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.d == d &&
      other.tx == tx &&
      other.ty == ty;

  @override
  int get hashCode => Object.hash(a, b, c, d, tx, ty);
}
