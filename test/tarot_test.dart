import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/gallery/painting_file.dart';
import 'package:jingyao_paint/share/painting_export.dart';

import '../tool/tarot/deck.dart';
import '../tool/tarot/tarot_card.dart';

/// The tarot cards made by tool/tarot (not part of the app, but they must
/// keep opening in it).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final card in deck) {
    group(card.fileName, () {
      final doc = card.doc(DateTime(2026, 10, 27));

      test('saves and reopens with every stroke, name and keyword', () {
        final back = PaintingFile.decode(PaintingFile.encode(doc));
        expect(back.strokes, hasLength(doc.strokes.length));
        expect(back.meta.name, contains(card.zh));
        final words = back.strokes.map((s) => s.text?.text).whereType<String>();
        expect(words, containsAll([card.numeral, card.zh, ...card.keywords]));
      });

      test('the paper is exactly the card, in the file and in pictures',
          () async {
        final back = PaintingFile.decode(PaintingFile.encode(doc));
        expect(back.paperSize, TarotCard.size);
        final png = await exportPainting(back, ExportFormat.png);
        final image = await decodeImageFromList(png.bytes);
        expect([image.width, image.height], [1400, 2400],
            reason: 'twice the card, with no margin');
      });
    });
  }
}
