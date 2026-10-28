
import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../settings.dart';
import '../../theme/cute_theme.dart';
import '../stroke.dart';
import 'brush_tile.dart';
import 'color_widgets.dart';
import 'tool_catalog.dart';

/// The pinned palette on an upright phone: one row under the paper with
/// every brush and the colors, scrolling sideways, so most of the screen
/// stays paper. "More" slides in the full drawer (sizes, shapes, opacity).
class PaletteStrip extends StatelessWidget {
  const PaletteStrip({
    super.key,
    required this.settings,
    required this.palette,
    required this.onMore,
    required this.onUnpin,
  });

  final AppSettings settings;
  final List<Color> palette;
  final VoidCallback onMore;
  final VoidCallback onUnpin;

  static const rowHeight = 52.0;
  static const height = rowHeight * 2;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    final brush = settings.brush;
    final colors = [
      for (final c in settings.customColors)
        if (!palette.any((p) => p.toARGB32() == c.toARGB32())) c,
      ...palette,
    ];
    return Material(
      elevation: 12,
      shadowColor: cute.spec.primary.withValues(alpha: 0.4),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(cute.radius)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              // Brushes above, colors below: both one tap away, each row
              // scrolling sideways on its own.
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: rowHeight,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        children: [
                          // The brushes and helpers the drawer shows.
                          for (final group in const [
                            ToolGroup.brushes,
                            ToolGroup.helpers,
                          ])
                            for (final o
                                in ToolCatalog.options(group, settings, s))
                              if (o.shownWith(settings.addedTools))
                                MiniBrush(
                                  brush: o.brush!,
                                  label: o.label,
                                  selected: o.selected,
                                  onTap: o.onSelect,
                                ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: rowHeight,
                      // Picking a color while erasing switches to the pen,
                      // as in the drawer.
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        children: [
                          for (final c in colors)
                            Swatch(
                              color: c,
                              label: s.colorLabel(c),
                              selected: brush.usesColor &&
                                  c.toARGB32() == settings.color.toARGB32(),
                              onTap: () => settings.color = c,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: s.moreTools,
                    icon: const Icon(Icons.tune_rounded),
                    color: cute.ink,
                    onPressed: onMore,
                  ),
                  IconButton(
                    tooltip: s.unpinPalette,
                    icon: const Icon(Icons.push_pin_rounded),
                    color: cute.spec.primary,
                    onPressed: onUnpin,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A brush as a small round button for the strip (48×48 to tap).
class MiniBrush extends StatelessWidget {
  const MiniBrush({
    super.key,
    required this.brush,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final BrushType brush;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: BrushBubble(
                brush: brush,
                selected: selected,
                size: 40,
                iconSize: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
