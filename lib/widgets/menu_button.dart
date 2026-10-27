import 'package:flutter/material.dart';

import '../theme/cute_theme.dart';

/// The menu button at the top right of a page: an outlined pill with a menu
/// icon and a small arrow saying it unfolds, so it stands out on the header
/// more than three faint dots would.
class MenuButton extends StatelessWidget {
  const MenuButton({super.key, required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  /// Finds the button in tests.
  static const icon = Icons.menu_rounded;

  @override
  Widget build(BuildContext context) {
    final fg = CuteTheme.of(context).onHeader;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          // The whole 48px-high area takes the tap; the pill is drawn
          // inside it.
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: fg.withValues(alpha: 0.16),
                  shape: StadiumBorder(
                    side: BorderSide(
                        color: fg.withValues(alpha: 0.7), width: 1.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: fg, size: 24),
                      Icon(Icons.arrow_drop_down_rounded, color: fg, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
