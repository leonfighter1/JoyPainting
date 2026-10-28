import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Where the paper sits in the paper area before zooming: its top-left
/// corner and how much it's scaled down to fit.
typedef PaperLayout = ({Offset corner, double scale});

/// The view's zoom factor. Not `getMaxScaleOnAxis`: that also counts the
/// untouched z axis (always 1), so it never reports less than 100%.
double zoomOf(Matrix4 m) =>
    math.sqrt(m.entry(0, 0) * m.entry(0, 0) + m.entry(1, 0) * m.entry(1, 0));

/// How far the view is turned, in radians (clockwise on screen).
double rotationOf(Matrix4 m) => math.atan2(m.entry(1, 0), m.entry(0, 0));

/// How the paper is zoomed and panned on screen. Only the view changes;
/// the painting itself is untouched.
///
/// Tracks every finger on the paper area (two make a pinch), drags that
/// move the paper, zooming with the wheel, keys and menu, and the animated
/// way back to the whole paper.
class CanvasViewController {
  CanvasViewController({required TickerProvider vsync})
      : _reset = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 260),
        );

  static const minZoom = 0.5;
  static const maxZoom = 8.0;

  final view = ValueNotifier<Matrix4>(Matrix4.identity());
  final AnimationController _reset;

  /// Whether changes animate (off with the system "remove animations").
  bool animate = true;

  /// The paper area, as last laid out.
  Size room = Size.zero;

  /// Where the paper was laid out last, before zooming.
  PaperLayout layout = (corner: Offset.zero, scale: 1);

  /// Whether two fingers also turn the paper (not for beginners).
  bool rotates = true;

  /// A turn this close to a quarter turn (0°, 90°, 180°, 270°) snaps to it.
  static const snapAngle = 7 * math.pi / 180;

  /// Called when a second finger lands: a pinch isn't drawing, so whatever
  /// the first finger started is dropped.
  VoidCallback? onPinchStart;

  double get zoom => zoomOf(view.value);

  // --- Fingers -------------------------------------------------------------

  /// Fingers on the paper area, in paper-area coordinates, for pinching.
  final Map<int, Offset> _touches = {};

  /// True from the moment a second finger lands until every finger lifts:
  /// the touch is a pinch/pan, not drawing.
  bool get pinching => _pinching;
  bool _pinching = false;
  ({Offset focal, double distance, double angle, Matrix4 start})? _pinchStart;

  /// A drag that started outside the paper, moving it.
  ({int pointer, Offset start, Matrix4 view})? _outsideDrag;

  /// A finger landed on the paper area. [onPaper] is true when the paper
  /// itself took it (it sees touches first); one it didn't take landed
  /// outside the paper (zoomed out, moved, or a sheet of another shape),
  /// and dragging there moves the paper.
  void fingerDown(int pointer, Offset local, Offset global,
      {required bool onPaper}) {
    _touches[pointer] = local;
    if (_touches.length == 2) {
      _outsideDrag = null;
      _startPinch();
      return;
    }
    if (_touches.length == 1 && !onPaper && !_pinching) {
      _outsideDrag = (pointer: pointer, start: global, view: view.value.clone());
    }
  }

  void fingerMove(int pointer, Offset local, Offset global) {
    if (!_touches.containsKey(pointer)) return;
    _touches[pointer] = local;
    if (_pinchStart != null) {
      _updatePinch();
      return;
    }
    if (_outsideDrag case final g? when g.pointer == pointer) {
      dragTo((start: g.start, view: g.view), global);
    }
  }

  void fingerUp(int pointer) {
    _touches.remove(pointer);
    if (_outsideDrag?.pointer == pointer) _outsideDrag = null;
    if (_touches.length < 2) _pinchStart = null;
    if (_touches.isEmpty) _pinching = false;
  }

  void _startPinch() {
    _pinching = true;
    onPinchStart?.call();
    final pts = _touches.values.toList();
    _pinchStart = (
      focal: (pts[0] + pts[1]) / 2,
      distance: math.max(1, (pts[0] - pts[1]).distance),
      angle: (pts[1] - pts[0]).direction,
      start: view.value.clone(),
    );
  }

  void _updatePinch() {
    final start = _pinchStart!;
    final pts = _touches.values.take(2).toList();
    final focal = (pts[0] + pts[1]) / 2;
    final base = zoomOf(start.start);
    final next = (base * (pts[0] - pts[1]).distance / start.distance)
        .clamp(minZoom, maxZoom);
    // The fingers' turn, snapped to a quarter turn when close to one.
    var turn = 0.0;
    if (rotates) {
      turn = _wrap((pts[1] - pts[0]).direction - start.angle);
      final total = rotationOf(start.start) + turn;
      final quarter = (total / (math.pi / 2)).round() * (math.pi / 2);
      if ((total - quarter).abs() < snapAngle) turn += quarter - total;
    }
    // Scale and turn around where the fingers started, then follow their
    // midpoint so moving both fingers together pans.
    final pan = focal - start.focal;
    view.value = Matrix4.translationValues(pan.dx, pan.dy, 0).multiplied(
        _turnedAround(start.start, start.focal, next / base, turn));
  }

  /// Moving the paper with one finger or the mouse: where the drag started
  /// (in screen positions, so the paper moves under the finger) and the
  /// view then.
  ({Offset start, Matrix4 view}) grab(Offset global) =>
      (start: global, view: view.value.clone());

  void dragTo(({Offset start, Matrix4 view}) grab, Offset global) {
    final d = global - grab.start;
    view.value = Matrix4.translationValues(d.dx, d.dy, 0).multiplied(grab.view);
  }

  // --- Zoom ----------------------------------------------------------------

  static Matrix4 _scaledAround(Matrix4 m, Offset focal, double k) =>
      Matrix4.translationValues(focal.dx, focal.dy, 0)
          .multiplied(Matrix4.diagonal3Values(k, k, 1))
          .multiplied(Matrix4.translationValues(-focal.dx, -focal.dy, 0))
          .multiplied(m);

  static Matrix4 _turnedAround(
          Matrix4 m, Offset focal, double k, double angle) =>
      Matrix4.translationValues(focal.dx, focal.dy, 0)
          .multiplied(Matrix4.rotationZ(angle))
          .multiplied(Matrix4.diagonal3Values(k, k, 1))
          .multiplied(Matrix4.translationValues(-focal.dx, -focal.dy, 0))
          .multiplied(m);

  /// [a] within -π to π.
  static double _wrap(double a) =>
      math.atan2(math.sin(a), math.cos(a));

  /// Turns the paper by [angle] around the middle of the paper area (the R
  /// key).
  void rotateCenter(double angle) => view.value = _turnedAround(
      view.value, Offset(room.width / 2, room.height / 2), 1, angle);

  /// Zooms by [factor] around [focal] (mouse wheel, menu buttons).
  void zoomAt(Offset focal, double factor) {
    final current = zoom;
    final next = (current * factor).clamp(minZoom, maxZoom);
    view.value = _scaledAround(view.value, focal, next / current);
  }

  /// Zooms around the middle of the paper area (Ctrl + and Ctrl −).
  void zoomCenter(double factor) =>
      zoomAt(Offset(room.width / 2, room.height / 2), factor);

  /// Back to the whole paper on screen.
  void reset() => _animateTo(Matrix4.identity());

  /// Back to the whole paper at once, without animating (another painting
  /// opened).
  void jumpToStart() => view.value = Matrix4.identity();

  /// Zooms so the paper shows at its real size (one paper point per screen
  /// point), from its top-left corner.
  void showActualSize() {
    if (room.isEmpty) return;
    final next = (1 / layout.scale).clamp(minZoom, maxZoom);
    _animateTo(_scaledAround(Matrix4.identity(), layout.corner, next));
  }

  /// Where a paper of [size] sits in [room] before zooming: shrunk to fit
  /// if it's bigger, never enlarged, and centered.
  static PaperLayout fitPaper(Size room, Size size) {
    final scale = math.min(
      1.0,
      math.min(room.width / size.width, room.height / size.height),
    );
    return (
      corner: Offset(
        (room.width - size.width * scale) / 2,
        (room.height - size.height * scale) / 2,
      ),
      scale: scale,
    );
  }

  static Matrix4 _placing(PaperLayout l) =>
      Matrix4.translationValues(l.corner.dx, l.corner.dy, 0)
          .multiplied(Matrix4.diagonal3Values(l.scale, l.scale, 1));

  /// After the paper was resized while held at [held], fits [size] on
  /// screen again without the paper jumping: the zoom takes over what the
  /// new layout changes.
  void keepPlace(PaperLayout held, Size size) {
    view.value = view.value
        .multiplied(_placing(held))
        .multiplied(Matrix4.inverted(_placing(fitPaper(room, size))));
  }

  void _animateTo(Matrix4 end) {
    if (!animate) {
      view.value = end;
      return;
    }
    final tween = Matrix4Tween(begin: view.value.clone(), end: end);
    final curve = CurvedAnimation(parent: _reset, curve: Curves.easeOutCubic);
    void step() => view.value = tween.evaluate(curve);
    _reset
      ..reset()
      ..addListener(step)
      ..forward().whenComplete(() => _reset.removeListener(step));
  }

  void dispose() {
    _reset.dispose();
    view.dispose();
  }
}
