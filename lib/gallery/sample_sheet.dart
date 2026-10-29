import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../skill_level.dart';
import '../theme/cute_theme.dart';
import 'level_sheet.dart';
import 'level_samples.dart';

/// Shows the sample paintings, starting with [level]'s; the level whose
/// sample is to be put into My Paintings, or null. [preview] paints a
/// sample's picture.
Future<SkillLevel?> pickSample(
  BuildContext context,
  SkillLevel level,
  Future<Uint8List> Function(SkillLevel level) preview,
) =>
    showModalBottomSheet<SkillLevel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SampleSheet(level: level, preview: preview),
    );

/// The samples: for each level, a painting that shows what its tools can
/// do (see [LevelSamples]), to look at and to add if the kid wants it.
class SampleSheet extends StatefulWidget {
  const SampleSheet({super.key, required this.level, required this.preview});

  /// The level shown first.
  final SkillLevel level;
  final Future<Uint8List> Function(SkillLevel level) preview;

  static const addKey = Key('addSample');

  @override
  State<SampleSheet> createState() => _SampleSheetState();
}

class _SampleSheetState extends State<SampleSheet> {
  /// Each level's picture, painted once.
  final _previews = <SkillLevel, Future<Uint8List>>{};

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LevelSheet(
      title: s.samples,
      hint: s.samplesHint,
      initial: widget.level,
      builder: (context, level) => SingleChildScrollView(
        key: ValueKey(level),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: _SampleCard(
          level: level,
          preview: _previews.putIfAbsent(level, () => widget.preview(level)),
        ),
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.level, required this.preview});

  final SkillLevel level;
  final Future<Uint8List> preview;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    void add() => Navigator.pop(context, level);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: add,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The samples are 1200 × 800.
            AspectRatio(
              aspectRatio: 1.5,
              child: FutureBuilder(
                future: preview,
                builder: (_, shot) => switch (shot.data) {
                  final bytes? => Image.memory(bytes,
                      fit: BoxFit.cover, excludeFromSemantics: true),
                  null when shot.hasError =>
                    const Icon(Icons.broken_image_outlined),
                  null => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(LevelSamples.name(level, s),
                  style: TextStyle(
                      color: cute.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
              child: Text(s.levelDescription(level),
                  style: TextStyle(color: cute.ink)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.tonalIcon(
                  key: SampleSheet.addKey,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(s.addSample),
                  onPressed: add,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
