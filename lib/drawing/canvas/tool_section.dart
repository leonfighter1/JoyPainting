import 'package:flutter/material.dart';

import '../../settings.dart';
import '../../theme/cute_theme.dart';

/// The tools drawer's sections. A tap on a heading opens or closes it, and
/// the drawer remembers. The everyday ones start open; the ones the
/// intermediate and advanced levels add start closed.
enum ToolSection {
  brushes(openAtFirst: true),
  moreBrushes(openAtFirst: false),
  colors(openAtFirst: true),
  shapes(openAtFirst: true),
  stamps(openAtFirst: true),
  gradient(openAtFirst: false),
  lightAndShadow(openAtFirst: false),
  texture(openAtFirst: false);

  const ToolSection({required this.openAtFirst});

  /// Open until it's closed.
  final bool openAtFirst;

  bool isOpen(AppSettings settings) =>
      settings.sectionOpen(name, byDefault: openAtFirst);
}

/// A tools drawer section's heading: a tap opens or closes the section.
/// While it's closed it shows what's chosen in it: [chosen], or a [swatch]
/// of the color.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    required this.open,
    required this.onTap,
    this.chosen,
    this.swatch,
  });

  final String title;
  final bool open;
  final VoidCallback onTap;
  final String? chosen;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final cute = CuteTheme.of(context);
    final style = TextStyle(color: cute.ink, fontSize: 13);
    final chosen = open ? null : this.chosen;
    final swatch = open ? null : this.swatch;
    return Semantics(
      button: true,
      expanded: open,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          // A full-size touch target.
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
            child: Row(
              children: [
                Text(title, style: style.copyWith(fontWeight: FontWeight.w800)),
                if (chosen != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '· $chosen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                ],
                if (swatch != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: cute.ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
