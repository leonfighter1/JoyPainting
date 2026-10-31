
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../l10n.dart';
import '../../widgets/press_bounce.dart';

/// The everyday colors offered for brushes, text and the selection.
abstract final class AppPalette {
  static const colors = [
    Colors.black,
    Colors.white,
    Color(0xFFFF5A5F),
    Color(0xFFFF8E3C),
    Color(0xFFFFD23F),
    Color(0xFF3DDC97),
    Color(0xFF3DA9FC),
    Color(0xFF7F5AF0),
    Color(0xFFFF6FB5),
    Color(0xFFFFB3C7),
    Color(0xFFB8E0FF),
    Color(0xFF8D6E63),
  ];
}

/// The full color picker. Returns the chosen (opaque) color, or null.
Future<Color?> showAppColorPicker(BuildContext context, Color initial) async {
  final s = S.of(context);
  var picked = initial.withValues(alpha: 1);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.pickColor),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: picked,
          onColorChanged: (c) => picked = c,
          // Transparency has its own slider.
          enableAlpha: false,
          displayThumbColor: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ).bouncy(),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(s.useColor),
        ).bouncy(),
      ],
    ),
  );
  return ok == true ? picked : null;
}

/// A round color. The visible dot is small but the tap area is 48x48.
class Swatch extends StatelessWidget {
  const Swatch({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: selected ? 38 : 32,
              height: selected ? 38 : 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? ring : Colors.black26,
                  width: selected ? 3 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: ring.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    ).bouncy();
  }
}

/// A rainbow button that opens the full color picker.
class MoreColorsButton extends StatelessWidget {
  const MoreColorsButton({super.key, required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFFFF5A5F),
                    Color(0xFFFFD23F),
                    Color(0xFF3DDC97),
                    Color(0xFF3DA9FC),
                    Color(0xFF7F5AF0),
                    Color(0xFFFF5A5F),
                  ],
                ),
              ),
              child: SizedBox(
                width: 36,
                height: 36,
                // Black on the light rainbow keeps the icon visible (3:1+).
                child: Icon(
                  Icons.palette_rounded,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ).bouncy(),
    );
  }
}

class PaperChoice extends StatelessWidget {
  const PaperChoice({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? primary : Colors.black26,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, color: primary)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

