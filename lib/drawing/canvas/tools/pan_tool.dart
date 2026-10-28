import 'package:flutter/widgets.dart';

import '../canvas_view.dart';
import 'canvas_tool.dart';

/// ✋ (or the space bar held): one finger or the mouse moves the paper
/// instead of drawing.
class PanTool extends CanvasTool {
  PanTool(this.view);

  final CanvasViewController view;
  ({Offset start, Matrix4 view})? _grab;

  // Screen positions: the paper moves under the finger.
  @override
  void down(ToolPointer p) => _grab = view.grab(p.global);

  @override
  void move(ToolPointer p) {
    if (_grab case final g?) view.dragTo(g, p.global);
  }

  @override
  void up(ToolPointer p) => _grab = null;

  @override
  void cancel() => _grab = null;
}
