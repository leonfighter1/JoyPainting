import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas/canvas_view.dart';
import 'package:jingyao_paint/drawing/canvas/paper_view.dart';
import 'package:jingyao_paint/drawing/canvas/shortcuts.dart';

import 'widget_test.dart' show pumpApp;

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

/// Whether [m] keeps the paper upright: no turn, the same scale both ways.
bool upright(Matrix4 m) =>
    m.entry(1, 0).abs() < 1e-9 &&
    m.entry(0, 1).abs() < 1e-9 &&
    (m.entry(0, 0) - m.entry(1, 1)).abs() < 1e-9;

void main() {
  // The paper used to turn with two fingers and R (5.2.0 to 6.5.0); a
  // turned paper made every frame two to three times as costly, so 6.6.0
  // took turning out.
  group('The paper stays upright', () {
    late CanvasViewController view;
    setUp(() => view = CanvasViewController(vsync: const TestVSync())
      ..animate = false
      ..room = const Size(400, 600));
    tearDown(() => view.dispose());

    test('two fingers that turn only zoom and move it', () {
      // The second finger goes 30° round the first, twice as far away.
      final turned = Offset.fromDirection(math.pi / 6, 200);
      pinch(view, const Offset(100, 100), const Offset(200, 100),
          const Offset(100, 100), const Offset(100, 100) + turned);
      expect(upright(view.view.value), isTrue);
      expect(view.zoom, closeTo(2, 1e-9));
    });

    test('moving both fingers together moves it', () {
      pinch(view, const Offset(100, 100), const Offset(200, 100),
          const Offset(130, 140), const Offset(230, 140));
      expect(upright(view.view.value), isTrue);
      expect(view.zoom, closeTo(1, 1e-9));
      expect(view.view.value.getTranslation().x, closeTo(30, 1e-9));
      expect(view.view.value.getTranslation().y, closeTo(40, 1e-9));
    });

    test('R is not a shortcut any more', () {
      expect(
          commandFor(
              const KeyDownEvent(
                  physicalKey: PhysicalKeyboardKey.keyR,
                  logicalKey: LogicalKeyboardKey.keyR,
                  character: 'r',
                  timeStamp: Duration.zero),
              hasSelection: false),
          isNull);
    });
  });

  testWidgets('R leaves the paper upright, its grips in place',
      (tester) async {
    await pumpApp(tester);
    expect(find.byType(PaperGrip), findsNWidgets(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pumpAndSettle();
    expect(find.textContaining('°'), findsNothing);
    expect(find.byType(PaperGrip), findsNWidgets(2));
  });
}
