import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas/canvas_view.dart';
import 'package:jingyao_paint/drawing/canvas/selection_controller.dart';
import 'package:jingyao_paint/drawing/canvas/shortcuts.dart';
import 'package:jingyao_paint/drawing/canvas/tools/draw_tool.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/drawing_controller.dart';
import 'package:jingyao_paint/drawing/stroke.dart';

import 'selection_test.dart' show hLine;
import 'test_helpers.dart';
import 'widget_test.dart' show drawStroke, pumpApp;

/// A copy or paste sits 24 points down and to the right.
void expectShift(Offset d) {
  expect(d.dx, closeTo(24, 1e-6));
  expect(d.dy, closeTo(24, 1e-6));
}

/// The drawing screen's logic, tested without the screen: the selection,
/// the view, the keyboard map and new strokes.
void main() {
  group('Selection controller', () {
    late DrawingController drawing;
    late SelectionController selection;

    setUp(() async {
      final app = await createTestApp();
      drawing = DrawingController()..add(hLine(20, 120, 50));
      selection =
          SelectionController(drawing: drawing, settings: app.settings);
    });

    test('picking a stroke up and dragging moves it; one undo puts it back',
        () {
      final y = drawing.strokes.single.bounds.center.dy;
      selection.startMove(const Offset(60, 50));
      expect(selection.selected.value, hasLength(1));
      expect(selection.moving.value, isTrue);
      selection
        ..continueMove(const Offset(60, 70))
        ..continueMove(const Offset(60, 90))
        ..endMove(cancelled: false);
      expect(selection.moving.value, isFalse);
      expect(drawing.strokes.single.bounds.center.dy, closeTo(y + 40, 0.01));
      drawing.undo();
      expect(drawing.strokes.single.bounds.center.dy, closeTo(y, 0.01));
    });

    test('a box dragged over empty paper selects what it touches', () {
      drawing.add(hLine(20, 120, 200));
      selection
        ..startMove(const Offset(5, 30))
        ..continueMove(const Offset(130, 70))
        ..endMove(cancelled: false);
      expect(selection.selected.value, [drawing.strokes.first]);
      expect(selection.box.value, isNull);
    });

    test('copy, cut and paste: each paste lands further down and right', () {
      final line = drawing.strokes.single;
      selection
        ..select([line])
        ..copy()
        ..paste();
      expect(drawing.strokes, hasLength(2));
      expect(selection.settings.brush, BrushType.move);
      final pasted = selection.selected.value.single;
      expectShift(pasted.bounds.topLeft - line.bounds.topLeft);
      selection.cut();
      expect(drawing.strokes, [line]);
      selection.paste();
      expectShift(drawing.strokes.last.bounds.topLeft - pasted.bounds.topLeft);
    });

    test('the move tool selects the last stroke; undo drops removed ones',
        () {
      drawing.add(hLine(20, 120, 200));
      selection.settings.brush = BrushType.move;
      selection.syncWithBrush();
      expect(selection.selected.value, [drawing.strokes.last]);
      drawing.undo();
      selection.keepDrawnOnly();
      expect(selection.selected.value, isEmpty);
    });
  });

  group('View controller', () {
    late CanvasViewController view;

    setUp(() => view = CanvasViewController(vsync: const TestVSync())
      ..animate = false
      ..room = const Size(400, 600));
    tearDown(() => view.dispose());

    test('zoom stays between 50% and 800%', () {
      view.zoomAt(Offset.zero, 100);
      expect(view.zoom, closeTo(CanvasViewController.maxZoom, 1e-9));
      view.zoomAt(Offset.zero, 0.0001);
      expect(view.zoom, closeTo(CanvasViewController.minZoom, 1e-9));
      view.reset();
      expect(view.zoom, 1);
    });

    test('two fingers spreading apart zoom in, after dropping the first '
        "finger's stroke", () {
      var pinched = 0;
      view.onPinchStart = () => pinched++;
      view
        ..fingerDown(1, const Offset(100, 100), Offset.zero, onPaper: true)
        ..fingerDown(2, const Offset(200, 100), Offset.zero, onPaper: false);
      expect(view.pinching, isTrue);
      expect(pinched, 1);
      view.fingerMove(2, const Offset(300, 100), Offset.zero);
      expect(view.zoom, closeTo(2, 1e-9));
      view
        ..fingerUp(1)
        ..fingerUp(2);
      expect(view.pinching, isFalse);
    });

    test('a drag that starts outside the paper moves it', () {
      view
        ..fingerDown(1, const Offset(10, 10), const Offset(10, 10),
            onPaper: false)
        ..fingerMove(1, const Offset(40, 30), const Offset(40, 30));
      expect(view.view.value.getTranslation().x, 30);
      expect(view.view.value.getTranslation().y, 20);
    });

    test('a paper is shrunk to fit and centered, but never enlarged', () {
      final big =
          CanvasViewController.fitPaper(const Size(400, 400), const Size(800, 400));
      expect(big.scale, 0.5);
      expect(big.corner, const Offset(0, 100));
      final small =
          CanvasViewController.fitPaper(const Size(400, 400), const Size(200, 100));
      expect(small.scale, 1);
      expect(small.corner, const Offset(100, 150));
    });
  });

  group('Keyboard shortcut map', () {
    KeyEvent key(LogicalKeyboardKey k, {String? character, bool repeat = false}) =>
        repeat
            ? KeyRepeatEvent(
                physicalKey: PhysicalKeyboardKey.keyA,
                logicalKey: k,
                character: character,
                timeStamp: Duration.zero)
            : KeyDownEvent(
                physicalKey: PhysicalKeyboardKey.keyA,
                logicalKey: k,
                character: character,
                timeStamp: Duration.zero);

    test('plain keys pick tools and change the size; held keys repeat only '
        'the size', () {
      CanvasCommand? map(KeyEvent e, {bool sel = false}) =>
          commandFor(e, hasSelection: sel);
      expect(map(key(LogicalKeyboardKey.keyP, character: 'p')),
          CanvasCommand.pen);
      expect(map(key(LogicalKeyboardKey.keyE, character: 'E')),
          CanvasCommand.eraser);
      expect(map(key(LogicalKeyboardKey.keyP, character: 'p', repeat: true)),
          isNull);
      expect(map(key(LogicalKeyboardKey.bracketLeft, repeat: true)),
          CanvasCommand.smallerBrush);
      expect(map(key(LogicalKeyboardKey.delete)), isNull);
      expect(map(key(LogicalKeyboardKey.delete), sel: true),
          CanvasCommand.deleteSelection);
      expect(map(key(LogicalKeyboardKey.escape)), CanvasCommand.escape);
    });

    testWidgets('Ctrl combinations: undo, redo, copy only with a selection',
        (tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(commandFor(key(LogicalKeyboardKey.keyZ), hasSelection: false),
          CanvasCommand.undo);
      expect(commandFor(key(LogicalKeyboardKey.keyC), hasSelection: false),
          isNull);
      expect(commandFor(key(LogicalKeyboardKey.keyC), hasSelection: true),
          CanvasCommand.copy);
      expect(
          commandFor(key(LogicalKeyboardKey.keyS, repeat: true),
              hasSelection: false),
          isNull);
      expect(
          commandFor(key(LogicalKeyboardKey.equal, repeat: true),
              hasSelection: false),
          CanvasCommand.zoomIn);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(commandFor(key(LogicalKeyboardKey.keyZ), hasSelection: false),
          CanvasCommand.redo);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    });
  });

  group('New strokes from the tools drawer', () {
    test('the eraser never draws shapes; spray dots never get gradients',
        () async {
      final settings = (await createTestApp()).settings
        ..shape = ShapeKind.rectangle
        ..gradient = GradientStyle.lighter
        ..brush = BrushType.eraser;
      expect(newStroke(settings, const Offset(10, 10)).shape, isNull);
      settings.brush = BrushType.spray;
      expect(newStroke(settings, const Offset(10, 10)).gradient, isNull);
      settings.brush = BrushType.pen;
      final pen = newStroke(settings, const Offset(10, 10), mirrorX: 50);
      expect(pen.shape, ShapeKind.rectangle);
      expect(pen.gradient, isNotNull);
      expect(pen.mirrorX, 50);
    });
  });

  testWidgets('after a pinch during ✋, the next stroke draws instead of '
      'moving the paper', (tester) async {
    final app = await pumpApp(tester);
    final state = tester.state<CanvasPageState>(find.byType(CanvasPage));
    state.panMode.value = true;
    await tester.pump();
    final a = await tester.startGesture(const Offset(150, 300), pointer: 1);
    final b = await tester.startGesture(const Offset(250, 300), pointer: 2);
    await a.moveBy(const Offset(-20, 0));
    await b.moveBy(const Offset(20, 0));
    await a.up();
    await b.up();
    state.panMode.value = false;
    await tester.pumpAndSettle();

    final view = state.view.value.clone();
    await drawStroke(tester);
    expect(app.session.drawing.strokes, hasLength(1));
    expect(app.session.drawing.current, isNull);
    expect(state.view.value, view);
    // Let the autosave run.
    await tester.pump(const Duration(seconds: 1));
  });
}
