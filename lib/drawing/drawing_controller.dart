
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'render/paint_strokes.dart';
import 'stroke.dart';

/// What the drawing looked like before an edit, for undo and redo.
class _Snapshot {
  _Snapshot(List<Stroke> strokes, this.paper, this.paperSize)
      : strokes = List.of(strokes);

  final List<Stroke> strokes;
  final Color paper;
  final Size? paperSize;
}

/// Holds the strokes and paper color of the open painting, plus its
/// undo/redo history.
///
/// Every edit (a stroke, clearing, moving or editing text, changing paper)
/// records a snapshot first, so all of them can be undone. Strokes are never
/// changed in place, so a snapshot only needs to copy the list.
class DrawingController extends ChangeNotifier {
  final List<Stroke> strokes = [];
  final List<_Snapshot> _undo = [];
  final List<_Snapshot> _redo = [];
  Stroke? current;
  Color paper = Colors.white;

  /// The paper's own size, or null for paper that fills the screen (and
  /// grows to fit what's drawn), as new paintings have. Strokes never
  /// change with it: a smaller paper only hides what's past its edges.
  Size? get paperSize => paperSizeListenable.value;
  final paperSizeListenable = ValueNotifier<Size?>(null);
  static const minPaperSide = 100.0;
  static const maxPaperSide = 8000.0;

  /// Older steps are forgotten past this many, to bound memory.
  static const maxUndo = 100;

  /// Bumped when what's finished (strokes, paper) changes, and on every
  /// move of the eraser, which cuts into it; not while another stroke is
  /// being drawn. The finished drawing has its own layer, so a big painting
  /// isn't painted again for every point of a new stroke.
  final finishedRevision = ValueNotifier<int>(0);

  bool get _erasing => current?.brush == BrushType.eraser;

  /// The eraser stroke being drawn, if the eraser is in use.
  Stroke? get eraser => _erasing ? current : null;

  /// Bumped whenever the finished drawing changes, so listeners can tell an
  /// edit worth saving apart from a repaint of the stroke being drawn.
  int revision = 0;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get isEmpty => strokes.isEmpty && current == null;

  /// The area everything drawn so far covers, or [Rect.zero] if nothing is.
  Rect get contentBounds => strokes.isEmpty
      ? Rect.zero
      : strokes.map((s) => s.bounds).reduce((a, b) => a.expandToInclude(b));

  /// Starts [stroke]. Freehand strokes pass their first [point]; shape
  /// strokes already have their outline.
  void begin(Stroke stroke, [PointVector? point]) {
    current = stroke;
    if (point != null) stroke.points.add(point);
    if (_erasing) finishedRevision.value++;
    notifyListeners();
  }

  void extend(PointVector point) {
    if (current == null) return;
    current!.points.add(point);
    if (_erasing) finishedRevision.value++;
    notifyListeners();
  }

  /// Drops the stroke being drawn without keeping it, for example when a
  /// second finger turns the touch into a pinch.
  void cancel() {
    if (current == null) return;
    if (_erasing) finishedRevision.value++;
    current = null;
    notifyListeners();
  }

  /// Drags the far corner of the shape being drawn.
  void moveShapeEnd(Offset end) {
    final c = current;
    if (c == null || c.shape == null) return;
    c.setShapeEnds(c.shapeFrom!, end);
    notifyListeners();
  }

  void end() {
    if (current == null) return;
    if (current!.isDegenerateShape) {
      // A tap with a shape tool draws nothing.
      current = null;
      notifyListeners();
      return;
    }
    _record();
    strokes.add(current!..isComplete = true);
    current = null;
    _changed();
  }

  /// Adds a finished stroke, such as a new text item.
  void add(Stroke stroke) {
    _record();
    strokes.add(stroke);
    _changed();
  }

  /// Swaps [old] for [replacement] in place, keeping its layer order.
  /// Pass `recordUndo: false` for the later steps of one continuous edit
  /// (like dragging text), so the whole drag undoes in one step.
  void replace(Stroke old, Stroke replacement, {bool recordUndo = true}) {
    final i = strokes.indexOf(old);
    if (i < 0) return;
    if (recordUndo) _record();
    strokes[i] = replacement;
    _changed();
  }

  /// Swaps each of [olds] for the replacement at the same index, as one
  /// edit. See [replace] for `recordUndo`.
  void replaceAll(List<Stroke> olds, List<Stroke> replacements,
      {bool recordUndo = true}) {
    assert(olds.length == replacements.length);
    if (!olds.any(strokes.contains)) return;
    if (recordUndo) _record();
    for (final (i, old) in olds.indexed) {
      final at = strokes.indexOf(old);
      if (at >= 0) strokes[at] = replacements[i];
    }
    _changed();
  }

  /// Adds finished strokes on top, as one edit (for example copies).
  void addAll(List<Stroke> added) {
    if (added.isEmpty) return;
    _record();
    strokes.addAll(added);
    _changed();
  }

  void remove(Stroke stroke) => removeAll([stroke]);

  /// Removes [removed] as one edit.
  void removeAll(List<Stroke> removed) {
    if (!removed.any(strokes.contains)) return;
    _record();
    strokes.removeWhere(removed.contains);
    _changed();
  }

  /// The topmost stroke of any kind under [point], if any.
  Stroke? hitStroke(Offset point) {
    for (final s in strokes.reversed) {
      // Eraser and blender strokes have no paint of their own to pick up.
      if (!s.brush.isEffect && s.hits(point)) return s;
    }
    return null;
  }

  /// Every visible stroke a selection box over [box] catches, in drawing
  /// order.
  List<Stroke> strokesIn(Rect box) => [
        for (final s in strokes)
          if (!s.brush.isEffect && s.touches(box)) s,
      ];

  /// The topmost text item under [point], if any.
  Stroke? hitText(Offset point) {
    for (final s in strokes.reversed) {
      if (s.text != null && s.hits(point)) return s;
    }
    return null;
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(_Snapshot(strokes, paper, paperSize));
    _restore(_undo.removeLast());
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(_Snapshot(strokes, paper, paperSize));
    _restore(_redo.removeLast());
  }

  /// Removes every stroke. Can be undone.
  void clear() {
    if (strokes.isEmpty) return;
    _record();
    strokes.clear();
    current = null;
    _changed();
  }

  /// Changes the paper's size (null: back to filling the screen), in
  /// whole pixels within [minPaperSide] and [maxPaperSide]. Can be undone;
  /// pass `recordUndo: false` for the later steps of one drag, so the
  /// whole drag undoes in one step.
  void setPaperSize(Size? size, {bool recordUndo = true}) {
    double side(double v) =>
        v.clamp(minPaperSide, maxPaperSide).roundToDouble();
    final next = size == null ? null : Size(side(size.width), side(size.height));
    if (next == paperSize) return;
    if (recordUndo) _record();
    paperSizeListenable.value = next;
    _changed();
  }

  void setPaper(Color color) {
    if (color.toARGB32() == paper.toARGB32()) return;
    _record();
    paper = color;
    _changed();
  }

  /// Replaces the drawing with [loaded] strokes and forgets undo history.
  void load(List<Stroke> loaded,
      {Color paper = Colors.white, Size? paperSize}) {
    strokes
      ..clear()
      ..addAll(loaded);
    _undo.clear();
    _redo.clear();
    current = null;
    this.paper = paper;
    paperSizeListenable.value = paperSize;
    revision++;
    finishedRevision.value++;
    notifyListeners();
  }

  void _record() {
    _undo.add(_Snapshot(strokes, paper, paperSize));
    if (_undo.length > maxUndo) _undo.removeAt(0);
    _redo.clear();
  }

  void _restore(_Snapshot s) {
    strokes
      ..clear()
      ..addAll(s.strokes);
    paper = s.paper;
    paperSizeListenable.value = s.paperSize;
    _changed();
  }

  void _changed() {
    revision++;
    finishedRevision.value++;
    notifyListeners();
  }

  /// Paints the finished strokes, and the eraser while it's being used
  /// (it cuts into them).
  void paintFinished(Canvas canvas, Size size) => paintStrokes(
      canvas, size, [...strokes, if (_erasing) ?current],
      paper: paper);

  /// Paints the stroke being drawn, unless it's the eraser. A blender
  /// stroke shows the finished drawing under it, blurred; [finished], a
  /// picture of the finished strokes, saves painting them again.
  void paintCurrent(Canvas canvas, Size size, {ui.Image? finished}) {
    final c = current;
    if (c == null || _erasing) return;
    if (c.brush == BrushType.smudge) {
      paintSmudgeOver(canvas, size, strokes, c,
          paper: paper, finished: finished);
    } else {
      c.paint(canvas);
    }
  }

  @override
  void dispose() {
    finishedRevision.dispose();
    paperSizeListenable.dispose();
    super.dispose();
  }
}
