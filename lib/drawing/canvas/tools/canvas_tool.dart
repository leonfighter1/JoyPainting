import 'package:flutter/gestures.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

/// One pointer event on the paper, as a tool sees it.
class ToolPointer {
  ToolPointer(PointerEvent e)
      : at = e.localPosition,
        global = e.position,
        stylus = e.kind == PointerDeviceKind.stylus,
        pressure = e.pressure,
        cancelled = e is PointerCancelEvent;

  /// Where on the paper, in paper points.
  final Offset at;

  /// Where on the screen.
  final Offset global;
  final bool stylus;
  final double pressure;

  /// The system took the touch away (a lift that isn't a real lift).
  final bool cancelled;

  /// A point for a freehand stroke: real pressure from a stylus, an even
  /// one from fingers and the mouse.
  PointVector get point => PointVector(at.dx, at.dy, stylus ? pressure : 0.5);
}

/// A tool on the paper. It gets one finger's (or the mouse's) touch, from
/// the moment it lands until it lifts; the drawing screen picks the tool
/// when the touch starts and sends it every event of that touch.
///
/// Adding a tool means adding a class like this and one line where the
/// drawing screen picks tools.
abstract class CanvasTool {
  void down(ToolPointer p);
  void move(ToolPointer p);
  void up(ToolPointer p);

  /// A second finger turned the touch into a pinch: drop what was started.
  void cancel() {}
}
