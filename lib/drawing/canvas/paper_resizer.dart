import 'package:flutter/material.dart';

import '../drawing_controller.dart';
import 'canvas_view.dart';

/// Dragging the paper's edge grips to make it wider or taller. Strokes
/// never change; one undo undoes a whole drag.
class PaperResizer {
  PaperResizer({
    required this.drawing,
    required this.view,
    required this.paperSize,
    required this.busy,
  });

  final DrawingController drawing;
  final CanvasViewController view;

  /// The paper's size now.
  final Size Function() paperSize;

  /// True while another touch is drawing or pinching.
  final bool Function() busy;

  /// While an edge grip is dragged, the paper keeps this place and scale
  /// on screen, so it grows or shrinks from its top-left corner, right
  /// under the finger.
  final held = ValueNotifier<PaperLayout?>(null);

  /// The edge grip being dragged. [moved] once the paper changed, so the
  /// whole drag undoes in one step.
  ({int pointer, Axis axis, Offset start, Size size, bool moved})? _drag;

  void start(Axis axis, PointerDownEvent e) {
    if (_drag != null || busy()) return;
    _drag = (
      pointer: e.pointer,
      axis: axis,
      start: e.position,
      size: paperSize(),
      moved: false,
    );
    held.value = view.layout;
  }

  void move(PointerMoveEvent e) {
    final r = _drag;
    if (r == null || r.pointer != e.pointer) return;
    // Screen points to paper points.
    final d = (e.position - r.start) / (view.layout.scale * view.zoom);
    final before = drawing.paperSize;
    drawing.setPaperSize(
      r.axis == Axis.horizontal
          ? Size(r.size.width + d.dx, r.size.height)
          : Size(r.size.width, r.size.height + d.dy),
      recordUndo: !r.moved,
    );
    if (drawing.paperSize != before) {
      _drag = (
        pointer: r.pointer,
        axis: r.axis,
        start: r.start,
        size: r.size,
        moved: true,
      );
    }
  }

  void end(PointerEvent e) {
    final r = _drag;
    if (r == null || r.pointer != e.pointer) return;
    _drag = null;
    // Fit the new size on screen again without the paper jumping: the
    // zoom takes over what the new layout changes.
    view.keepPlace(held.value!, drawing.paperSize ?? paperSize());
    held.value = null;
  }

  /// Makes the paper wider or taller by [step] paper points, for screen
  /// readers and keyboards.
  void step(Axis axis, double step) {
    final size = paperSize();
    drawing.setPaperSize(axis == Axis.horizontal
        ? Size(size.width + step, size.height)
        : Size(size.width, size.height + step));
  }

  void dispose() => held.dispose();
}
