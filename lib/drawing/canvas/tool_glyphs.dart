import 'package:flutter/material.dart';

import '../stroke.dart';

/// Little pictures of drawer options, drawn the way the option paints, so
/// every shape, texture and gradient shows what it is (icons can't).
/// [color] is the chip's text color.

/// [kind]'s outline, as the shape tool draws it.
class ShapeGlyph extends StatelessWidget {
  const ShapeGlyph(this.kind, this.color, {super.key});

  final ShapeKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: CustomPaint(painter: _ShapePainter(kind, color)),
  );
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.kind, this.color);

  final ShapeKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = kind.path(
      const Offset(2, 2),
      Offset(size.width - 2, size.height - 2),
      arrowHead: 5,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.kind != kind || old.color != color;
}

/// A dab of [color] with [texture]'s grain in it.
class TextureGlyph extends StatelessWidget {
  const TextureGlyph(this.texture, this.color, {super.key});

  final StrokeTexture texture;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: CustomPaint(painter: _TexturePainter(texture, color)),
  );
}

class _TexturePainter extends CustomPainter {
  _TexturePainter(this.texture, this.color);

  final StrokeTexture texture;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.saveLayer(area, Paint());
    canvas.drawRRect(
      RRect.fromRectAndRadius(area, const Radius.circular(5)),
      Paint()..color = color,
    );
    texture.mask(canvas, area);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TexturePainter old) =>
      old.texture != texture || old.color != color;
}

/// A dot painted with [style] made from the brush color [paint], ringed in
/// [color].
class GradientGlyph extends StatelessWidget {
  const GradientGlyph(this.style, this.paint, this.color, {super.key});

  final GradientStyle style;
  final Color paint;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: CustomPaint(painter: _GradientPainter(style, paint, color)),
  );
}

class _GradientPainter extends CustomPainter {
  _GradientPainter(this.style, this.brush, this.ring);

  final GradientStyle style;
  final Color brush;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final box = (Offset.zero & size).deflate(1);
    final fill = Paint();
    final gradient = style.forColor(brush);
    if (gradient == null) {
      fill.color = brush;
    } else {
      fill.shader = gradient.shader(box, 1);
    }
    canvas
      ..drawOval(box, fill)
      ..drawOval(
        box,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
  }

  @override
  bool shouldRepaint(_GradientPainter old) =>
      old.style != style || old.brush != brush || old.ring != ring;
}
