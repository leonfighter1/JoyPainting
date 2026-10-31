import 'package:flutter/material.dart';

import '../l10n.dart';
import '../skill_level.dart';
import '../theme/cute_theme.dart';
import '../widgets/snap_sheet.dart';
import 'coloring_pages.dart';
import 'level_sheet.dart';

/// Shows the coloring pages to choose from, starting with [level]'s; the
/// one picked, or null.
Future<ColoringPage?> pickColoringPage(
  BuildContext context,
  SkillLevel level,
) =>
    showSnapSheet<ColoringPage>(
      context: context,
      builder: (_) => ColoringBookSheet(level: level),
    );

/// The coloring book: each level's pages as little pictures with names.
class ColoringBookSheet extends StatelessWidget {
  const ColoringBookSheet({super.key, required this.level});

  /// The level shown first.
  final SkillLevel level;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return LevelSheet(
      title: s.coloringBook,
      hint: s.coloringBookHint,
      initial: level,
      builder: (context, level) => [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          sliver: SliverGrid.extent(
            maxCrossAxisExtent: 170,
            childAspectRatio: 0.72,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final page in ColoringPage.of(level))
                Card(
                  key: ValueKey(page),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, page),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(page.preview,
                                excludeFromSemantics: true),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          child: Text(s.coloringName(page),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: cute.ink,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
