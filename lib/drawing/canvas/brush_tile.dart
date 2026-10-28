
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../theme/cute_theme.dart';
import '../stroke.dart';

/// A large, round, colorful brush button with its name underneath.
class BrushTile extends StatelessWidget {
  const BrushTile({
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
    final cute = CuteTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 62,
            child: Column(
              children: [
                BrushBubble(
                  brush: brush,
                  selected: selected,
                  size: selected ? 56 : 52,
                  iconSize: 28,
                  raised: true,
                  duration: const Duration(milliseconds: 180),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cute.ink,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// A brush's round icon, tinted with the brush's color, or filled with it
/// and ringed in white when [selected]. [raised] gives a selected bubble
/// a soft gradient and shadow (the drawer's big tiles).
class BrushBubble extends StatelessWidget {
  const BrushBubble({
    super.key,
    required this.brush,
    required this.selected,
    required this.size,
    required this.iconSize,
    this.raised = false,
    this.duration = Duration.zero,
  });

  final BrushType brush;
  final bool selected;
  final double size;
  final double iconSize;
  final bool raised;

  /// How long a change of [selected] or [size] animates.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final cute = CuteTheme.of(context);
    final accent = AppTheme.brushColor(brush);
    final lifted = selected && raised;
    return AnimatedContainer(
      duration: duration,
      // No overshooting curves here: going past 1.0 makes the fading
      // shadow's blur radius negative, which crashes.
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: lifted
            ? LinearGradient(
                colors: [accent, Color.lerp(accent, Colors.white, 0.18)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: lifted
            ? null
            : selected
            ? accent
            : accent.withValues(alpha: AppTheme.brushTintAlpha),
        border: Border.all(
          color: selected ? Colors.white : accent.withValues(alpha: 0.25),
          width: selected ? 3 : 1.5,
        ),
        boxShadow: lifted
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        AppTheme.brushIcon(brush),
        size: iconSize,
        color: selected ? cute.onColor(accent) : accent,
      ),
    );
  }
}
