import '../selection_controller.dart';
import 'canvas_tool.dart';

/// The move tool: picks strokes up and moves, resizes or turns them, or
/// drags a box over empty paper to select several (see
/// [SelectionController.startMove]).
class MoveTool extends CanvasTool {
  MoveTool(this.selection);

  final SelectionController selection;

  @override
  void down(ToolPointer p) => selection.startMove(p.at);

  @override
  void move(ToolPointer p) => selection.continueMove(p.at);

  @override
  void up(ToolPointer p) => selection.endMove(cancelled: p.cancelled);

  @override
  void cancel() => selection.endMove(cancelled: true);
}
