
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../settings.dart';
import '../stroke.dart';
import 'overlay_painter.dart';

/// The dashed box around the move tool's selection: [box], turned and
/// resized by [transform] while a handle is dragged (upright otherwise).
typedef SelectionFrame = ({Rect box, StrokeTransform transform});

extension SelectionFrameHandles on SelectionFrame {
  /// The upright frame around [strokes], or null when nothing is selected.
  static SelectionFrame? around(List<Stroke> strokes) {
    if (strokes.isEmpty) return null;
    final bounds = strokes
        .map((s) => s.bounds)
        .reduce((a, b) => a.expandToInclude(b));
    return (box: bounds.inflate(10), transform: _upright);
  }

  static const _upright = StrokeTransform(1, 0, 0, 1, 0, 0);

  /// Drag this corner to make the selection bigger or smaller.
  Offset get scaleHandle => transform.apply(box.bottomRight);

  /// Drag this knob above the box to turn the selection.
  Offset get rotateHandle =>
      transform.apply(box.topCenter - const Offset(0, rotateHandleGap));

  static const rotateHandleGap = 40.0;
}

/// Guides drawn over the paper that are not part of the picture: the dashed
/// mirror axis, the eraser's range circle and the move tool's selection.
class CanvasOverlayPainter extends CustomPainter {
  CanvasOverlayPainter({
    required this.settings,
    required this.eraserCursor,
    required this.selected,
    required this.frame,
    required this.selectionBox,
    required this.accent,
    required this.ink,
  }) : super(
         repaint: Listenable.merge([
           settings,
           eraserCursor,
           frame,
           selectionBox,
         ]),
       );

  final AppSettings settings;
  final ValueListenable<Offset?> eraserCursor;

  /// The move tool's selection.
  final ValueListenable<List<Stroke>> selected;

  /// The dashed box drawn around [selected], with its handles.
  final ValueListenable<SelectionFrame?> frame;

  /// The box being dragged out to select several strokes.
  final ValueListenable<Rect?> selectionBox;
  final Color accent;
  final Color ink;

  /// The eraser circle's radius, matching how wide the eraser actually is.
  static double eraserRadius(AppSettings s) =>
      s.size * BrushType.eraser.sizeFactor / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    if (settings.mirror) {
      final paint = Paint()
        ..color = accent.withValues(alpha: 0.35)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var y = 6.0; y < size.height; y += 16) {
        canvas.drawLine(Offset(mid, y), Offset(mid, y + 8), paint);
      }
    }
    if (frame.value case final f?) _paintSelection(canvas, f);
    if (selectionBox.value case final box?) _paintSelectionBox(canvas, box);
    final at = eraserCursor.value;
    if (at == null || settings.brush != BrushType.eraser) return;
    final r = eraserRadius(settings);
    for (final c in [at, if (settings.mirror) Offset(2 * mid - at.dx, at.dy)]) {
      // A white ring outside a dark ring stays visible on any paper or ink.
      canvas
        ..drawCircle(c, r, Paint()..color = accent.withValues(alpha: 0.12))
        ..drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = Colors.white.withValues(alpha: 0.9),
        )
        ..drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = ink,
        );
    }
  }

  @override
  bool shouldRepaint(CanvasOverlayPainter old) =>
      old.accent != accent || old.ink != ink;

  /// A dashed rounded box around the selection, with corner dots, a resize
  /// handle at the bottom right and a turn knob above.
  void _paintSelection(Canvas canvas, SelectionFrame f) {
    final dash = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // The handles keep their size while the box is resized.
    final scale = f.transform.scale;
    canvas
      ..save()
      ..transform(f.transform.matrix4);
    final box = RRect.fromRectAndRadius(f.box, const Radius.circular(12));
    canvas.drawRRect(box, Paint()..color = accent.withValues(alpha: 0.06));
    for (final metric in (Path()..addRRect(box)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(
          metric.extractPath(d, d + 7),
          dash..strokeWidth = 2 / scale,
        );
      }
    }
    final r = f.box;
    final knob =
        r.topCenter - const Offset(0, SelectionFrameHandles.rotateHandleGap);
    canvas.drawLine(r.topCenter, knob, dash..strokeWidth = 2 / scale);
    for (final c in [r.topLeft, r.topRight, r.bottomLeft]) {
      canvas
        ..drawCircle(c, 6 / scale, Paint()..color = Colors.white)
        ..drawCircle(c, 4.5 / scale, Paint()..color = accent);
    }
    canvas.restore();
    _paintHandle(canvas, f.scaleHandle, Icons.open_in_full_rounded);
    _paintHandle(canvas, f.rotateHandle, Icons.rotate_right_rounded);
  }

  /// A round accent knob with a white icon on it.
  void _paintHandle(Canvas canvas, Offset at, IconData icon) {
    canvas
      ..drawCircle(at, 17, Paint()..color = Colors.white)
      ..drawCircle(at, 15, Paint()..color = accent);
    final glyph = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, at - Offset(glyph.width / 2, glyph.height / 2));
    glyph.dispose();
  }

  /// The see-through box dragged out over empty paper.
  void _paintSelectionBox(Canvas canvas, Rect box) {
    canvas
      ..drawRect(box, Paint()..color = accent.withValues(alpha: 0.10))
      ..drawRect(
        box,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }
}

