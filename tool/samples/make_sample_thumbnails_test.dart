// Paints the gallery thumbnails of the bigger level samples beforehand,
// into assets/samples/<level>.png (see LevelSamples.thumbnail):
//
//   flutter test tool/samples/make_sample_thumbnails_test.dart
//
// Run it again whenever make_samples_test.dart changes a sample. Painting
// the 3,058 strokes of the advanced one took 4 s in Chrome, which stalled
// the app when a kid picked that level.
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/gallery/level_samples.dart';
import 'package:jingyao_paint/l10n.dart';
import 'package:jingyao_paint/painting_session.dart';
import 'package:jingyao_paint/skill_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paint the sample thumbnails', () async {
    for (final level in SkillLevel.values) {
      if (level == SkillLevel.beginner) continue;
      final doc = await LevelSamples.load(level, const S('zh'));
      // As PaintingSession paints one when it adds a painting.
      final png = await renderThumbnail(doc.strokes,
          Size(doc.meta.width, doc.meta.height), doc.paper, doc.layers);
      File(LevelSamples.thumbnailAsset(level)).writeAsBytesSync(png);
    }
  });
}
