import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometric shapes drawn by dragging from one corner to the opposite one
/// (or from start to end, for lines and arrows).
enum ShapeKind {
  line,
  arrow,
  rectangle,
  ellipse,
  triangle,
  star,
  heart;

  /// Closed shapes can be filled.
  bool get closed => this != line && this != arrow;

  /// null means freehand drawing.
  static ShapeKind? fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }

  /// The exact outline from [a] to [b]. [arrowHead] is the arrow head's
  /// length (scaled to the brush width by the caller).
  Path path(Offset a, Offset b, {double arrowHead = 16}) {
    final r = Rect.fromPoints(a, b);
    final path = Path();
    switch (this) {
      case ShapeKind.line:
        path
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy);
      case ShapeKind.arrow:
        // One continuous outline (shaft, then each side of the head), so
        // spray, rainbow and stamps can follow it without jumps.
        final back = (a - b).direction;
        final head = math.min(arrowHead, (b - a).distance * 0.45);
        final h1 = b + Offset.fromDirection(back + 0.45, head);
        final h2 = b + Offset.fromDirection(back - 0.45, head);
        path
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(h1.dx, h1.dy)
          ..moveTo(b.dx, b.dy)
          ..lineTo(h2.dx, h2.dy);
      case ShapeKind.rectangle:
        path.addRect(r);
      case ShapeKind.ellipse:
        path.addOval(r);
      case ShapeKind.triangle:
        path
          ..moveTo(r.topCenter.dx, r.topCenter.dy)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.left, r.bottom)
          ..close();
      case ShapeKind.star:
        for (var i = 0; i < 10; i++) {
          final k = i.isEven ? 1.0 : 0.45;
          final angle = i * math.pi / 5 - math.pi / 2;
          final p = r.center +
              Offset(math.cos(angle) * r.width / 2 * k,
                  math.sin(angle) * r.height / 2 * k);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();
      case ShapeKind.heart:
        final x = r.left, y = r.top, w = r.width, h = r.height;
        path
          ..moveTo(x + w / 2, y + h * 0.25)
          ..cubicTo(x + w / 2, y, x, y, x, y + h * 0.3)
          ..cubicTo(x, y + h * 0.6, x + w / 2, y + h * 0.8, x + w / 2, y + h)
          ..cubicTo(x + w / 2, y + h * 0.8, x + w, y + h * 0.6, x + w, y + h * 0.3)
          ..cubicTo(x + w, y, x + w / 2, y, x + w / 2, y + h * 0.25)
          ..close();
    }
    return path;
  }
}
