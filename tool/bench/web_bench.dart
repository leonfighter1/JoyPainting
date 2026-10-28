import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:jingyao_paint/app_theme.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/family.dart';
import 'package:jingyao_paint/gallery/level_samples.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/l10n.dart';
import 'package:jingyao_paint/main.dart';
import 'package:jingyao_paint/music/music_library.dart';
import 'package:jingyao_paint/painting_session.dart';
import 'package:jingyao_paint/settings.dart';
import 'package:jingyao_paint/skill_level.dart';
import 'package:jingyao_paint/theme/theme_spec.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import 'drawing_bench.dart';

/// The app in Chrome, running [drawingBench] by itself with simulated
/// touches, then posting the frame timings to the page's server
/// (tool/bench/serve.dart). Settings and paintings live in memory only.
/// Built and run by tool/bench/web_bench.ps1; not part of the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // In memory, so the browser's real settings are never touched.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'flutter.language': 'zh',
    'flutter.onboarded': true,
    'flutter.samplesAdded': <String>['beginner', 'intermediate', 'advanced'],
    'flutter.level': 'advanced',
  });
  final settings = await AppSettings.load();
  final backend = MemoryStoreBackend();
  final session = PaintingSession(
    store: Family.storeFor(backend, settings.currentKid),
    settings: settings,
  );
  final music = MusicLibrary(MemoryMusicFiles());
  runApp(PaintApp(
    settings: settings,
    session: session,
    themes: await ThemeSpec.loadAll(kThemeIds),
    music: music,
    family: Family(
        settings: settings, backend: backend, session: session, music: music),
  ));
  await Future<void>.delayed(const Duration(seconds: 3));

  final level = SkillLevel.fromName(
      const String.fromEnvironment('SAMPLE', defaultValue: 'advanced'));
  final doc = await LevelSamples.load(level, const S('zh'));
  final results = await drawingBench(
    drawing: session.drawing,
    settings: settings,
    doc: doc,
    paper: _paperOnScreen,
    swipe: _swipe,
  );
  final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
  results['about'] = {
    'platform': 'web (Chrome)',
    'sample': level.name,
    'strokes': doc.strokes.length,
    'screen': '${view.physicalSize.width.round()}x'
        '${view.physicalSize.height.round()} @${view.devicePixelRatio}',
  };
  await web.window
      .fetch(
        '/result'.toJS,
        web.RequestInit(method: 'POST', body: jsonEncode(results).toJS),
      )
      .toDart;
}

/// Where the paper is on screen.
Rect _paperOnScreen() {
  Rect? found;
  void visit(Element e) {
    if (found != null) return;
    if (e.widget.key == CanvasKeys.paper) {
      final box = e.renderObject! as RenderBox;
      found = MatrixUtils.transformRect(
          box.getTransformTo(null), Offset.zero & box.size);
      return;
    }
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement!.visitChildren(visit);
  return found!;
}

var _pointer = 100;

/// A finger moving along [path], as touches from the screen arrive.
Future<void> _swipe(List<Offset> path) async {
  final id = _pointer++;
  final gestures = GestureBinding.instance;
  gestures.handlePointerEvent(PointerDownEvent(
      pointer: id, position: path.first, kind: PointerDeviceKind.touch));
  var last = path.first;
  for (final p in path.skip(1)) {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    gestures.handlePointerEvent(PointerMoveEvent(
        pointer: id,
        position: p,
        delta: p - last,
        kind: PointerDeviceKind.touch));
    last = p;
  }
  gestures.handlePointerEvent(PointerUpEvent(
      pointer: id, position: last, kind: PointerDeviceKind.touch));
}
