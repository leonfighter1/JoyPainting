import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme/cute_theme.dart';
import 'coloring_pages.dart';

/// Shows the coloring pages to choose from; the one picked, or null.
Future<ColoringPage?> pickColoringPage(BuildContext context) =>
    showModalBottomSheet<ColoringPage>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const ColoringBookSheet(),
    );

/// The coloring book: every page as a little picture with its name.
class ColoringBookSheet extends StatelessWidget {
  const ColoringBookSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(s.coloringBook,
                  style: TextStyle(
                      color: cute.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(s.coloringBookHint,
                  style: TextStyle(color: cute.ink)),
            ),
            Flexible(
              child: GridView.extent(
                shrinkWrap: true,
                maxCrossAxisExtent: 170,
                childAspectRatio: 0.72,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final page in ColoringPage.values)
                    Card(
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
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(s.coloringName(page),
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
        ),
      ),
    );
  }
}
