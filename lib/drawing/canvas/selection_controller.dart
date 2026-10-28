import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../settings.dart';
import '../drawing_controller.dart';
import '../stroke.dart';
import 'overlay_painter.dart';

/// The move tool's selection and everything that can be done with it:
/// picking strokes up, moving, resizing and turning them, box selection,
/// copy and paste, recoloring and fading.
///
/// The selection bar, keyboard shortcuts and the move tool all call these
/// methods, so each action behaves the same wherever it starts.
class SelectionController {
  SelectionController({required this.drawing, required this.settings});

  final DrawingController drawing;
  final AppSettings settings;

  /// The strokes the move tool has selected, outlined on the paper.
  final selected = ValueNotifier<List<Stroke>>(const []);

  /// The dashed box around [selected], with its resize and turn handles.
  final frame = ValueNotifier<SelectionFrame?>(null);

  /// The box being dragged out over empty paper to select several strokes.
  final box = ValueNotifier<Rect?>(null);

  /// True while a finger moves, resizes or turns the selection (the
  /// selection bar hides meanwhile).
  final moving = ValueNotifier<bool>(false);

  /// How close (in paper points) a touch must be to grab a handle.
  static const handleReach = 30.0;
  static const minScale = 0.1;
  static const maxScale = 10.0;

  /// How far a finger must move before a tap becomes a drag.
  static const dragSlop = 6.0;

  _MoveGesture? _gesture;

  /// The brush the selection was last synced with.
  BrushType? _syncedBrush;

  bool get isEmpty => selected.value.isEmpty;

  void select(List<Stroke> strokes, {SelectionFrame? frame}) {
    selected.value = List.unmodifiable(strokes);
    this.frame.value = frame ?? SelectionFrameHandles.around(strokes);
  }

  void clear() => select(const []);

  // --- Touches -------------------------------------------------------------

  /// Touching a handle resizes or turns the selection; touching a selected
  /// stroke (or anywhere inside the selection's box) moves the selection;
  /// touching another stroke selects and moves just that one; touching
  /// empty paper starts a box that selects every stroke it catches.
  void startMove(Offset p) {
    final sel = selected.value;
    final f = frame.value;
    if (f != null && sel.isNotEmpty) {
      if ((p - f.scaleHandle).distance <= handleReach) {
        return _start(_MoveGesture(_MoveMode.scale, sel, p, f.box));
      }
      if ((p - f.rotateHandle).distance <= handleReach) {
        return _start(_MoveGesture(_MoveMode.rotate, sel, p, f.box));
      }
    }
    final hit = drawing.hitStroke(p);
    if (hit != null && !sel.contains(hit)) {
      select([hit]);
      return _start(_MoveGesture(_MoveMode.drag, [hit], p, frame.value!.box));
    }
    if (f != null && (hit != null || f.box.contains(p))) {
      return _start(_MoveGesture(_MoveMode.drag, sel, p, f.box));
    }
    clear();
    _start(_MoveGesture(_MoveMode.box, const [], p, Rect.zero));
    box.value = Rect.fromPoints(p, p);
  }

  void _start(_MoveGesture g) {
    _gesture = g;
    moving.value = true;
  }

  void continueMove(Offset p) {
    final g = _gesture;
    if (g == null) return;
    final center = g.frame.center;
    switch (g.mode) {
      case _MoveMode.box:
        box.value = Rect.fromPoints(g.down, p);
      case _MoveMode.drag:
        final delta = p - g.down;
        if (g.current == null && delta.distance < dragSlop) return;
        _applyMove(g, [for (final s in g.originals) s.moved(delta)]);
      case _MoveMode.scale:
        final k =
            ((p - center).distance / math.max(1, (g.down - center).distance))
                .clamp(minScale, maxScale);
        _applyMove(g, null, StrokeTransform.around(center, scale: k));
      case _MoveMode.rotate:
        final angle = (p - center).direction - (g.down - center).direction;
        _applyMove(g, null, StrokeTransform.around(center, angle: angle));
    }
  }

  /// Puts the moved strokes on the paper. A resize or turn ([t]) also turns
  /// the dashed box with them, so the handles stay under the finger.
  void _applyMove(_MoveGesture g, List<Stroke>? moved, [StrokeTransform? t]) {
    final next = moved ?? [for (final s in g.originals) s.transformed(t!)];
    // Only the first step records undo, so a whole drag undoes at once.
    drawing.replaceAll(
      g.current ?? g.originals,
      next,
      recordUndo: g.current == null,
    );
    g.current = next;
    select(next, frame: t == null ? null : (box: g.frame, transform: t));
  }

  void endMove({required bool cancelled}) {
    final g = _gesture;
    _gesture = null;
    if (g == null) return;
    if (g.mode == _MoveMode.box) {
      final dragged = box.value;
      box.value = null;
      // A tap on empty paper selects nothing.
      if (!cancelled && dragged != null && dragged.longestSide >= dragSlop) {
        select(drawing.strokesIn(dragged));
      }
    } else if (g.current case final moved?) {
      // Back to an upright box around the new shape.
      select(moved);
    }
    moving.value = false;
  }

  // --- Actions -------------------------------------------------------------

  /// Resizes or turns the whole selection around its middle (from the
  /// selection bar's buttons).
  void transform({double scale = 1, double angle = 0}) {
    final sel = selected.value;
    final f = frame.value;
    if (sel.isEmpty || f == null) return;
    final t = StrokeTransform.around(f.box.center, scale: scale, angle: angle);
    final next = [for (final s in sel) s.transformed(t)];
    drawing.replaceAll(sel, next);
    select(next);
  }

  /// Copies sit a little down and to the right, and become the selection.
  void duplicate() {
    final copies = [
      for (final s in selected.value) s.moved(const Offset(24, 24)),
    ];
    drawing.addAll(copies);
    select(copies);
  }

  void delete() {
    drawing.removeAll(selected.value);
    clear();
  }

  /// Copied strokes (Ctrl+C), kept while the app is open, so they can be
  /// pasted into another painting too.
  List<Stroke> _clipboard = const [];

  /// How many times the clipboard was pasted: each paste lands a step
  /// further down and right, so copies don't hide each other.
  int _pastes = 0;

  void copy() {
    _clipboard = selected.value;
    _pastes = 0;
  }

  void cut() {
    copy();
    delete();
  }

  /// Adds a copy of the clipboard to the active layer, selected with the
  /// move tool, so it can be dragged into place right away.
  void paste() {
    if (_clipboard.isEmpty) return;
    _pastes++;
    final copies = [
      for (final s in _clipboard)
        s
            .moved(const Offset(24, 24) * _pastes.toDouble())
            .onLayer(drawing.activeLayer),
    ];
    settings.brush = BrushType.move;
    drawing.addAll(copies);
    select(copies);
  }

  /// Everything on the active layer, with the move tool (eraser and
  /// blender strokes have no paint of their own, so they're never
  /// selected).
  void selectAll() {
    settings.brush = BrushType.move;
    select([
      for (final s in drawing.strokes)
        if (!s.brush.isEffect && drawing.pickable(s)) s,
    ]);
  }

  /// Recolors the selection. Rainbow strokes keep their own colors.
  void recolor(Color color) {
    final sel = selected.value;
    final next = [
      for (final s in sel)
        s.brush == BrushType.rainbow ? s : s.copyWith(color: color),
    ];
    drawing.replaceAll(sel, next);
    select(next);
  }

  /// Sets the selection's opacity. Pass `recordUndo: false` while the
  /// slider is still being dragged.
  void fade(double opacity, {required bool recordUndo}) {
    final sel = selected.value;
    final next = [for (final s in sel) s.copyWith(opacity: opacity)];
    drawing.replaceAll(sel, next, recordUndo: recordUndo);
    select(next);
  }

  // --- Keeping in step -----------------------------------------------------

  /// Switching to the move tool selects the last thing drawn; switching
  /// away clears the selection.
  void syncWithBrush() {
    final brush = settings.brush;
    if (brush != BrushType.move) {
      if (selected.value.isNotEmpty) clear();
    } else if (_syncedBrush != BrushType.move) {
      // Eraser and blender strokes are never selected.
      final last = drawing.strokes.reversed
          .where((s) => !s.brush.isEffect && drawing.pickable(s))
          .firstOrNull;
      select([?last]);
    }
    _syncedBrush = brush;
  }

  /// Undo can remove selected strokes, and another layer can become the
  /// active one; the rest stay selected.
  void keepDrawnOnly() {
    if (_gesture != null) return;
    final sel = selected.value;
    final kept = [
      for (final s in sel)
        if (drawing.strokes.contains(s) && drawing.pickable(s)) s,
    ];
    if (kept.length != sel.length) select(kept);
  }

  void dispose() {
    selected.dispose();
    frame.dispose();
    box.dispose();
    moving.dispose();
  }
}

enum _MoveMode { drag, scale, rotate, box }

/// One touch of the move tool.
class _MoveGesture {
  _MoveGesture(this.mode, this.originals, this.down, this.frame);

  final _MoveMode mode;

  /// The strokes as they were when the finger went down.
  final List<Stroke> originals;
  final Offset down;

  /// The selection's box when the finger went down; resizing and turning
  /// happen around its middle.
  final Rect frame;

  /// The moved strokes now on the paper, after the first step.
  List<Stroke>? current;
}
