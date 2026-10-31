import 'package:flutter/material.dart';

import '../l10n.dart';
import '../skill_level.dart';
import '../theme/cute_theme.dart';
import '../widgets/snap_sheet.dart';

/// A bottom sheet (a [SnapSheet]: half the screen, or all of it pulled up)
/// with a title, a hint and a choice of drawing level; [builder] gives the
/// slivers that show what there is for the level picked. It starts at
/// [initial], the kid's own level, and any other can be picked.
class LevelSheet extends StatefulWidget {
  const LevelSheet({
    super.key,
    required this.title,
    required this.hint,
    required this.initial,
    required this.builder,
  });

  final String title;
  final String hint;
  final SkillLevel initial;
  final List<Widget> Function(BuildContext context, SkillLevel level) builder;

  @override
  State<LevelSheet> createState() => _LevelSheetState();
}

class _LevelSheetState extends State<LevelSheet> {
  late SkillLevel _level = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return SnapSheet(
      // A new level starts at the top.
      contentKey: _level,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        child: Text(widget.title,
            style: TextStyle(
                color: cute.ink, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(widget.hint, style: TextStyle(color: cute.ink)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final level in SkillLevel.values)
                      ChoiceChip(
                        label: Text(s.levelName(level)),
                        selected: level == _level,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _level = level),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        ...widget.builder(context, _level),
      ],
    );
  }
}
