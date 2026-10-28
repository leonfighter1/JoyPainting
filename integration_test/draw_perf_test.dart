import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jingyao_paint/app_theme.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/family.dart';
import 'package:jingyao_paint/gallery/level_samples.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/l10n.dart';
import 'package:jingyao_paint/main.dart';
import 'package:jingyao_paint/painting_session.dart';
import 'package:jingyao_paint/skill_level.dart';
import 'package:jingyao_paint/theme/theme_spec.dart';

import '../test/test_helpers.dart';
import '../tool/bench/drawing_bench.dart';

/// How smooth the drawing screen is with a big painting (the advanced
/// sample, about 3,000 strokes), with and without the kept picture: see
/// [drawingBench] (TECH_PLAN.md, F1). Settings and paintings live in
/// memory, so nothing on the device is touched. In Chrome, use
/// tool/bench/web_bench.ps1 instead. Run on a phone in profile mode:
///
///   flutter drive --profile --driver=test_driver/integration_test.dart \
///     --target=integration_test/draw_perf_test.dart -d emulator-5554
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('drawing, erasing and undoing on a big painting',
      (tester) async {
    final test = await createTestApp();
    // Real thumbnails, as the app makes after every edit.
    final session = PaintingSession(
      store: Family.storeFor(MemoryStoreBackend(), test.settings.currentKid),
      settings: test.settings,
    );
    final app = TestApp(test.settings, MemoryStoreBackend(), session)
      ..base = MemoryStoreBackend();
    await tester.pumpWidget(PaintApp(
      settings: app.settings,
      session: session,
      themes: await ThemeSpec.loadAll(kThemeIds),
      music: app.music,
      family: app.family,
    ));
    await tester.pumpAndSettle();
    // --dart-define=SAMPLE=intermediate for a lighter painting.
    final level = SkillLevel.fromName(
        const String.fromEnvironment('SAMPLE', defaultValue: 'advanced'));
    final doc = await LevelSamples.load(level, const S('zh'));
    Future<void> swipe(List<Offset> path) async {
      final g = await tester.startGesture(path.first);
      for (final p in path.skip(1)) {
        await g.moveTo(p);
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      await g.up();
    }

    binding.reportData = await drawingBench(
      drawing: session.drawing,
      settings: app.settings,
      doc: doc,
      paper: () => tester.getRect(find.byKey(CanvasKeys.paper)),
      swipe: swipe,
    );
    // Let the last autosave finish.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
  });
}
