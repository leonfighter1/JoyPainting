import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerHoverEvent;
import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../theme/cute_theme.dart';
import '../../widgets/corner_float.dart';
import '../drawing_controller.dart';
import '../render/layer_cache.dart';
import 'canvas_keys.dart';
import 'canvas_view.dart';

/// The paper and everything finished on it, from [cache] at [ratio] pixels
/// per paper point. Repaints only when that changes; see
/// [DrawingController.finishedRevision].
class FinishedStrokesPainter extends CustomPainter {
  FinishedStrokesPainter(this.controller,
      {required this.cache, required this.ratio})
      : super(repaint: Listenable.merge([controller.finishedRevision, ratio]));

  final DrawingController controller;
  final LayeredCache cache;
  final ValueListenable<double> ratio;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = controller.paper);
    cache.paint(canvas, size, controller.strokes, controller.layers,
        controller.paper, ratio.value,
        eraser: controller.eraser);
  }

  @override
  bool shouldRepaint(FinishedStrokesPainter oldDelegate) =>
      oldDelegate.controller != controller ||
      oldDelegate.cache != cache ||
      oldDelegate.ratio != ratio;
}

/// The stroke being drawn, on its own layer above the finished ones. A
/// blender stroke takes the picture under it from [cache].
class CurrentStrokePainter extends CustomPainter {
  CurrentStrokePainter(this.controller, {required this.cache})
      : super(repaint: controller);

  final DrawingController controller;
  final LayeredCache cache;

  @override
  void paint(Canvas canvas, Size size) {
    final layer = controller.current?.layerId ?? controller.activeLayer;
    controller.paintCurrent(canvas, size,
        finished: cache.imageOf(layer, controller.strokesOn(layer), size));
  }

  @override
  bool shouldRepaint(CurrentStrokePainter oldDelegate) =>
      oldDelegate.controller != controller || oldDelegate.cache != cache;
}

/// A grip on the middle of the paper's right edge ([Axis.horizontal]:
/// drag to make it wider or narrower) or bottom edge (taller or shorter).
/// Screen readers adjust it in steps.
class PaperGrip extends StatelessWidget {
  const PaperGrip({
    super.key,
    required this.axis,
    required this.alignment,
    required this.label,
    required this.value,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onStep,
  });

  final Axis axis;

  /// Where the grip shows in its touch area: on the paper's edge.
  final Alignment alignment;
  final String label;

  /// The paper's width or height now.
  final double value;
  final void Function(PointerDownEvent) onDown;
  final void Function(PointerMoveEvent) onMove;
  final void Function(PointerEvent) onUp;
  final void Function(double step) onStep;

  static const step = 50.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final across = axis == Axis.horizontal;
    return Semantics(
      label: label,
      value: value.round().toString(),
      increasedValue: (value + step).round().toString(),
      decreasedValue: (value - step).round().toString(),
      onIncrease: () => onStep(step),
      onDecrease: () => onStep(-step),
      child: Tooltip(
        message: label,
        child: MouseRegion(
          cursor: across
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.resizeUpDown,
          child: Listener(
            onPointerDown: onDown,
            onPointerMove: onMove,
            onPointerUp: onUp,
            onPointerCancel: onUp,
            behavior: HitTestBehavior.opaque,
            child: Align(
              alignment: alignment,
              child: Container(
                width: across ? 12 : 44,
                height: across ? 44 : 12,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: scheme.onPrimary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// The paper sheet, placed by [layout]: a rounded sketchbook sheet with a
/// soft shadow, the finished drawing, the stroke being drawn on its own
/// layer above it, and [overlay] (guides that aren't part of the picture)
/// over both. Touches on it go to [onDown], [onMove] and [onUp] in paper
/// coordinates.
class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.size,
    required this.layout,
    required this.drawing,
    required this.cache,
    required this.cacheRatio,
    required this.overlay,
    required this.panning,
    required this.repaintKey,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onHover,
    required this.onExit,
  });

  final Size size;
  final PaperLayout layout;
  final DrawingController drawing;

  /// The finished drawing kept as a picture, at [cacheRatio] pixels per
  /// paper point.
  final LayeredCache cache;
  final ValueListenable<double> cacheRatio;
  final CustomPainter overlay;

  /// Shows a hand cursor: a drag moves the paper.
  final bool panning;

  /// On the paper's repaint boundary, to find where it is on screen.
  final GlobalKey repaintKey;
  final PointerDownEventListener onDown;
  final PointerMoveEventListener onMove;
  final void Function(PointerEvent) onUp;
  final void Function(PointerHoverEvent e) onHover;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final cute = CuteTheme.of(context);
    final radius = BorderRadius.circular(cute.radius);
    return Stack(
      children: [
        Positioned.fromRect(
          rect: layout.corner & size * layout.scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: cute.spec.primary.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: FittedBox(
                child: SizedBox.fromSize(
                  size: size,
                  child: Semantics(
                    label: S.of(context).canvasLabel,
                    child: MouseRegion(
                      // A hand while dragging moves the paper.
                      cursor: panning
                          ? SystemMouseCursors.grab
                          : MouseCursor.defer,
                      onHover: onHover,
                      onExit: (_) => onExit(),
                      child: Listener(
                        onPointerDown: onDown,
                        onPointerMove: onMove,
                        onPointerUp: onUp,
                        onPointerCancel: onUp,
                        child: RepaintBoundary(
                          key: repaintKey,
                          child: CustomPaint(
                            key: CanvasKeys.paper,
                            painter: FinishedStrokesPainter(drawing,
                                cache: cache, ratio: cacheRatio),
                            // A big painting is costly to paint: let the
                            // engine keep it while a stroke is drawn on top.
                            isComplex: true,
                            foregroundPainter: overlay,
                            size: size,
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: CurrentStrokePainter(drawing, cache: cache),
                                size: size,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The grips on the middle of the paper's right edge and along its bottom
/// edge, on top of the zoom so they keep their size on screen.
class PaperGrips extends StatelessWidget {
  const PaperGrips({
    super.key,
    required this.room,
    required this.paperRect,
    required this.paperSize,
    required this.floats,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onStep,
  });

  /// The paper area.
  final Size room;

  /// Where the paper is on screen now.
  final Rect paperRect;
  final Size paperSize;

  /// The corners the floating buttons sit in.
  final Set<Corner> floats;
  final void Function(Axis axis, PointerDownEvent e) onDown;
  final PointerMoveEventListener onMove;
  final void Function(PointerEvent e) onUp;
  final void Function(Axis axis, double step) onStep;

  /// Where a grip for the paper edge at [edge] goes: its 48×48 touch area
  /// kept inside [room] (a paper filling the screen has its edges right at
  /// the screen's), and where in that area the grip shows.
  static (Rect, Alignment) place(Size room, Offset edge) {
    const half = 24.0;
    final at = Offset(
      edge.dx.clamp(8, math.max(8, room.width - 8)),
      edge.dy.clamp(8, math.max(8, room.height - 8)),
    );
    final box = Rect.fromCenter(center: at, width: half * 2, height: half * 2);
    final dx = box.left < 0 ? -box.left : math.min(0.0, room.width - box.right);
    final dy = box.top < 0 ? -box.top : math.min(0.0, room.height - box.bottom);
    final moved = box.shift(Offset(dx, dy));
    return (moved, Alignment(-dx / half, -dy / half));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rect = paperRect;
    // The bottom grip stays clear of the floating buttons in the bottom
    // corners (the tools button is wide).
    final along = !floats.contains(Corner.bottomLeft)
        ? 0.25
        : !floats.contains(Corner.bottomRight)
        ? 0.75
        : 0.5;
    return Stack(
      children: [
        for (final axis in Axis.values)
          for (final (box, at) in [
            place(
              room,
              axis == Axis.horizontal
                  ? rect.centerRight
                  : Offset(rect.left + rect.width * along, rect.bottom),
            ),
          ])
            Positioned.fromRect(
              rect: box,
              child: PaperGrip(
                axis: axis,
                alignment: at,
                label: axis == Axis.horizontal
                    ? s.paperWidthGrip
                    : s.paperHeightGrip,
                value: axis == Axis.horizontal
                    ? paperSize.width
                    : paperSize.height,
                onDown: (e) => onDown(axis, e),
                onMove: onMove,
                onUp: onUp,
                onStep: (step) => onStep(axis, step),
              ),
            ),
      ],
    );
  }
}
