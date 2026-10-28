import 'dart:async';

import 'package:flutter/material.dart';

import '../../../settings.dart';
import '../../drawing_controller.dart';
import '../../stroke.dart';
import 'canvas_tool.dart';

/// The brushes, shapes and the eraser: each touch draws one stroke with
/// what's chosen in the tools drawer.
class DrawTool extends CanvasTool {
  DrawTool({
    required this.drawing,
    required this.settings,
    required this.paperWidth,
    required this.eraserCursor,
  });

  final DrawingController drawing;
  final AppSettings settings;

  /// The paper's width now, for the mirror axis.
  final double Function() paperWidth;

  /// Where the eraser's range circle shows (null: hidden).
  final ValueNotifier<Offset?> eraserCursor;

  /// How long the eraser is held before its range circle shows.
  static const longPressDelay = Duration(milliseconds: 350);
  Timer? _longPress;
  Offset _last = Offset.zero;

  @override
  void down(ToolPointer p) {
    _last = p.at;
    final stroke = newStroke(
      settings,
      p.at,
      mirrorX: settings.mirror ? paperWidth() / 2 : null,
      stylus: p.stylus,
      layer: drawing.newStrokeLayer,
    );
    // Shapes already have their outline; freehand strokes start at a point.
    drawing.begin(stroke, stroke.shape == null ? p.point : null);
    if (settings.brush == BrushType.eraser) {
      _longPress?.cancel();
      _longPress = Timer(longPressDelay, () => eraserCursor.value = _last);
    }
  }

  @override
  void move(ToolPointer p) {
    _last = p.at;
    if (eraserCursor.value != null) eraserCursor.value = p.at;
    if (drawing.current?.shape != null) {
      drawing.moveShapeEnd(p.at);
    } else {
      drawing.extend(p.point);
    }
  }

  @override
  void up(ToolPointer p) {
    _hideCursor();
    drawing.end();
  }

  @override
  void cancel() {
    _hideCursor();
    drawing.cancel();
  }

  void _hideCursor() {
    _longPress?.cancel();
    eraserCursor.value = null;
  }

  void dispose() => _longPress?.cancel();
}

/// A new stroke starting at [at], with the brush, color, size, shape and
/// looks chosen in [settings].
Stroke newStroke(AppSettings settings, Offset at,
    {double? mirrorX, bool stylus = false, String? layer}) {
  // The eraser always has a round tip; it never draws shapes.
  final brush = settings.brush;
  final shape = brush.usesShapes ? settings.shape : null;
  // Gradients color lines and fills; spray dots and stamps stay plain.
  final gradient = brush.usesColor && brush.kind == BrushKind.outline
      ? settings.gradient.forColor(settings.color)
      : null;
  final blur = brush.blur * settings.size * brush.sizeFactor;
  final blend = brush.usesColor ? settings.blend : StrokeBlend.normal;
  final texture = brush.usesTexture ? settings.texture : StrokeTexture.none;
  if (shape != null) {
    return Stroke.shape(
      shape: shape,
      from: at,
      to: at,
      brush: brush,
      color: settings.color,
      size: settings.size,
      opacity: settings.opacity,
      fill: settings.fill,
      stamp: settings.stamp,
      mirrorX: mirrorX,
      gradient: gradient,
      blur: blur,
      blend: blend,
      texture: texture,
      layer: layer,
    );
  }
  return Stroke(
    brush: brush,
    color: settings.color,
    size: settings.size,
    opacity: settings.opacity,
    stamp: settings.stamp,
    mirrorX: mirrorX,
    fill: brush.usesShapes && settings.freeShape,
    gradient: gradient,
    blur: blur,
    blend: blend,
    texture: texture,
    usesRealPressure: stylus,
    layer: layer,
  );
}
