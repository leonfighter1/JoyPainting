import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n.dart';

/// What a keyboard shortcut on the drawing screen does.
enum CanvasCommand {
  undo,
  redo,
  zoomIn,
  zoomOut,
  fitView,
  actualSize,
  save,
  print,
  selectAll,
  paste,
  copy,
  cut,
  duplicate,
  deleteSelection,
  smallerBrush,
  biggerBrush,
  showShortcuts,

  /// Closes one thing: the selection, then the tools, then ✋.
  escape,
  togglePan,
  pen,
  eraser,
  text,
  move,
  picker,
}

/// The command for a key press, or null if the key isn't a shortcut.
/// Copy, cut, duplicate and delete need [hasSelection]. Holding a key
/// down repeats undo, redo, zoom and the brush size; the rest act once
/// per press.
CanvasCommand? commandFor(KeyEvent e, {required bool hasSelection}) {
  final keys = HardwareKeyboard.instance;
  if (keys.isAltPressed) return null;
  final key = e.logicalKey;
  final repeat = e is KeyRepeatEvent;
  if (keys.isControlPressed || keys.isMetaPressed) {
    if (key == LogicalKeyboardKey.keyZ) {
      return keys.isShiftPressed ? CanvasCommand.redo : CanvasCommand.undo;
    }
    if (key == LogicalKeyboardKey.keyY) return CanvasCommand.redo;
    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      return CanvasCommand.zoomIn;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      return CanvasCommand.zoomOut;
    }
    if (repeat) return null;
    return switch (key) {
      LogicalKeyboardKey.digit0 || LogicalKeyboardKey.numpad0 =>
        CanvasCommand.fitView,
      LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 =>
        CanvasCommand.actualSize,
      LogicalKeyboardKey.keyS => CanvasCommand.save,
      LogicalKeyboardKey.keyP => CanvasCommand.print,
      LogicalKeyboardKey.keyA => CanvasCommand.selectAll,
      LogicalKeyboardKey.keyV => CanvasCommand.paste,
      // Copying needs something selected; otherwise the key is left alone.
      LogicalKeyboardKey.keyC when hasSelection => CanvasCommand.copy,
      LogicalKeyboardKey.keyX when hasSelection => CanvasCommand.cut,
      LogicalKeyboardKey.keyD when hasSelection => CanvasCommand.duplicate,
      _ => null,
    };
  }

  if (key == LogicalKeyboardKey.bracketLeft) return CanvasCommand.smallerBrush;
  if (key == LogicalKeyboardKey.bracketRight) return CanvasCommand.biggerBrush;
  if (repeat) return null;
  if (e.character == '?') return CanvasCommand.showShortcuts;
  if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
    return hasSelection ? CanvasCommand.deleteSelection : null;
  }
  if (key == LogicalKeyboardKey.escape) return CanvasCommand.escape;
  if (key == LogicalKeyboardKey.keyH) return CanvasCommand.togglePan;
  return switch (e.character?.toLowerCase()) {
    'p' => CanvasCommand.pen,
    'e' => CanvasCommand.eraser,
    't' => CanvasCommand.text,
    'v' || 'm' => CanvasCommand.move,
    'i' => CanvasCommand.picker,
    _ => null,
  };
}

/// The ⌘ key on Apple keyboards, Ctrl elsewhere.
String get commandKeyLabel =>
    defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? '⌘'
        : 'Ctrl';

/// The list of keyboard shortcuts (the ? key, or the ☰ menu).
Future<void> showShortcutsDialog(BuildContext context) {
  final s = S.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(s.keyboardShortcuts),
        content: SingleChildScrollView(
          child: Table(
            columnWidths: const {0: IntrinsicColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              for (final (keys, what) in s.shortcuts(commandKeyLabel))
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 16, 4),
                    child: Text(
                      keys,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(what),
                ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.confirm),
          ),
        ],
      );
    },
  );
}
