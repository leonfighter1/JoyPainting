import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import '../../../settings.dart';
import '../../drawing_controller.dart';
import '../../render/flood_fill.dart';
import '../../render/pixel_sampler.dart';
import '../../stroke.dart';
import 'canvas_tool.dart';

/// The paint bucket: a tap fills the area around it (everything of about
/// the same color, up to the lines around it) with the chosen color. The
/// fill is an ordinary filled shape on top, so it can be moved, recolored,
/// erased and undone like anything else.
class FillTool extends CanvasTool {
  FillTool({
    required this.drawing,
    required this.settings,
    required this.pixels,
  });

  final DrawingController drawing;
  final AppSettings settings;

  /// The painting as it looks now, as pixels.
  final Future<PaperPixels> Function() pixels;

  /// True while a fill is being worked out; taps meanwhile are ignored.
  final busy = ValueNotifier<bool>(false);

  Offset? _down;
  bool _dragged = false;

  @override
  void down(ToolPointer p) {
    _down = p.at;
    _dragged = false;
  }

  @override
  void move(ToolPointer p) {
    // A drag isn't a tap: it fills nothing.
    if (_down case final d? when (p.at - d).distance > 8) _dragged = true;
  }

  @override
  Future<void> up(ToolPointer p) async {
    final at = _down;
    _down = null;
    if (at == null || p.cancelled || _dragged || busy.value) return;
    await fillAt(at);
  }

  @override
  void cancel() => _down = null;

  /// Fills the area around [at] (paper coordinates).
  Future<void> fillAt(Offset at) async {
    busy.value = true;
    try {
      final image = await pixels();
      final request = FillRequest(
        rgba: image.rgba,
        width: image.width,
        height: image.height,
        x: (at.dx * image.ratio).floor(),
        y: (at.dy * image.ratio).floor(),
        gap: (settings.fillGap * image.ratio).round(),
      );
      final loops = await compute(fillOutlines, request);
      if (loops.isEmpty) return;
      drawing.add(fillStroke(settings, [
        for (final loop in loops) [for (final p in loop) p / image.ratio],
      ]));
    } finally {
      busy.value = false;
    }
  }

  void dispose() => busy.dispose();
}

/// A filled area in the chosen color, opacity and looks.
Stroke fillStroke(AppSettings settings, List<List<Offset>> area) => Stroke(
      brush: BrushType.pen,
      color: settings.color,
      size: 1,
      opacity: settings.opacity,
      usesRealPressure: false,
      fill: true,
      gradient: settings.gradient.forColor(settings.color),
      blend: settings.blend,
      isComplete: true,
      points: [for (final p in area.first) PointVector(p.dx, p.dy, 0.5)],
      area: area,
    );
