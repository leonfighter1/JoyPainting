// Makes the tarot cards as JoyPainting paintings (to import into the app
// and keep drawing on) and as PNG pictures, in dist/tarot/:
//
//   flutter test tool/tarot/make_tarot_test.dart
//
// It runs as a test because drawing text and pictures needs Flutter's
// engine. The PNG is drawn from the saved file read back, so it shows
// exactly what the app will open.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/gallery/painting_file.dart';
import 'package:jingyao_paint/share/painting_export.dart';

import 'deck.dart';

const _fonts = {
  'ZCOOLKuaiLe': 'assets/fonts/zcoolkuaile/ZCOOLKuaiLe-Regular.ttf',
  'ZCOOLQingKeHuangYou':
      'assets/fonts/zcoolqingkehuangyou/ZCOOLQingKeHuangYou-Regular.ttf',
  'LongCang': 'assets/fonts/longcang/LongCang-Regular.ttf',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final MapEntry(key: family, value: path) in _fonts.entries) {
      final bytes = File(path).readAsBytesSync();
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });

  for (final card in deck) {
    test(card.fileName, () async {
      final out = Directory('dist/tarot')..createSync(recursive: true);
      final file = PaintingFile.encode(card.doc(DateTime(2026, 10, 27)));
      File('${out.path}/${card.fileName}.${PaintingFile.extension}')
          .writeAsBytesSync(file);
      final back = PaintingFile.decode(Uint8List.fromList(file));
      final png = await exportPainting(back, ExportFormat.png);
      File('${out.path}/${card.fileName}.png').writeAsBytesSync(png.bytes);
      expect(back.strokes, hasLength(card.strokes().length));
    });
  }
}
