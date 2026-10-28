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
  heart,
  // Since 6.0.
  roundedRect,
  diamond,
  pentagon,
  hexagon,
  cross,
  cloud,
  moon,
  drop,
  lightning,
  bubble,
  doubleArrow,
  spiral,
  arc,
  wave;

  /// Closed shapes can be filled.
  bool get closed =>
      this != line &&
      this != arrow &&
      this != doubleArrow &&
      this != spiral &&
      this != arc &&
      this != wave;

  /// Shapes from 6.0 on also save their outline as points, so older
  /// versions, which don't know them, show that outline as a line.
  bool get savesOutline => index > heart.index;

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
      case ShapeKind.roundedRect:
        path.addRRect(RRect.fromRectAndRadius(
            r, Radius.circular(math.min(r.width, r.height) * 0.22)));
      case ShapeKind.diamond:
        _polygon(path, r, const [
          Offset(0.5, 0), Offset(1, 0.5), Offset(0.5, 1), Offset(0, 0.5),
        ]);
      case ShapeKind.pentagon:
        _regular(path, r, 5, -math.pi / 2);
      case ShapeKind.hexagon:
        _regular(path, r, 6, 0);
      case ShapeKind.cross:
        const a = 1 / 3, b = 2 / 3;
        _polygon(path, r, const [
          Offset(a, 0), Offset(b, 0), Offset(b, a), Offset(1, a), Offset(1, b),
          Offset(b, b), Offset(b, 1), Offset(a, 1), Offset(a, b), Offset(0, b),
          Offset(0, a), Offset(a, a),
        ]);
      case ShapeKind.cloud:
        // A flat base with three puffs on top, as one outline.
        Path oval(double cx, double cy, double rx, double ry) => Path()
          ..addOval(Rect.fromCenter(
              center: Offset(r.left + r.width * cx, r.top + r.height * cy),
              width: r.width * rx * 2,
              height: r.height * ry * 2));
        var cloud = oval(0.5, 0.74, 0.47, 0.24);
        for (final puff in [
          oval(0.2, 0.62, 0.17, 0.22),
          oval(0.4, 0.44, 0.21, 0.3),
          oval(0.63, 0.4, 0.2, 0.29),
          oval(0.82, 0.6, 0.16, 0.22),
        ]) {
          cloud = Path.combine(PathOperation.union, cloud, puff);
        }
        path.addPath(cloud, Offset.zero);
      case ShapeKind.moon:
        // A crescent: the circle with a shifted circle taken out.
        path.addPath(
            Path.combine(
              PathOperation.difference,
              Path()..addOval(r),
              Path()
                ..addOval(r.shift(Offset(r.width * 0.34, -r.height * 0.12))),
            ),
            Offset.zero);
      case ShapeKind.drop:
        final x = r.left, y = r.top, w = r.width, h = r.height;
        path
          ..moveTo(x + w / 2, y)
          ..cubicTo(x + w * 0.56, y + h * 0.24, x + w, y + h * 0.44, x + w,
              y + h * 0.67)
          ..cubicTo(x + w, y + h * 0.9, x + w * 0.78, y + h, x + w / 2, y + h)
          ..cubicTo(x + w * 0.22, y + h, x, y + h * 0.9, x, y + h * 0.67)
          ..cubicTo(x, y + h * 0.44, x + w * 0.44, y + h * 0.24, x + w / 2, y)
          ..close();
      case ShapeKind.lightning:
        _polygon(path, r, const [
          Offset(0.58, 0), Offset(0.12, 0.56), Offset(0.46, 0.56),
          Offset(0.3, 1), Offset(0.88, 0.38), Offset(0.54, 0.38),
          Offset(0.76, 0),
        ]);
      case ShapeKind.bubble:
        // A speech bubble: a rounded box with a tail at the bottom left.
        final body = Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.78);
        path.addPath(
            Path.combine(
              PathOperation.union,
              Path()
                ..addRRect(RRect.fromRectAndRadius(body,
                    Radius.circular(math.min(body.width, body.height) * 0.22))),
              _polygon(Path(), r, const [
                Offset(0.2, 0.7), Offset(0.12, 1), Offset(0.42, 0.74),
              ]),
            ),
            Offset.zero);
      case ShapeKind.doubleArrow:
        // As the arrow: one outline, a head at each end.
        final head = math.min(arrowHead, (b - a).distance * 0.3);
        final toA = (a - b).direction, toB = (b - a).direction;
        final b1 = b + Offset.fromDirection(toA + 0.45, head);
        final b2 = b + Offset.fromDirection(toA - 0.45, head);
        final a1 = a + Offset.fromDirection(toB + 0.45, head);
        final a2 = a + Offset.fromDirection(toB - 0.45, head);
        path
          ..moveTo(a1.dx, a1.dy)
          ..lineTo(a.dx, a.dy)
          ..lineTo(a2.dx, a2.dy)
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(b1.dx, b1.dy)
          ..moveTo(b.dx, b.dy)
          ..lineTo(b2.dx, b2.dy);
      case ShapeKind.spiral:
        // Three turns out from the middle to the box's edge.
        const steps = 150, turns = 3;
        for (var i = 0; i <= steps; i++) {
          final t = i / steps;
          final angle = t * turns * 2 * math.pi - math.pi / 2;
          final p = r.center +
              Offset(math.cos(angle) * r.width / 2 * t,
                  math.sin(angle) * r.height / 2 * t);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
      case ShapeKind.arc:
        // From the box's bottom left, up through its top middle, down to its
        // bottom right, like an arch.
        path.addArc(
            Rect.fromLTRB(r.left, r.top, r.right, r.bottom + r.height),
            math.pi,
            math.pi);
      case ShapeKind.wave:
        // Along the drag, like a line: two and a half waves, as tall as a
        // sixth of their length.
        final along = b - a;
        final length = along.distance;
        if (length == 0) {
          path.moveTo(a.dx, a.dy);
          break;
        }
        final across = Offset(-along.dy, along.dx) / length;
        const steps = 120, waves = 2.5;
        for (var i = 0; i <= steps; i++) {
          final t = i / steps;
          final p = a +
              along * t +
              across * (math.sin(t * waves * 2 * math.pi) * length / 12);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
    }
    return path;
  }

  /// [corners] (fractions of [r]) joined into a closed outline on [path].
  static Path _polygon(Path path, Rect r, List<Offset> corners) {
    for (final (i, c) in corners.indexed) {
      final p = Offset(r.left + c.dx * r.width, r.top + c.dy * r.height);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// A regular polygon of [sides] filling [r], its first corner at [start]
  /// (radians from the right, clockwise).
  static void _regular(Path path, Rect r, int sides, double start) {
    for (var i = 0; i < sides; i++) {
      final angle = start + i * 2 * math.pi / sides;
      final p = r.center +
          Offset(math.cos(angle) * r.width / 2, math.sin(angle) * r.height / 2);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
  }
}
