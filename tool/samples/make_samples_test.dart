// Makes the three sample paintings kids find in My Paintings, one per
// drawing level, as `.jypaint` files in assets/samples/ (see
// lib/gallery/level_samples.dart):
//
//   flutter test tool/samples/make_samples_test.dart
//
// It runs as a test because drawing text and pictures needs Flutter's
// engine. Previews (PNG) go to local_art/out/samples/, which isn't in git.
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_file.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/gallery/sample_painting.dart';
import 'package:jingyao_paint/l10n.dart';
import 'package:jingyao_paint/share/painting_export.dart';
import 'package:jingyao_paint/skill_level.dart';

import 'dawn_on_the_lake.dart';
import 'sunset_by_the_sea.dart';

PaintingDoc _doc(String name, List<Stroke> strokes, Size size, Color paper) {
  final when = DateTime(2026, 10, 27);
  return PaintingDoc(
    meta: PaintingMeta(
      id: 'sample',
      name: name,
      createdAt: when,
      updatedAt: when,
      width: size.width,
      height: size.height,
      strokeCount: strokes.length,
    ),
    strokes: strokes,
    paper: paper,
    paperSize: size,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const zh = S('zh');
  final samples = {
    SkillLevel.beginner: () => _doc(zh.samplePaintingName,
        SamplePainting.strokes(zh), SamplePainting.size, SamplePainting.paper),
    SkillLevel.intermediate: () => _doc(zh.sampleSunsetName,
        SunsetByTheSea.strokes(), SunsetByTheSea.size, SunsetByTheSea.paper),
    SkillLevel.advanced: () => _doc(zh.sampleLakeName,
        DawnOnTheLake.strokes(), DawnOnTheLake.size, DawnOnTheLake.paper),
  };
  for (final MapEntry(key: level, value: make) in samples.entries) {
    test(level.name, () async {
      final bytes = PaintingFile.encode(make());
      File('assets/samples/${level.name}.jypaint').writeAsBytesSync(bytes);
      final png = await exportPainting(
          PaintingFile.decode(bytes), ExportFormat.png);
      (Directory('local_art/out/samples')..createSync(recursive: true));
      File('local_art/out/samples/${level.name}.png')
          .writeAsBytesSync(png.bytes);
    });
  }
}
