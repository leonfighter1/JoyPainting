import 'package:flutter/widgets.dart';

/// Keys that tests use to find parts of the drawing screen.
abstract final class CanvasKeys {
  static const paper = Key('paper');
  static const zoom = Key('zoom');
  static const dockedPalette = Key('dockedPalette');

  /// The tools button and the drawer's scrolling list.
  static const toolsButton = Key('toolsButton');
  static const toolsFloat = Key('toolsFloat');
  static const undoFloat = Key('undoFloat');
  static const toolsList = Key('toolsList');
  static const selectionBar = Key('selectionBar');
}
