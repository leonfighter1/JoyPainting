import 'package:flutter/services.dart';

import '../drawing/stroke.dart';
import '../l10n.dart';
import '../skill_level.dart';
import 'painting_file.dart';
import 'painting_store.dart';

/// The paintings a kid finds in My Paintings to begin with, one for each
/// drawing level, each showing what that level's tools can do:
///
/// - beginner: 快乐的一天 (A Happy Day), pens, shapes and stamps;
/// - intermediate: 海边的晚霞 (Sunset by the Sea), the soft brush,
///   gradients and free shapes;
/// - advanced: 湖畔晨光 (Dawn on the Lake), a realistic painting with
///   textures, the blender and light and shadow.
///
/// They're ordinary `.jypaint` files in `assets/samples/`, made by
/// `tool/samples/make_samples_test.dart`, so they open, move, recolor and
/// erase like anything drawn by hand. Their names say they're samples.
abstract final class LevelSamples {
  static String asset(SkillLevel level) =>
      'assets/samples/${level.name}.jypaint';

  static String name(SkillLevel level, S s) => s.sampleTitle(switch (level) {
    SkillLevel.beginner => s.samplePaintingName,
    SkillLevel.intermediate => s.sampleSunsetName,
    SkillLevel.advanced => s.sampleLakeName,
  });

  /// The gallery thumbnail of [level]'s sample, made beforehand by
  /// `tool/samples/make_sample_thumbnails_test.dart`: painting the
  /// thousands of strokes of the bigger samples takes seconds in a
  /// browser. Null for the beginner's, whose greeting follows the
  /// language; it's quick to paint when it's added.
  static Future<Uint8List?> thumbnail(
    SkillLevel level, {
    AssetBundle? bundle,
  }) async {
    if (level == SkillLevel.beginner) return null;
    final data = await (bundle ?? rootBundle).load(thumbnailAsset(level));
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static String thumbnailAsset(SkillLevel level) =>
      'assets/samples/${level.name}.png';

  /// The greeting the beginner sample's sun says in the file; it's swapped
  /// for the app's language when loaded.
  static final fileGreeting = const S('zh').sampleGreeting;

  /// The sample for [level], named in the language of [s].
  static Future<PaintingDoc> load(
    SkillLevel level,
    S s, {
    AssetBundle? bundle,
  }) async {
    final data = await (bundle ?? rootBundle).load(asset(level));
    final doc = PaintingFile.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final now = DateTime.now();
    return PaintingDoc(
      meta: PaintingMeta(
        id: '',
        name: name(level, s),
        createdAt: now,
        updatedAt: now,
        width: doc.meta.width,
        height: doc.meta.height,
        strokeCount: doc.strokes.length,
      ),
      strokes: [
        for (final stroke in doc.strokes)
          if (stroke.text case final t? when t.text == fileGreeting)
            Stroke.text(
              anchor: stroke.anchor,
              content: t.copyWith(text: s.sampleGreeting),
              color: stroke.color,
              opacity: stroke.opacity,
              transform: stroke.transform,
            )
          else
            stroke,
      ],
      paper: doc.paper,
      paperSize: doc.paperSize,
      layers: doc.layers,
    );
  }
}
