import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas/shortcuts.dart';
import 'package:jingyao_paint/drawing/canvas/tools/canvas_tool.dart';
import 'package:jingyao_paint/drawing/canvas/tools/picker_tool.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/render/layer_cache.dart';
import 'package:jingyao_paint/drawing/render/pixel_sampler.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/settings.dart';
import 'package:jingyao_paint/skill_level.dart';

import 'test_helpers.dart';
import 'v3_test.dart' show box;
import 'v4_test.dart' show line;
import 'widget_test.dart' show pumpApp;

const _size = Size(60, 40);
const _cream = Color(0xFFFFF6E5);

/// The paper's color at [at] with [strokes] on it.
Future<Color> colorAt(List<Stroke> strokes, Offset at,
    {Color paper = Colors.white, ui.Image? finished}) async {
  final s = await PaperSampler.sample(at,
      size: _size, paper: paper, strokes: strokes, finished: finished);
  s.patch.dispose();
  return s.color;
}

/// Close enough: within [tolerance] in every channel.
Matcher near(Color c, {int tolerance = 3}) => predicate<Color>(
    (x) =>
        ((x.r - c.r) * 255).abs() <= tolerance &&
        ((x.g - c.g) * 255).abs() <= tolerance &&
        ((x.b - c.b) * 255).abs() <= tolerance,
    'near $c');

/// A pointer event on the paper at [at], as the picker sees it.
ToolPointer pointerAt(Offset at, {bool up = false}) => ToolPointer(up
    ? PointerUpEvent(position: at)
    : PointerDownEvent(position: at));

void main() {
  group('Reading the paper', () {
    test('the color seen: paint, paper, shadows and see-through paint',
        () async {
      final red = box(const Rect.fromLTWH(0, 0, 30, 40), const Color(0xFFFF0000));
      expect(await colorAt([red], const Offset(10, 20)),
          near(const Color(0xFFFF0000)));
      expect(await colorAt([red], const Offset(45, 20), paper: _cream),
          near(_cream), reason: 'bare paper');
      final shadow = box(const Rect.fromLTWH(0, 0, 60, 40),
          const Color(0xFF808080), blend: StrokeBlend.multiply);
      expect(await colorAt([red, shadow], const Offset(10, 20)),
          near(const Color(0xFF800000)), reason: 'red in shadow');
      final marker = line(const Offset(40, 4), const Offset(40, 36),
          brush: BrushType.highlighter, color: const Color(0xFF0000FF));
      final mixed = await colorAt([marker], const Offset(40, 20));
      expect(mixed.b, 1.0);
      expect(mixed.r, inExclusiveRange(0.3, 0.95),
          reason: 'the paper shows through the highlighter');
    });

    test('reading the kept picture gives the same color as painting the '
        'strokes', () async {
      final strokes = [
        box(const Rect.fromLTWH(0, 0, 30, 40), const Color(0xFF2E7D32)),
        line(const Offset(4, 20), const Offset(56, 20),
            brush: BrushType.highlighter, color: const Color(0xFFFFC107)),
      ];
      final cache = StrokeLayerCache();
      final recorder = ui.PictureRecorder();
      cache.paint(Canvas(recorder), _size, strokes, Colors.white, 2);
      recorder.endRecording().dispose();
      final finished = cache.imageOf(strokes, _size);
      expect(finished, isNotNull);
      for (final at in const [Offset(10, 20), Offset(45, 20), Offset(10, 5)]) {
        expect(await colorAt(strokes, at, finished: finished),
            near(await colorAt(strokes, at)), reason: '$at');
      }
    });
  });

  group('Picker tool', () {
    late AppSettings settings;
    late ValueNotifier<PickerLoupe?> loupe;

    setUp(() async {
      settings = (await createTestApp()).settings;
      loupe = ValueNotifier(null);
    });

    PickerTool picker(Future<PaperSample> Function(Offset at) sample) =>
        PickerTool(
          settings: settings,
          sample: sample,
          loupe: loupe,
          place: (g) => g + const Offset(1, 1),
          returnTo: () => BrushType.marker,
        );

    Future<PaperSample> paper(Color c) async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(c, BlendMode.src);
      return PaperSample(c, await recorder.endRecording().toImage(9, 9));
    }

    test('letting go picks the color, keeps it, and goes back to the brush',
        () async {
      settings.brush = BrushType.picker;
      const green = Color(0xFF2E7D32);
      final tool = picker((_) => paper(green));
      tool.down(pointerAt(const Offset(20, 30)));
      expect(loupe.value?.at, const Offset(21, 31), reason: 'shown at once');
      await pumpEventQueue();
      expect(loupe.value?.color, green);
      await tool.up(pointerAt(const Offset(20, 30), up: true));
      expect(loupe.value, isNull);
      expect(settings.color, green);
      expect(settings.customColors, contains(green));
      expect(settings.brush, BrushType.marker);
    });

    test('a slow read never shows over a newer one', () async {
      final first = Completer<PaperSample>();
      final reads = [first.future, paper(Colors.blue)];
      final tool = picker((_) => reads.removeAt(0));
      tool
        ..down(pointerAt(Offset.zero))
        ..move(pointerAt(const Offset(5, 5)));
      await pumpEventQueue();
      expect(loupe.value?.color, Colors.blue);
      first.complete(await paper(Colors.red));
      await pumpEventQueue();
      expect(loupe.value?.color, Colors.blue);
      tool.cancel();
      expect(loupe.value, isNull);
    });
  });

  test('intermediate and advanced have the picker; I picks it', () {
    expect(SkillLevel.beginner.brushes, isNot(contains(BrushType.picker)));
    expect(SkillLevel.intermediate.brushes, contains(BrushType.picker));
    expect(BrushType.picker.usesColor, isFalse);
    expect(BrushType.picker.usesShapes, isFalse);
    expect(BrushType.picker.drawsNothing, isTrue);
    expect(
        commandFor(
            const KeyDownEvent(
                physicalKey: PhysicalKeyboardKey.keyI,
                logicalKey: LogicalKeyboardKey.keyI,
                character: 'i',
                timeStamp: Duration.zero),
            hasSelection: false),
        CanvasCommand.picker);
  });

  testWidgets('picking a color off the canvas', (tester) async {
    final app = await pumpApp(tester);
    const orange = Color(0xFFFF8E3C);
    final paper = tester.getRect(find.byKey(CanvasPageState.paperKey));
    // A big orange square in the middle of the paper.
    app.session.drawing.add(box(
        Rect.fromCenter(center: paper.size.center(Offset.zero), width: 120,
            height: 120),
        orange));
    app.settings
      ..color = Colors.black
      ..brush = BrushType.picker;
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(paper.center);
    // Reading the paper is real image work: give it real time.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('吸取的颜色 #FF8E3C')), findsOneWidget);
    await gesture.up();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(app.settings.color, near(orange));
    expect(app.settings.brush, isNot(BrushType.picker));
    await tester.pump(const Duration(seconds: 1));
  });
}
