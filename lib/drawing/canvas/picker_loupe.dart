import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import 'tools/picker_tool.dart';

/// The color picker's loupe: a magnified circle of the paper under the
/// finger, ringed with the color that will be picked. It floats above the
/// finger (below it near the top edge), so the finger never covers it.
/// [PickerLoupe.at] is in this widget's own coordinates.
/// Fill the paper area with it; it takes no touches.
class PickerLoupeView extends StatelessWidget {
  const PickerLoupeView({super.key, required this.loupe});

  final ValueNotifier<PickerLoupe?> loupe;

  static const diameter = 96.0;

  /// How far above the finger the loupe's middle is.
  static const lift = 84.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, area) => ValueListenableBuilder(
          valueListenable: loupe,
          builder: (context, shown, _) {
            if (shown == null) return const SizedBox.shrink();
            final finger = shown.at;
            final above = finger.dy - lift;
            final center = Offset(
              finger.dx.clamp(
                  diameter / 2, math.max(diameter / 2, area.maxWidth - diameter / 2)),
              above >= diameter / 2 ? above : finger.dy + lift,
            );
            final color = shown.color;
            final hex = color == null
                ? ''
                : '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
            return Stack(
              children: [
                Positioned(
                  left: center.dx - diameter / 2,
                  top: center.dy - diameter / 2,
                  width: diameter,
                  height: diameter,
                  child: Semantics(
                    liveRegion: true,
                    label:
                        color == null ? null : S.of(context).pickedColor(hex),
                    child: CustomPaint(
                      painter: _LoupePainter(shown.patch, color),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoupePainter extends CustomPainter {
  _LoupePainter(this.patch, this.color);

  final ui.Image? patch;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
        c + const Offset(0, 3),
        r,
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    if (patch case final p?) {
      // Each paper point a crisp square, as in a magnifying glass.
      canvas.drawImageRect(
          p,
          Rect.fromLTWH(0, 0, p.width.toDouble(), p.height.toDouble()),
          Offset.zero & size,
          Paint()..filterQuality = FilterQuality.none);
      final cell = size.width / p.width;
      canvas.drawRect(
          Rect.fromCenter(center: c, width: cell, height: cell),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white);
      canvas.drawRect(
          Rect.fromCenter(center: c, width: cell + 3, height: cell + 3),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.black54);
    } else {
      canvas.drawCircle(c, r, Paint()..color = Colors.white);
    }
    canvas.restore();
    // The picked color as a thick ring, between a white and a dark line so
    // it shows on any paper.
    canvas
      ..drawCircle(
          c,
          r - 6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..color = color ?? Colors.white)
      ..drawCircle(
          c,
          r - 1,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white)
      ..drawCircle(
          c,
          r - 11.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.black45);
  }

  @override
  bool shouldRepaint(_LoupePainter old) =>
      old.patch != patch || old.color != color;
}
