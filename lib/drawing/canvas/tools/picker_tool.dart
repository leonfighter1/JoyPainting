import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../settings.dart';
import '../../render/pixel_sampler.dart';
import '../../stroke.dart';
import 'canvas_tool.dart';

/// What the picker's loupe shows: where the finger is, and the paper under
/// it once it has been read.
class PickerLoupe {
  const PickerLoupe(this.at, {this.color, this.patch});

  /// The finger, in the coordinates of the area the loupe floats over.
  final Offset at;
  final Color? color;
  final ui.Image? patch;
}

/// The color picker (eyedropper): touch the paper and move, and the loupe
/// shows the color under the finger; letting go makes it the brush color
/// (kept with the recent colors too) and goes back to the brush used
/// before. Alt + click on a computer picks without changing tools.
class PickerTool extends CanvasTool {
  PickerTool({
    required this.settings,
    required this.sample,
    required this.loupe,
    required this.place,
    required this.returnTo,
  });

  final AppSettings settings;

  /// Reads the paper at a point (paper coordinates).
  final Future<PaperSample> Function(Offset at) sample;

  /// What the loupe shows; null hides it.
  final ValueNotifier<PickerLoupe?> loupe;

  /// Where a point on the screen is in the loupe's area.
  final Offset Function(Offset global) place;

  /// The brush to go back to after picking.
  final BrushType Function() returnTo;

  /// Bumped for every read, so a slow read never shows over a newer one.
  int _reads = 0;

  @override
  void down(ToolPointer p) => _look(p);

  @override
  void move(ToolPointer p) => _look(p);

  @override
  Future<void> up(ToolPointer p) async {
    final read = ++_reads;
    _show(null);
    if (p.cancelled) return;
    final found = await sample(p.at);
    found.patch.dispose();
    if (read != _reads) return;
    // Back to the brush first: picking a color for a tool that draws
    // nothing (the picker itself) would switch to the pen.
    if (settings.brush == BrushType.picker) settings.brush = returnTo();
    settings
      ..color = found.color
      ..addCustomColor(found.color);
  }

  @override
  void cancel() {
    _reads++;
    _show(null);
  }

  Future<void> _look(ToolPointer p) async {
    final read = ++_reads;
    // Follow the finger at once, with the last color until the new one
    // is read.
    final shown = loupe.value;
    loupe.value =
        PickerLoupe(place(p.global), color: shown?.color, patch: shown?.patch);
    final found = await sample(p.at);
    if (read != _reads) {
      found.patch.dispose();
      return;
    }
    _show(PickerLoupe(place(p.global), color: found.color, patch: found.patch));
  }

  /// Shows [next], letting go of the patch shown before.
  void _show(PickerLoupe? next) {
    final old = loupe.value?.patch;
    loupe.value = next;
    if (old != null && old != next?.patch) old.dispose();
  }
}
