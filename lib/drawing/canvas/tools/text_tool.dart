import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../settings.dart';
import '../../drawing_controller.dart';
import '../../stroke.dart';
import '../../text_editor.dart';
import '../color_widgets.dart';
import '../selection_controller.dart';
import 'canvas_tool.dart';

/// The text tool: a tap adds text (or edits the text tapped), and dragging
/// text moves it.
class TextTool extends CanvasTool {
  TextTool({
    required this.drawing,
    required this.settings,
    required this.context,
  });

  final DrawingController drawing;
  final AppSettings settings;

  /// Where the text editor opens.
  final BuildContext Function() context;

  /// The current touch: the text under the finger (if any), where the
  /// finger went down, and the moved copy while dragging.
  ({Stroke? hit, Offset down, Stroke? dragged})? _gesture;

  @override
  void down(ToolPointer p) {
    _gesture = (hit: drawing.hitText(p.at), down: p.at, dragged: null);
  }

  @override
  void move(ToolPointer p) {
    final g = _gesture;
    final hit = g?.hit;
    if (g == null || hit == null) return;
    final delta = p.at - g.down;
    if (g.dragged == null && delta.distance < SelectionController.dragSlop) {
      return;
    }
    final moved = hit.moved(delta);
    // Only the first step records undo, so a whole drag undoes at once.
    drawing.replace(g.dragged ?? hit, moved, recordUndo: g.dragged == null);
    _gesture = (hit: hit, down: g.down, dragged: moved);
  }

  @override
  void up(ToolPointer p) {
    final g = _gesture;
    _gesture = null;
    // A tap (not a drag, not a cancelled touch) adds or edits text.
    if (g == null || p.cancelled || g.dragged != null) return;
    g.hit != null ? editText(g.hit!) : addText(g.down);
  }

  @override
  void cancel() => _gesture = null;

  Future<void> addText(Offset at) async {
    final style =
        (settings.textStyle ??
                TextContent(fontFamily: fontById(settings.fontId.value).family))
            .copyWith(fontSize: settings.size * BrushType.text.sizeFactor);
    final result = await showTextEditor(
      context(),
      initial: style,
      color: settings.color,
      palette: AppPalette.colors,
    );
    if (result?.content case final content?) {
      _remember(content, result!.color!);
      drawing.add(
        Stroke.text(
          anchor: at,
          content: content,
          color: result.color!,
          opacity: settings.opacity,
          layer: drawing.newStrokeLayer,
        ),
      );
    }
  }

  Future<void> editText(Stroke item) async {
    final result = await showTextEditor(
      context(),
      initial: item.text!,
      color: item.color,
      palette: AppPalette.colors,
      editing: true,
    );
    if (result == null) return;
    if (result.delete) {
      drawing.remove(item);
    } else {
      _remember(result.content!, result.color!);
      drawing.replace(
        item,
        Stroke.text(
          anchor: item.anchor,
          content: result.content!,
          color: result.color!,
          opacity: item.opacity,
          transform: item.transform,
          layer: item.layer,
        ),
      );
    }
  }

  /// The next text starts with the same formatting, size and color.
  void _remember(TextContent content, Color color) {
    settings
      ..textStyle = content
      ..size = content.fontSize / BrushType.text.sizeFactor
      ..color = color;
  }
}
