import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas/canvas_view.dart';
import 'package:jingyao_paint/drawing/canvas/paper_view.dart';
import 'package:jingyao_paint/drawing/canvas/shortcuts.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/skill_level.dart';

import 'widget_test.dart' show drawStroke, pumpApp;

double degrees(double radians) => radians * 180 / math.pi;

/// Two fingers on the paper area: down at [a0] and [b0], then moved to
/// [a1] and [b1].
void pinch(CanvasViewController view, Offset a0, Offset b0, Offset a1,
    Offset b1) {
  view
    ..fingerDown(1, a0, Offset.zero, onPaper: true)
    ..fingerDown(2, b0, Offset.zero, onPaper: false)
    ..fingerMove(1, a1, Offset.zero)
    ..fingerMove(2, b1, Offset.zero)
    ..fingerUp(1)
    ..fingerUp(2);
}

void main() {
  group('Turning the paper', () {
    late CanvasViewController view;
    setUp(() => view = CanvasViewController(vsync: const TestVSync())
      ..animate = false
      ..room = const Size(400, 600));
    tearDown(() => view.dispose());

    test('two fingers turn it as they turn, keeping the zoom', () {
      // The second finger goes 30° round the first, at the same distance.
      final turned = Offset.fromDirection(math.pi / 6, 100);
      pinch(view, const Offset(100, 100), const Offset(200, 100),
          const Offset(100, 100), const Offset(100, 100) + turned);
      expect(degrees(rotationOf(view.view.value)), closeTo(30, 0.01));
      expect(view.zoom, closeTo(1, 1e-9));
    });

    test('close to a quarter turn it snaps to it', () {
      final turned = Offset.fromDirection(85 * math.pi / 180, 100);
      pinch(view, const Offset(100, 100), const Offset(200, 100),
          const Offset(100, 100), const Offset(100, 100) + turned);
      expect(degrees(rotationOf(view.view.value)), closeTo(90, 1e-6));
    });

    test('beginners only pinch to zoom', () {
      view.rotates = false;
      final turned = Offset.fromDirection(math.pi / 6, 200);
      pinch(view, const Offset(100, 100), const Offset(200, 100),
          const Offset(100, 100), const Offset(100, 100) + turned);
      expect(rotationOf(view.view.value), 0);
      expect(view.zoom, closeTo(2, 1e-9));
      expect(SkillLevel.beginner.rotation, isFalse);
      expect(SkillLevel.intermediate.rotation, isTrue);
    });

    test('R turns it 15°, Shift+R back; fit to screen straightens it', () {
      expect(
          commandFor(
              const KeyDownEvent(
                  physicalKey: PhysicalKeyboardKey.keyR,
                  logicalKey: LogicalKeyboardKey.keyR,
                  character: 'r',
                  timeStamp: Duration.zero),
              hasSelection: false),
          CanvasCommand.turnRight);
      view.rotateCenter(math.pi / 12);
      expect(degrees(rotationOf(view.view.value)), closeTo(15, 1e-9));
      view.reset();
      expect(rotationOf(view.view.value), 0);
    });
  });

  testWidgets('a turned paper: the chip shows the angle, the grips hide, and '
      'a stroke still lands under the finger', (tester) async {
    final app = await pumpApp(tester);
    expect(find.byType(PaperGrip), findsNWidgets(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pumpAndSettle();
    expect(find.textContaining('30°'), findsOneWidget);
    expect(find.byType(PaperGrip), findsNothing);

    const start = Offset(150, 300);
    final paper =
        tester.renderObject<RenderBox>(find.byKey(CanvasPageState.paperKey));
    final expected = paper.globalToLocal(start);
    await tester.dragFrom(start, const Offset(40, 0));
    await tester.pump();
    final first = app.session.drawing.strokes.single.points.first;
    expect(first.x, closeTo(expected.dx, 1));
    expect(first.y, closeTo(expected.dy, 1));
    await drawStroke(tester);
    await tester.pump(const Duration(seconds: 1));
  });
}
