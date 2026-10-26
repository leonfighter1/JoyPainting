import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/gallery/sample_painting.dart';
import 'package:jingyao_paint/l10n.dart';
import 'package:jingyao_paint/onboarding_page.dart';
import 'package:jingyao_paint/settings.dart';

import 'test_helpers.dart';
import 'widget_test.dart'
    show drawStroke, inGallery, openTab, pumpApp, tapMenu;

/// Presses [key] with Ctrl (and Shift) held, as on a computer keyboard.
Future<void> ctrl(WidgetTester tester, LogicalKeyboardKey key,
    {bool shift = false}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

void main() {
  group('Bigger paper', () {
    testWidgets('shows at real size after picking it, growing right and down',
        (tester) async {
      await pumpApp(tester);
      final paper = find.byKey(CanvasPageState.paperKey);
      final before = tester.getRect(paper);
      await tapMenu(tester, '画纸大小');
      await tester.tap(find.text('4倍 · 宽和高都是 2 倍'));
      await tester.pumpAndSettle();

      final after = tester.getRect(paper);
      expect(after.width, closeTo(before.width * 2, 2),
          reason: 'twice as wide on screen, not shrunk to fit');
      expect(after.height, closeTo(before.height * 2, 2));
      expect(after.topLeft.dx, closeTo(before.topLeft.dx, 2),
          reason: "what's drawn stays where it was");
      expect(after.topLeft.dy, closeTo(before.topLeft.dy, 2));
      expect(find.textContaining('画纸变大啦'), findsOneWidget);

      // "Fit to screen" (the zoom chip) shows the whole sheet again.
      await tester.tap(find.textContaining('% · 适应屏幕'));
      await tester.pumpAndSettle();
      expect(tester.getRect(paper).width, closeTo(before.width, 2));
      await tester.pump(const Duration(seconds: 7));
    });
  });

  group('Keyboard shortcuts', () {
    testWidgets('Ctrl+Z undoes, Ctrl+Y and Ctrl+Shift+Z redo',
        (tester) async {
      final app = await pumpApp(tester);
      await drawStroke(tester);
      final drawing = app.session.drawing;
      expect(drawing.strokes, hasLength(1));
      await ctrl(tester, LogicalKeyboardKey.keyZ);
      expect(drawing.strokes, isEmpty);
      await ctrl(tester, LogicalKeyboardKey.keyY);
      expect(drawing.strokes, hasLength(1));
      await ctrl(tester, LogicalKeyboardKey.keyZ);
      await ctrl(tester, LogicalKeyboardKey.keyZ, shift: true);
      expect(drawing.strokes, hasLength(1));
      await tester.pump(const Duration(seconds: 1)); // autosave
    });

    testWidgets('select all, copy, paste, duplicate, delete and Esc',
        (tester) async {
      final app = await pumpApp(tester);
      await drawStroke(tester);
      final drawing = app.session.drawing;
      final state = tester.state<CanvasPageState>(find.byType(CanvasPage));

      await ctrl(tester, LogicalKeyboardKey.keyA);
      expect(app.settings.brush, BrushType.move);
      expect(state.selected.value, hasLength(1));

      await ctrl(tester, LogicalKeyboardKey.keyC);
      await ctrl(tester, LogicalKeyboardKey.keyV);
      expect(drawing.strokes, hasLength(2), reason: 'pasted');
      final pasted = state.selected.value.single;
      expect(pasted.bounds.topLeft - drawing.strokes.first.bounds.topLeft,
          const Offset(24, 24), reason: 'a step down and right');
      await ctrl(tester, LogicalKeyboardKey.keyV);
      expect(drawing.strokes, hasLength(3),
          reason: 'pasting again adds another');

      await ctrl(tester, LogicalKeyboardKey.keyD);
      expect(drawing.strokes, hasLength(4), reason: 'duplicated');

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(drawing.strokes, hasLength(3), reason: 'the copy was deleted');

      await ctrl(tester, LogicalKeyboardKey.keyA);
      expect(state.selected.value, hasLength(3));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(state.selected.value, isEmpty);
      await ctrl(tester, LogicalKeyboardKey.keyZ);
      expect(drawing.strokes, hasLength(4), reason: 'delete is undoable');
      await tester.pump(const Duration(seconds: 1)); // autosave
    });

    testWidgets('copied strokes can be pasted into another painting',
        (tester) async {
      final app = await pumpApp(tester);
      await drawStroke(tester);
      await ctrl(tester, LogicalKeyboardKey.keyA);
      await ctrl(tester, LogicalKeyboardKey.keyC);
      await app.session.newPainting();
      await tester.pumpAndSettle();
      expect(app.session.drawing.strokes, isEmpty);
      await ctrl(tester, LogicalKeyboardKey.keyV);
      expect(app.session.drawing.strokes, hasLength(1));
      await tester.pump(const Duration(seconds: 1)); // autosave
    });

    testWidgets('letter keys pick tools, brackets change the size',
        (tester) async {
      final app = await pumpApp(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pump();
      expect(app.settings.brush, BrushType.eraser);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();
      expect(app.settings.brush, BrushType.pen);
      final size = app.settings.size;
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
      await tester.pump();
      expect(app.settings.size, size + 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pump();
      final state = tester.state<CanvasPageState>(find.byType(CanvasPage));
      expect(state.panMode.value, isTrue, reason: 'H toggles ✋');
    });

    testWidgets('? lists the shortcuts', (tester) async {
      await pumpApp(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash, character: '?');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.text('键盘快捷键'), findsOneWidget);
      expect(find.text('${CanvasPageState.commandKey}+Z'), findsOneWidget);

      // While the list is open, keys don't reach the paper underneath.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pump();
      expect(find.text('键盘快捷键'), findsOneWidget);
    });

    testWidgets('keys do nothing to the paper while another tab is showing',
        (tester) async {
      final app = await pumpApp(tester);
      await drawStroke(tester);
      await openTab(tester, 1);
      await ctrl(tester, LogicalKeyboardKey.keyZ);
      expect(app.session.drawing.strokes, hasLength(1));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      expect(app.settings.brush, BrushType.pen);
      await tester.pump(const Duration(seconds: 1)); // autosave
    });

    test('every shortcut is explained in both languages', () {
      final zh = const S('zh').shortcuts('Ctrl');
      final en = const S('en').shortcuts('Ctrl');
      expect(zh.length, en.length);
      expect(zh.first, ('Ctrl+Z', '撤销'));
      expect(en.first, ('Ctrl+Z', 'Undo'));
    });
  });

  group('Copying a painting', () {
    testWidgets('My Paintings makes a copy with its own name',
        (tester) async {
      final app = await createTestApp();
      await app.store.save(
          sampleDoc('a', DateTime(2026, 2, 1)).withName('小猫'), tinyPng);
      await pumpApp(tester, app: app);
      await openTab(tester, 1);
      await tester.tap(find.byType(PopupMenuButton<VoidCallback>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '复制一份'));
      await tester.pumpAndSettle();

      expect(inGallery(find.text('小猫 副本')), findsOneWidget);
      expect(inGallery(find.text('小猫')), findsOneWidget,
          reason: 'the original stays');
      final copy = (await app.store.list())
          .firstWhere((m) => m.name == '小猫 副本');
      expect(copy.id, isNot('a'));
      final original = (await app.store.load('a'))!;
      final copied = (await app.store.load(copy.id))!;
      expect(copied.strokes.length, original.strokes.length);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('copying the open painting includes what was just drawn',
        (tester) async {
      final app = await pumpApp(tester);
      await drawStroke(tester);
      final copy = await app.session.duplicate(app.session.id, 'copy');
      expect(copy!.strokes, hasLength(1));
      expect(copy.meta.id, isNot(app.session.id));
      expect(app.session.isSaved, isTrue);
      await tester.pump(const Duration(seconds: 1)); // autosave
    });
  });

  group('Sample painting', () {
    testWidgets('each kid gets it once, in their language', (tester) async {
      final app = await createTestApp(prefs: {'flutter.sampleAdded': false});
      await app.session.restoreLast();
      var paintings = await app.store.list();
      expect([for (final m in paintings) m.name], ['快乐的一天']);
      final doc = (await app.store.load(paintings.single.id))!;
      expect(doc.paper, SamplePainting.paper);
      expect(doc.strokes.length, greaterThan(50));
      expect(doc.strokes.any((s) => s.text?.text == '你好呀！'), isTrue);
      // Drawn on its own size: nothing sticks out past the sheet.
      final bounds = doc.strokes
          .map((s) => s.bounds)
          .reduce((a, b) => a.expandToInclude(b));
      expect(bounds.right, lessThanOrEqualTo(SamplePainting.size.width + 10));
      expect(bounds.bottom, lessThanOrEqualTo(SamplePainting.size.height + 10));

      // Deleted, it stays deleted.
      await app.session.delete(paintings.single.id);
      await app.session.restoreLast();
      paintings = await app.store.list();
      expect(paintings.where((m) => m.name == '快乐的一天'), isEmpty);
    });

    testWidgets('a new install gets it after the setup, named in English',
        (tester) async {
      final app = await createTestApp(fresh: true);
      await pumpApp(tester, app: app);
      expect(await app.store.list(), isEmpty, reason: 'not before the setup');
      await tester.ensureVisible(find.byKey(OnboardingPage.startKey));
      await tester.tap(find.byKey(OnboardingPage.startKey));
      await tester.pumpAndSettle();
      expect([for (final m in await app.store.list()) m.name], ['A Happy Day']);
    });
  });

  group('Default kid name', () {
    testWidgets('Athena in English, 靖瑶 in Chinese, until it is changed',
        (tester) async {
      final app = await createTestApp(fresh: true);
      await pumpApp(tester, app: app);
      final field = find.byKey(OnboardingPage.nameFieldKey);
      String name() => tester.widget<TextField>(field).controller!.text;
      expect(name(), 'Athena');
      expect(find.text("Athena's Drawing Board"), findsOneWidget);

      await tester.tap(find.text('简体中文'));
      await tester.pumpAndSettle();
      expect(name(), '靖瑶');

      await tester.enterText(field, '小明');
      await tester.pump();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(name(), '小明', reason: 'a typed name is kept');

      await tester.ensureVisible(find.byKey(OnboardingPage.startKey));
      await tester.tap(find.byKey(OnboardingPage.startKey));
      await tester.pumpAndSettle();
      expect(app.settings.kidName, '小明');
    });

    test('settings keep the music mode a user picked', () {
      expect(MusicMode.fromName('repeatOne'), MusicMode.repeatOne);
      expect(MusicMode.fromName(null), MusicMode.shuffle);
    });
  });
}

extension on PaintingDoc {
  PaintingDoc withName(String name) =>
      PaintingDoc(meta: meta.copyWith(name: name), strokes: strokes, paper: paper);
}
