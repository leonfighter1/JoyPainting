import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// A check mark that draws itself, from its lower left up to its upper
/// right, when [checked] turns on (in [duration]), and is wiped back the
/// same way when it turns off.
class DrawnCheck extends StatefulWidget {
  const DrawnCheck({
    super.key,
    required this.checked,
    required this.color,
    this.size = 20,
    this.duration = const Duration(milliseconds: 200),
  });

  final bool checked;
  final Color color;
  final double size;
  final Duration duration;

  @override
  State<DrawnCheck> createState() => _DrawnCheckState();
}

class _DrawnCheckState extends State<DrawnCheck>
    with SingleTickerProviderStateMixin {
  late final _drawn = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.checked ? 1 : 0,
  );
  late final _curve = CurvedAnimation(parent: _drawn, curve: Curves.easeOut);

  @override
  void didUpdateWidget(DrawnCheck old) {
    super.didUpdateWidget(old);
    if (old.checked == widget.checked) return;
    _drawn.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : widget.duration;
    widget.checked ? _drawn.forward() : _drawn.reverse();
  }

  @override
  void dispose() {
    _curve.dispose();
    _drawn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(widget.size),
    painter: _CheckPainter(
      drawn: _curve,
      color: widget.color,
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.drawn, required this.color})
    : super(repaint: drawn);

  final Animation<double> drawn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawn.value <= 0) return;
    final s = size.width;
    // Material's check: the short arm down to the corner, then the long
    // arm up to the right.
    final check = Path()
      ..moveTo(0.2 * s, 0.53 * s)
      ..lineTo(0.41 * s, 0.73 * s)
      ..lineTo(0.8 * s, 0.31 * s);
    final PathMetric line = check.computeMetrics().single;
    canvas.drawPath(
      line.extractPath(0, line.length * drawn.value),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.drawn != drawn || old.color != color;
}
