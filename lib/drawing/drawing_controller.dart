
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'render/paint_strokes.dart';
import 'stroke.dart';

/// What the drawing looked like before an edit, for undo and redo.
class _Snapshot {
  _Snapshot(List<Stroke> strokes, this.paper, this.paperSize, this.layers,
      this.activeLayer)
      : strokes = List.of(strokes);

  final List<Stroke> strokes;
  final Color paper;
  final Size? paperSize;
  final List<PaintingLayer> layers;
  final String activeLayer;
}

/// Holds the strokes, layers and paper color of the open painting, plus
/// its undo/redo history.
///
/// Every edit (a stroke, clearing, moving or editing text, changing paper,
/// changing layers) records a snapshot first, so all of them can be undone.
/// Strokes are never changed in place, so a snapshot only needs to copy the
/// list.
///
/// [strokes] are kept in painting order: grouped by layer, bottom layer
/// first, and in the order they were added within a layer. So the list
/// alone, as older versions read it, still stacks them correctly.
class DrawingController extends ChangeNotifier {
  final List<Stroke> strokes = [];
  final List<_Snapshot> _undo = [];
  final List<_Snapshot> _redo = [];
  Stroke? current;
  Color paper = Colors.white;

  /// The painting's layers, bottom first; always at least one.
  List<PaintingLayer> get layers => List.unmodifiable(_layers);
  List<PaintingLayer> _layers = const [PaintingLayer.base];

  /// The layer new strokes go on, and the only one strokes can be picked
  /// from.
  String get activeLayer => _active;
  String _active = PaintingLayer.baseId;

  /// The paper's own size, or null for paper that fills the screen (and
  /// grows to fit what's drawn), as new paintings have. Strokes never
  /// change with it: a smaller paper only hides what's past its edges.
  Size? get paperSize => paperSizeListenable.value;
  final paperSizeListenable = ValueNotifier<Size?>(null);
  static const minPaperSide = 100.0;
  static const maxPaperSide = 8000.0;

  /// Older steps are forgotten past this many, to bound memory.
  static const maxUndo = 100;

  /// Bumped when what's finished (strokes, layers, paper) changes, and on
  /// every move of the eraser, which cuts into it; not while another stroke
  /// is being drawn. The finished drawing has its own layer, so a big
  /// painting isn't painted again for every point of a new stroke.
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

  // --- Layers -------------------------------------------------------------

  PaintingLayer layer(String id) =>
      _layers.firstWhere((l) => l.id == id, orElse: () => _layers.last);

  PaintingLayer get active => layer(_active);

  /// What a new stroke's `layer` is: null for the base layer.
  String? get newStrokeLayer =>
      _active == PaintingLayer.baseId ? null : _active;

  /// Whether the active layer can be drawn on: shown and not locked.
  bool get canDrawOnActive => active.visible && !active.locked;

  /// The strokes on layer [id], in painting order.
  List<Stroke> strokesOn(String id) => [
        for (final s in strokes)
          if (s.layerId == id) s,
      ];

  /// Makes [id] the layer new strokes go on. Not an edit: not undone.
  void selectLayer(String id) {
    if (_active == id || !_layers.any((l) => l.id == id)) return;
    _active = id;
    notifyListeners();
  }

  /// Adds an empty layer above the active one and makes it active.
  /// Returns false when there are already [PaintingLayer.maxLayers].
  bool addLayer() {
    if (_layers.length >= PaintingLayer.maxLayers) return false;
    _record();
    var n = _layers.length;
    String id;
    do {
      id = 'L${++n}';
    } while (_layers.any((l) => l.id == id));
    final at = _layers.indexWhere((l) => l.id == _active) + 1;
    _layers = [..._layers]..insert(at, PaintingLayer(id: id));
    _active = id;
    _changed();
    return true;
  }

  /// Deletes layer [id] with everything on it. The last layer stays.
  void deleteLayer(String id) {
    if (_layers.length <= 1) return;
    final at = _layers.indexWhere((l) => l.id == id);
    if (at < 0) return;
    _record();
    strokes.removeWhere((s) => s.layerId == id);
    _layers = [..._layers]..removeAt(at);
    if (_active == id) _active = _layers[at == 0 ? 0 : at - 1].id;
    _changed();
  }

  /// Moves layer [id] to [index] (0 is the bottom).
  void moveLayer(String id, int index) {
    final from = _layers.indexWhere((l) => l.id == id);
    final to = index.clamp(0, _layers.length - 1);
    if (from < 0 || from == to) return;
    _record();
    final moved = [..._layers];
    moved.insert(to, moved.removeAt(from));
    _layers = moved;
    _sortStrokes();
    _changed();
  }

  /// Replaces a layer's name, visibility, opacity or lock with [changed]'s.
  /// Pass `recordUndo: false` for the later steps of one slider drag.
  void updateLayer(PaintingLayer changed, {bool recordUndo = true}) {
    final at = _layers.indexWhere((l) => l.id == changed.id);
    if (at < 0 || _layers[at] == changed) return;
    if (recordUndo) _record();
    _layers = [..._layers]..[at] = changed;
    _changed();
  }

  /// Puts layer [id]'s strokes onto the layer below it, which becomes
  /// active. The merged layer's own opacity is dropped.
  void mergeDown(String id) {
    final at = _layers.indexWhere((l) => l.id == id);
    if (at <= 0) return;
    _record();
    final below = _layers[at - 1].id;
    for (var i = 0; i < strokes.length; i++) {
      if (strokes[i].layerId == id) strokes[i] = strokes[i].onLayer(below);
    }
    _layers = [..._layers]..removeAt(at);
    _active = below;
    _sortStrokes();
    _changed();
  }

  /// Stable-sorts [strokes] into layer order.
  void _sortStrokes() {
    final order = {for (final (i, l) in _layers.indexed) l.id: i};
    final indexed = [...strokes.indexed]..sort((a, b) {
        final byLayer = order[a.$2.layerId]!.compareTo(order[b.$2.layerId]!);
        return byLayer != 0 ? byLayer : a.$1.compareTo(b.$1);
      });
    strokes
      ..clear()
      ..addAll([for (final (_, s) in indexed) s]);
  }

  /// Where a new stroke on [layerId] goes: after the last stroke of its
  /// layer or of any layer below it.
  int _insertAt(String layerId) {
    final mine = _layers.indexWhere((l) => l.id == layerId);
    for (var i = strokes.length - 1; i >= 0; i--) {
      final theirs = _layers.indexWhere((l) => l.id == strokes[i].layerId);
      if (theirs <= mine) return i + 1;
    }
    return 0;
  }

  void _insert(Stroke s) => strokes.insert(_insertAt(s.layerId), s);

  // --- Drawing ------------------------------------------------------------

  /// Starts [stroke]. Freehand strokes pass their first [point]; shape
  /// strokes already have their outline. Tools give new strokes the
  /// [newStrokeLayer].
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
    _insert(current!..isComplete = true);
    current = null;
    _changed();
  }

  /// Adds a finished stroke, such as a new text item, on its layer.
  void add(Stroke stroke) {
    _record();
    _insert(stroke);
    _changed();
  }

  /// Adds [stroke] under everything else on its layer (a photo to trace),
  /// on [newLayer] put at the very bottom if given, as one edit.
  void addUnder(Stroke stroke, {PaintingLayer? newLayer}) {
    _record();
    if (newLayer != null) _layers = [newLayer, ..._layers];
    final first = strokes.indexWhere((s) => s.layerId == stroke.layerId);
    strokes.insert(first >= 0 ? first : _insertAt(stroke.layerId), stroke);
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

  /// Adds finished strokes on top of their layers, as one edit (for
  /// example copies).
  void addAll(List<Stroke> added) {
    if (added.isEmpty) return;
    _record();
    added.forEach(_insert);
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

  /// Whether [s] can be picked up: on the active layer, which is shown and
  /// not locked.
  bool pickable(Stroke s) => s.layerId == _active && canDrawOnActive;

  /// The topmost stroke on the active layer under [point], if any.
  Stroke? hitStroke(Offset point) {
    for (final s in strokes.reversed) {
      // Eraser and blender strokes have no paint of their own to pick up.
      if (!s.brush.isEffect && pickable(s) && s.hits(point)) return s;
    }
    return null;
  }

  /// Every stroke on the active layer a selection box over [box] catches,
  /// in drawing order.
  List<Stroke> strokesIn(Rect box) => [
        for (final s in strokes)
          if (!s.brush.isEffect && pickable(s) && s.touches(box)) s,
      ];

  /// The topmost text item on the active layer under [point], if any.
  Stroke? hitText(Offset point) {
    for (final s in strokes.reversed) {
      if (s.text != null && pickable(s) && s.hits(point)) return s;
    }
    return null;
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(_snapshot());
    _restore(_undo.removeLast());
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(_snapshot());
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

  /// Replaces the drawing with [loaded] strokes on [layers] (just the base
  /// layer if none) and forgets undo history. Strokes on a layer that
  /// isn't there go on the base layer.
  void load(List<Stroke> loaded,
      {Color paper = Colors.white,
      Size? paperSize,
      List<PaintingLayer> layers = const [PaintingLayer.base]}) {
    _layers = layers.isEmpty ? const [PaintingLayer.base] : [...layers];
    if (!_layers.any((l) => l.isBase)) _layers.insert(0, PaintingLayer.base);
    final ids = {for (final l in _layers) l.id};
    strokes
      ..clear()
      ..addAll([
        for (final s in loaded)
          ids.contains(s.layerId) ? s : s.onLayer(PaintingLayer.baseId),
      ]);
    _sortStrokes();
    // Draw on the top layer that isn't locked (a coloring page's lines are).
    _active = _layers.lastWhere((l) => !l.locked, orElse: () => _layers.last).id;
    _undo.clear();
    _redo.clear();
    current = null;
    this.paper = paper;
    paperSizeListenable.value = paperSize;
    revision++;
    finishedRevision.value++;
    notifyListeners();
  }

  _Snapshot _snapshot() =>
      _Snapshot(strokes, paper, paperSize, _layers, _active);

  void _record() {
    _undo.add(_snapshot());
    if (_undo.length > maxUndo) _undo.removeAt(0);
    _redo.clear();
  }

  void _restore(_Snapshot s) {
    strokes
      ..clear()
      ..addAll(s.strokes);
    paper = s.paper;
    paperSizeListenable.value = s.paperSize;
    _layers = s.layers;
    _active = s.activeLayer;
    _changed();
  }

  void _changed() {
    revision++;
    finishedRevision.value++;
    notifyListeners();
  }

  /// Paints the finished strokes, and the eraser while it's being used
  /// (it cuts into its layer).
  void paintFinished(Canvas canvas, Size size) => paintStrokes(
      canvas, size, [...strokes, if (_erasing) ?current],
      paper: paper, layers: _layers);

  /// Paints the stroke being drawn, unless it's the eraser. A blender
  /// stroke shows its layer under it, blurred; [finished], a picture of
  /// that layer's finished strokes, saves painting them again.
  void paintCurrent(Canvas canvas, Size size, {ui.Image? finished}) {
    final c = current;
    if (c == null || _erasing) return;
    if (c.brush == BrushType.smudge) {
      paintSmudgeOver(canvas, size, strokesOn(c.layerId), c,
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
