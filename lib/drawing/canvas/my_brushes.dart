import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../settings.dart';
import '../../widgets/name_dialog.dart';
import '../brush_preset.dart';

/// 我的画笔: saves the brush in use, with its settings, under a name the
/// kid gives it.
Future<void> saveMyBrush(BuildContext context, AppSettings settings) async {
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final presets = settings.brushPresets;
  if (presets.length >= BrushPreset.max) {
    messenger.showSnackBar(SnackBar(content: Text(s.myBrushesFull)));
    return;
  }
  final name = await showNameDialog(
    context,
    title: s.nameMyBrush,
    initial: s.myBrushName(presets.length + 1),
  );
  if (name == null) return;
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  settings.brushPresets = [...presets, settings.presetNow(id, name)];
  messenger.showSnackBar(SnackBar(content: Text(s.myBrushSaved(name))));
}

/// Asks, then deletes one of 我的画笔.
Future<void> deleteMyBrush(
  BuildContext context,
  AppSettings settings,
  BrushPreset preset,
) async {
  final s = S.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.deleteMyBrush(preset.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(s.delete),
        ),
      ],
    ),
  );
  if (ok != true) return;
  settings.brushPresets = [
    for (final p in settings.brushPresets)
      if (p.id != preset.id) p,
  ];
}

/// The chip after the brushes that saves the one in use as 我的画笔.
class SaveBrushChip extends StatelessWidget {
  const SaveBrushChip({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        key: const ValueKey('saveBrush'),
        avatar: Icon(
          Icons.bookmark_add_rounded,
          size: 18,
          color: scheme.primary,
        ),
        label: Text(S.of(context).saveBrush),
        labelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
        backgroundColor: scheme.surface,
        onPressed: () => saveMyBrush(context, settings),
      ),
    );
  }
}
