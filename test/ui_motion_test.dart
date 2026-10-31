import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/app_theme.dart';
import 'package:jingyao_paint/family.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/main.dart';
import 'package:jingyao_paint/theme/cute_theme.dart';
import 'package:jingyao_paint/theme/theme_spec.dart';
import 'package:jingyao_paint/theme/touch_ripple.dart';
import 'package:jingyao_paint/widgets/drawn_check.dart';
import 'package:jingyao_paint/widgets/elastic_switch.dart';
import 'package:jingyao_paint/widgets/liquid_slider.dart';
import 'package:jingyao_paint/widgets/menu_button.dart';
import 'package:jingyao_paint/widgets/motion.dart';
import 'package:jingyao_paint/widgets/press_bounce.dart';
import 'package:jingyao_paint/widgets/skeleton.dart';
import 'package:jingyao_paint/widgets/snap_sheet.dart';

import 'test_helpers.dart';
import 'widget_test.dart' show inGallery, openTab, pumpApp;

List<ThemeSpec>? _themes;

Future<ThemeData> _cuteTheme(WidgetTester tester) async {
  _themes ??= await tester.runAsync(() => ThemeSpec.loadAll(kThemeIds));
  return CuteTheme.build(_themes!.first);
}

/// [child] alone on a page in the app's first theme.
Future<void> _pumpAlone(WidgetTester tester, Widget child) async {
  final theme = await _cuteTheme(tester);
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(body: Center(child: child)),
  ));
}

/// Every call of [method] when [finder]'s widget paints, with its arguments.
List<List<dynamic>> _calls(Finder finder, Symbol method) {
  final calls = <List<dynamic>>[];
  expect(
    finder,
    paints
      ..everything((m, args) {
        if (m == method) calls.add(args);
        return true;
      }),
  );
  return calls;
}

/// Holds back reading the list of paintings until [gate] completes.
class _GatedBackend extends MemoryStoreBackend {
  Completer<void>? gate;

  @override
  Future<String?> readText(String name) async {
    if (name.endsWith('index.json')) await gate?.future;
    return super.readText(name);
  }
}

void main() {
  group('Press bounce', () {
    double scale(WidgetTester tester) => tester
        .widget<ScaleTransition>(find.descendant(
            of: find.byType(PressBounce),
            matching: find.byType(ScaleTransition)))
        .scale
        .value;

    testWidgets('a pressed button shrinks to 96 %, then springs back a little '
        'past its size', (tester) async {
      await _pumpAlone(
          tester, FilledButton(onPressed: () {}, child: const Text('好')).bouncy());
      final press =
          await tester.startGesture(tester.getCenter(find.byType(FilledButton)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(scale(tester), closeTo(0.96, 0.001));
      await press.up();
      var peak = 0.0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        peak = math.max(peak, scale(tester));
      }
      expect(peak, inInclusiveRange(1.005, 1.03));
      await tester.pumpAndSettle();
      expect(scale(tester), closeTo(1, 0.0001));
    });

    testWidgets('a disabled button stays still', (tester) async {
      await _pumpAlone(
          tester, const FilledButton(onPressed: null, child: Text('好')).bouncy());
      final press =
          await tester.startGesture(tester.getCenter(find.byType(FilledButton)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(scale(tester), 1);
      await press.up();
    });
  });

  group('Elastic switch', () {
    RRect knob(WidgetTester tester) =>
        _calls(find.byType(ElasticSwitch), #drawRRect).last.first as RRect;

    testWidgets('the knob stretches on the way, squashes against the end and '
        'is round again', (tester) async {
      var on = false;
      await _pumpAlone(
        tester,
        StatefulBuilder(
          builder: (context, setState) => ElasticSwitch(
            value: on,
            onChanged: (v) => setState(() => on = v),
          ),
        ),
      );
      expect(knob(tester).width, knob(tester).height, reason: 'round when off');
      await tester.tap(find.byType(ElasticSwitch));
      expect(on, isTrue);
      var longest = 0.0;
      var flattest = double.infinity;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        final k = knob(tester);
        longest = math.max(longest, k.width / k.height);
        flattest = math.min(flattest, k.width / k.height);
      }
      expect(longest, greaterThan(1.3), reason: 'a capsule while it travels');
      expect(flattest, lessThan(0.95), reason: 'the bounce at the end');
      await tester.pumpAndSettle();
      expect(knob(tester).width, closeTo(24, 0.01));
      expect(knob(tester).height, closeTo(24, 0.01));
    });

    testWidgets('in a list row, the whole row flips it and reads as a switch',
        (tester) async {
      final semantics = tester.ensureSemantics();
      var on = false;
      await _pumpAlone(
        tester,
        StatefulBuilder(
          builder: (context, setState) => ElasticSwitchTile(
            title: const Text('音乐'),
            value: on,
            onChanged: (v) => setState(() => on = v),
          ),
        ),
      );
      await tester.tap(find.text('音乐'));
      await tester.pumpAndSettle();
      expect(on, isTrue);
      expect(
        tester.getSemantics(find.byType(ElasticSwitchTile)),
        isSemantics(
            label: '音乐', hasToggledState: true, isToggled: true, hasTapAction: true),
      );
      semantics.dispose();
    });
  });

  group('Touch ripple', () {
    testWidgets('is the theme\'s ripple', (tester) async {
      final theme = await _cuteTheme(tester);
      expect(theme.splashFactory, same(TouchRipple.splashFactory));
    });

    testWidgets('grows from where the finger went down and stays there',
        (tester) async {
      const key = Key('well');
      await _pumpAlone(
        tester,
        SizedBox(
          width: 300,
          height: 60,
          child: Material(child: InkWell(key: key, onTap: () {})),
        ),
      );
      final box = tester.getRect(find.byKey(key));
      final press = await tester.startGesture(box.topLeft + const Offset(30, 20));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      // Material's own ripple would have drifted toward x = 150 by now.
      expect(Material.of(tester.element(find.byKey(key))),
          paints..circle(x: 30, y: 20));
      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a long press that cancels a ripple before it shows is fine',
        (tester) async {
      const key = Key('well');
      await _pumpAlone(
        tester,
        SizedBox(
          width: 200,
          height: 60,
          child: Material(
            child: InkWell(key: key, onTap: () {}, onLongPress: () {}),
          ),
        ),
      );
      await tester.longPress(find.byKey(key));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a check mark draws itself from lower left to upper right in '
      '200 ms', (tester) async {
    var checked = false;
    late StateSetter setChecked;
    await _pumpAlone(
      tester,
      StatefulBuilder(builder: (context, setState) {
        setChecked = setState;
        return DrawnCheck(checked: checked, color: Colors.black, size: 100);
      }),
    );
    final check = find.byType(DrawnCheck);
    expect(check, paintsNothing);
    Rect drawn() => (_calls(check, #drawPath).single.first as Path).getBounds();

    setChecked(() => checked = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(drawn().left, closeTo(20, 1), reason: 'starts at the lower left');
    expect(drawn().right, lessThan(60), reason: 'not up to the right yet');
    await tester.pump(const Duration(milliseconds: 150));
    expect(drawn().right, closeTo(80, 1));
    expect(drawn().top, closeTo(31, 1));
  });

  group('Liquid slider', () {
    testWidgets('its thumb, fill and number above glide together',
        (tester) async {
      final semantics = tester.ensureSemantics();
      var value = 0.0;
      await _pumpAlone(
        tester,
        SizedBox(
          width: 420,
          child: StatefulBuilder(
            builder: (context, setState) => LiquidSlider(
              value: value,
              max: 100,
              divisions: 100,
              label: (v) => '${v.round()}',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      final slider = find.byType(LiquidSlider);
      // The track runs from 20 to 400.
      final press = await tester
          .startGesture(tester.getRect(slider).centerLeft + const Offset(20, 0));
      await press.moveBy(const Offset(0.8 * 380, 0));
      expect(value, 80);

      double thumb() =>
          (_calls(slider, #drawPath).single.first as Path).getBounds().center.dx;
      double fillEnd() => (_calls(slider, #drawRRect)[1].first as RRect).right;
      int bubble() => int.parse(tester
          .widget<Text>(find.byWidgetPredicate(
              (w) => w is Text && int.tryParse(w.data ?? '') != null))
          .data!);

      await tester.pump();
      await tester.pump(Motion.settle ~/ 4);
      final shown = (thumb() - 20) / 380 * 100;
      expect(shown, inExclusiveRange(5, 75), reason: 'still on its way');
      expect(fillEnd(), closeTo(thumb(), 0.01));
      expect(bubble(), closeTo(shown, 1));

      await tester.pump(Motion.settle);
      expect(thumb(), closeTo(20 + 0.8 * 380, 0.01));
      expect(bubble(), 80);
      await press.up();
      await tester.pumpAndSettle();

      // A screen reader steps it one division.
      expect(tester.getSemantics(slider).value, '80%');
      tester.semantics.increase(find.semantics.byValue('80%'));
      await tester.pumpAndSettle();
      expect(value, 81);
      semantics.dispose();
    });
  });

  testWidgets('a number rolls to its new value, slowing down as it gets close',
      (tester) async {
    var value = 0.0;
    late StateSetter setValue;
    await _pumpAlone(
      tester,
      StatefulBuilder(builder: (context, setState) {
        setValue = setState;
        return RollingNumber(
          value: value,
          builder: (context, v) => Text(v.toStringAsFixed(3)),
        );
      }),
    );
    double shown() => double.parse(tester.widget<Text>(find.byType(Text)).data!);
    setValue(() => value = 100);
    await tester.pump();
    var last = 0.0;
    var lastStep = double.infinity;
    for (var i = 0; i < 6; i++) {
      await tester.pump(Motion.roll ~/ 6);
      final step = shown() - last;
      expect(step, lessThan(lastStep), reason: 'slower each time');
      lastStep = step;
      last = shown();
    }
    expect(shown(), 100);
  });

  testWidgets('My Paintings loads behind placeholders the size of its cards, '
      'replaced where they stand', (tester) async {
    final backend = _GatedBackend();
    final app = await createTestApp(backend: backend);
    final store = Family.storeFor(backend, app.settings.currentKid);
    for (final (i, name) in ['小猫', '小狗', '小鸟'].indexed) {
      final doc = sampleDoc('p$i', DateTime(2026, 3, i + 1));
      await store.save(
        PaintingDoc(meta: doc.meta.copyWith(name: name), strokes: doc.strokes),
        tinyPng,
      );
    }
    backend.gate = Completer();

    tester.view.physicalSize = const Size(393, 829) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    _themes ??= await tester.runAsync(() => ThemeSpec.loadAll(kThemeIds));
    await tester.pumpWidget(PaintApp(
      settings: app.settings,
      session: app.session,
      themes: _themes!,
      music: app.music,
      family: app.family,
    ));
    Future<void> wait() async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await wait();
    final nav = find.byWidgetPredicate(
        (w) => w is NavigationBar || w is NavigationRail);
    await tester.tap(find.descendant(of: nav, matching: find.byType(Text)).at(1));
    await wait();
    expect(inGallery(find.byType(SkeletonLine)), findsWidgets);
    final placeholder = tester.getRect(inGallery(find.byType(Card)).first);
    const import = Key('galleryImport');
    final importAt = tester.getRect(find.byKey(import));

    backend.gate!.complete();
    await wait();
    expect(inGallery(find.byType(SkeletonLine)), findsNothing);
    expect(find.text('小鸟'), findsOneWidget, reason: 'newest first');
    expect(tester.getRect(inGallery(find.byType(Card)).first), placeholder);
    expect(tester.getRect(find.byKey(import)), importAt);
  });

  testWidgets('the menu button\'s lines turn into a cross while the menu is '
      'open, and back', (tester) async {
    await pumpApp(tester);
    final lines = find.descendant(
      of: find.byType(MenuButton).first,
      matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.size == const Size.square(24)),
    );
    expect(lines, paintsExactlyCountTimes(#drawLine, 3));
    await tester.tap(find.byType(MenuButton).first);
    await tester.pumpAndSettle();
    expect(lines, paintsExactlyCountTimes(#drawLine, 2),
        reason: 'the middle one has faded');
    expect(lines, paints..rotate()..line()..rotate()..line());
    await tester.tapAt(const Offset(5, 600));
    await tester.pumpAndSettle();
    expect(lines, paintsExactlyCountTimes(#drawLine, 3));
  });

  testWidgets('a sheet opens at half the screen, pulls up to all of it, and '
      'closes when pulled down past half its height', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 1);
    await tester.tap(find.text('涂色本'));
    await tester.pumpAndSettle();
    final handle = find.byKey(SnapSheet.handleKey);
    double top() => tester.getTopLeft(handle).dy;
    const height = 829.0;
    expect(top(), closeTo(height / 2, 2));

    await tester.drag(handle, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(top(), closeTo(0, 2), reason: 'the whole screen');
    await tester.drag(handle, const Offset(0, 250));
    await tester.pumpAndSettle();
    expect(top(), closeTo(height / 2, 2), reason: 'back to half');
    await tester.drag(handle, const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(top(), closeTo(height / 2, 2), reason: 'a short pull stays');

    await tester.tap(handle);
    await tester.pumpAndSettle();
    expect(top(), closeTo(0, 2), reason: 'a tap on the handle opens it up');
    await tester.tap(handle);
    await tester.pumpAndSettle();
    expect(top(), closeTo(height / 2, 2));

    await tester.drag(handle, const Offset(0, 250));
    await tester.pumpAndSettle();
    expect(handle, findsNothing, reason: 'closed');
  });
}
