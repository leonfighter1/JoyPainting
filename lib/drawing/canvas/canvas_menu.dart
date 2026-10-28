import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../device.dart';
import '../../l10n.dart';
import '../../painting_session.dart';
import '../../settings.dart';
import '../../share/share_actions.dart';
import '../../widgets/drop_menu.dart';
import 'color_widgets.dart';

/// The ☰ menu on the drawing screen: a grouped list that unfolds from the
/// top and scrolls. Sharing and quick switches act here; the rest call
/// back into the drawing screen.
Future<void> showCanvasMenu(
  BuildContext context, {
  required PaintingSession session,
  required AppSettings settings,
  required ValueNotifier<bool> panMode,
  required bool hasPainting,
  required VoidCallback onReplay,
  required VoidCallback onShortcuts,
  required VoidCallback onPaperColor,
  required VoidCallback onDefaultPaperSize,
  VoidCallback? onImportPhoto,
  required VoidCallback onRename,
  required VoidCallback onDelete,
  required VoidCallback onSettings,
}) {
  final s = S.of(context);
  return showDropMenu(context, [
    DropMenuSection(
      title: s.menuShare,
      items: [
        DropMenuItem(
          icon: Icons.send_rounded,
          label: s.send,
          onSelected: () => showSendSheet(context, session.currentDoc()),
        ),
        DropMenuItem(
          icon: Icons.print_rounded,
          label: s.print,
          onSelected: () => printPainting(context, session.currentDoc()),
        ),
        DropMenuItem(
          icon: Icons.save_alt_rounded,
          label: s.downloadImage,
          onSelected: () => downloadPainting(context, session.currentDoc()),
        ),
        // The painting drawing itself again, stroke by stroke.
        DropMenuItem(
          icon: Icons.slow_motion_video_rounded,
          label: s.replay,
          enabled: session.drawing.strokes.isNotEmpty,
          onSelected: onReplay,
        ),
      ],
    ),
    DropMenuSection(
      title: s.menuView,
      items: [
        DropMenuItem(
          icon: Icons.pan_tool_rounded,
          label: s.panCanvas,
          checked: panMode.value,
          onSelected: () => panMode.value = !panMode.value,
        ),
        // Only where there's a keyboard to use them with.
        if (Device.current.desktopOs)
          DropMenuItem(
            icon: Icons.keyboard_rounded,
            label: s.keyboardShortcuts,
            onSelected: onShortcuts,
          ),
      ],
    ),
    DropMenuSection(
      title: s.menuPaper,
      items: [
        DropMenuItem(
          icon: Icons.flip_rounded,
          label: s.mirror,
          checked: settings.mirror,
          onSelected: () => settings.mirror = !settings.mirror,
        ),
        DropMenuItem(
          icon: Icons.wallpaper_rounded,
          label: s.paperColor,
          onSelected: onPaperColor,
        ),
        // A photo to trace (from the intermediate level).
        if (onImportPhoto != null)
          DropMenuItem(
            icon: Icons.add_photo_alternate_rounded,
            label: s.importPhoto,
            onSelected: onImportPhoto,
          ),
        // The paper is resized by its edge grips; this undoes all that.
        DropMenuItem(
          icon: Icons.aspect_ratio_rounded,
          label: s.paperDefaultSize,
          enabled: session.drawing.paperSize != null,
          onSelected: onDefaultPaperSize,
        ),
      ],
    ),
    // A quick switch; volume and tracks are in Settings.
    DropMenuSection(
      title: s.menuSound,
      items: [
        DropMenuItem(
          icon: Icons.music_note_rounded,
          label: s.backgroundMusic,
          checked: settings.musicOn,
          onSelected: () => settings.musicOn = !settings.musicOn,
        ),
      ],
    ),
    DropMenuSection(
      title: s.menuPainting,
      items: [
        DropMenuItem(
          icon: Icons.drive_file_rename_outline_rounded,
          label: s.rename,
          onSelected: onRename,
        ),
        DropMenuItem(
          icon: Icons.delete_outline_rounded,
          label: s.deletePainting,
          danger: true,
          enabled: hasPainting,
          onSelected: onDelete,
        ),
      ],
    ),
    DropMenuSection(
      items: [
        DropMenuItem(
          icon: Icons.settings_rounded,
          label: s.navSettings,
          onSelected: onSettings,
        ),
      ],
    ),
  ]);
}

/// Asks for one of the soft papers; null if none was picked.
Future<Color?> pickPaperColor(BuildContext context, Color current) {
  final s = S.of(context);
  return showDialog<Color>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(s.paperColor),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (i, paper) in AppTheme.papers.indexed)
                PaperChoice(
                  color: paper,
                  label: s.paperNames[i],
                  selected: paper.toARGB32() == current.toARGB32(),
                  onTap: () => Navigator.pop(context, paper),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Asks before clearing the whole paper.
Future<bool> confirmClear(BuildContext context) async {
  final s = S.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.clearTitle),
      content: Text(s.clearBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(s.confirm),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Asks before deleting the open painting.
Future<bool> confirmDeletePainting(BuildContext context) async {
  final s = S.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.deleteTitle),
      content: Text(s.deleteBody),
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
  return ok == true;
}
