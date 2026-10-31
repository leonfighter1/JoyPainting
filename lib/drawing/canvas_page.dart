import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show PointerHoverEvent, PointerScrollEvent;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../l10n.dart';
import '../painting_session.dart';
import '../settings.dart';
import '../share/photo_import.dart';
import '../share/share_actions.dart';
import '../theme/cute_theme.dart';
import '../widgets/corner_float.dart';
import '../widgets/name_dialog.dart';
import '../widgets/press_bounce.dart';
import 'canvas/canvas_keys.dart';
import 'canvas/canvas_menu.dart';
import 'canvas/canvas_view.dart';
import 'canvas/color_widgets.dart';
import 'canvas/floating_controls.dart';
import 'canvas/layer_panel.dart';
import 'canvas/overlay_painter.dart';
import 'canvas/paper_resizer.dart';
import 'canvas/paper_view.dart';
import 'canvas/picker_loupe.dart';
import 'canvas/selection_controller.dart';
import 'canvas/selection_widgets.dart';
import 'canvas/shortcuts.dart';
import 'canvas/tool_drawer.dart';
import 'canvas/tools/canvas_tool.dart';
import 'canvas/tools/draw_tool.dart';
import 'canvas/tools/fill_tool.dart';
import 'canvas/tools/move_tool.dart';
import 'canvas/tools/pan_tool.dart';
import 'canvas/tools/picker_tool.dart';
import 'canvas/tools/text_tool.dart';
import 'drawing_controller.dart';
import 'render/layer_cache.dart';
import 'replay/replay_page.dart';
import 'render/pixel_sampler.dart';
import 'stroke.dart';

export 'canvas/canvas_keys.dart';
export 'canvas/canvas_view.dart' show PaperLayout, zoomOf;
export 'canvas/overlay_painter.dart'
    show CanvasOverlayPainter, SelectionFrame, SelectionFrameHandles;

class CanvasPage extends StatefulWidget {
  const CanvasPage({
    super.key,
    required this.session,
    required this.settings,
    required this.onOpenSettings,
  });

  final PaintingSession session;
  final AppSettings settings;

  /// Opens the settings page (from the ☰ menu).
  final VoidCallback onOpenSettings;

  @override
  State<CanvasPage> createState() => CanvasPageState();
}

class CanvasPageState extends State<CanvasPage> with TickerProviderStateMixin {
  int? _activePointer;

  /// Where to show the eraser's range circle, or null to hide it. Shown
  /// after a long press while erasing, or while a mouse/stylus hovers.
  final _eraserCursor = ValueNotifier<Offset?>(null);
  static const longPressDelay = DrawTool.longPressDelay;

  /// The finished drawing kept as a picture, so a big painting isn't
  /// painted again for every new stroke or eraser move. A painting just
  /// opened is put on the paper a slice per frame.
  final layerCache = LayeredCache(sliced: true);

  /// Pixels per paper point [layerCache] is kept at: what the screen shows
  /// at the current zoom step.
  final _cacheRatio = ValueNotifier<double>(1);

  /// A picture was still being decoded when the kept pictures were made:
  /// make them again.
  void _onPhotoDecoded() => layerCache.dispose();

  /// Measured from the view and layout, never while building.
  void _updateCacheRatio() {
    if (!mounted) return;
    _cacheRatio.value = cacheRatioFor(
      MediaQuery.devicePixelRatioOf(context),
      _view.layout.scale,
      _view.zoom,
    );
  }

  /// The tools drawer: 0 = hidden, 1 = fully slid in.
  late final AnimationController _tools = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 240),
  )..addStatusListener((_) => setState(() {}));

  /// How the paper is zoomed and panned on screen.
  late final _view = CanvasViewController(vsync: this)
    ..onPinchStart = _onPinchStart;
  ValueNotifier<Matrix4> get view => _view.view;
  static const minZoom = CanvasViewController.minZoom;
  static const maxZoom = CanvasViewController.maxZoom;
  String? _viewFor;

  DrawingController get _drawing => widget.session.drawing;
  AppSettings get _settings => widget.settings;
  bool get _erasing => _settings.brush == BrushType.eraser;
  bool get _toolsShown => _tools.status != AnimationStatus.dismissed;

  @override
  void initState() {
    super.initState();
    _viewFor = widget.session.id;
    widget.session.addListener(_onSessionChanged);
    layerCache.paintInSlices(widget.session.paperProgress);
    _settings.addListener(_onSettingsChanged);
    panMode.addListener(_updatePanning);
    HardwareKeyboard.instance.addHandler(_onKey);
    _drawing.addListener(_selection.keepDrawnOnly);
    selectionFrame.addListener(_scheduleBarAnchor);
    _selection.moving.addListener(_onMovingChanged);
    view.addListener(_scheduleBarAnchor);
    view.addListener(_updateCacheRatio);
    Photos.decoded.addListener(_onPhotoDecoded);
    _selection.syncWithBrush();
    if (_settings.brush != BrushType.picker) {
      _brushBeforePicker = _settings.brush;
    }
  }

  /// A different painting starts at the whole-paper view, and is put on
  /// the paper a slice per frame if it's big, its progress shown. Done
  /// here, not while building, because changing the view rebuilds other
  /// widgets.
  void _onSessionChanged() {
    if (_viewFor == widget.session.id) return;
    _viewFor = widget.session.id;
    _view.jumpToStart();
    layerCache.paintInSlices(widget.session.paperProgress);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    _settings.removeListener(_onSettingsChanged);
    HardwareKeyboard.instance.removeHandler(_onKey);
    panMode.dispose();
    _panning.dispose();
    _drawing.removeListener(_selection.keepDrawnOnly);
    _selection.dispose();
    _barAnchor.dispose();
    _drawTool.dispose();
    _eraserCursor.dispose();
    _loupe.dispose();
    _fillTool.dispose();
    Photos.decoded.removeListener(_onPhotoDecoded);
    _cacheRatio.dispose();
    layerCache.dispose();
    _tools.dispose();
    _resizer.dispose();
    _view.dispose();
    super.dispose();
  }

  // --- Tools drawer -------------------------------------------------------

  /// Respects the system "remove animations" setting.
  bool get _animate => !MediaQuery.disableAnimationsOf(context);

  void _openTools() => _animate ? _tools.forward() : _tools.value = 1;
  void _closeTools() => _animate ? _tools.reverse() : _tools.value = 0;

  // --- Zoom and pan -------------------------------------------------------

  void _onFrameDown(PointerDownEvent e) => _view.fingerDown(
    e.pointer,
    e.localPosition,
    e.position,
    onPaper: _activePointer == e.pointer,
  );

  void _onFrameMove(PointerMoveEvent e) =>
      _view.fingerMove(e.pointer, e.localPosition, e.position);

  void _onFrameUp(PointerEvent e) => _view.fingerUp(e.pointer);

  /// A second finger landed. The first finger may already have started a
  /// stroke; a pinch isn't drawing, so drop it.
  void _onPinchStart() {
    _tool?.cancel();
    _tool = null;
    _activePointer = null;
  }

  /// The view's zoom factor (see [zoomOf]).
  static double zoomLevel(Matrix4 m) => zoomOf(m);

  /// Zooms around the middle of the paper area (Ctrl + and Ctrl −).
  void zoomCenter(double factor) => _view.zoomCenter(factor);

  /// Back to the whole paper on screen.
  void resetView() => _view.reset();

  /// Zooms so the paper shows at its real size, from its top-left corner.
  void showActualSize() => _view.showActualSize();

  /// Where a paper of [size] sits in [room] before zooming.
  static PaperLayout fitPaper(Size room, Size size) =>
      CanvasViewController.fitPaper(room, size);

  // --- Resizing the paper ---------------------------------------------------

  late final _resizer = PaperResizer(
    drawing: _drawing,
    view: _view,
    paperSize: () => widget.session.canvasSize,
    busy: () => _activePointer != null || _view.pinching,
  );

  // --- Moving the paper (拖动画板) ----------------------------------------

  /// The ✋ button: while on, one finger or the mouse moves the paper
  /// instead of drawing (handy on big papers, and with a mouse, which
  /// can't do a two-finger drag).
  final panMode = ValueNotifier<bool>(false);

  /// Whether a drag moves the paper now: the ✋ button, or the space bar
  /// held down (as in drawing programs on computers).
  final _panning = ValueNotifier<bool>(false);
  bool _spaceHeld = false;

  void _updatePanning() => _panning.value = panMode.value || _spaceHeld;

  // --- Keyboard shortcuts ---------------------------------------------------

  /// Whether keys are for this page: the paper is the tab showing (the tab
  /// stack keeps hidden tabs built, but invisible) and no dialog or sheet
  /// is on top.
  bool get _keysForMe =>
      mounted &&
      Visibility.of(context) &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  bool _onKey(KeyEvent e) {
    // Keys typed into a text field are for the text.
    final typing = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<EditableText>();
    if (typing != null) return false;
    if (e.logicalKey == LogicalKeyboardKey.space) {
      _spaceHeld = e is! KeyUpEvent;
      _updatePanning();
      return false;
    }
    if (e is KeyUpEvent || !_keysForMe) return false;
    final command = commandFor(e, hasSelection: !_selection.isEmpty);
    // Handled keys return true, which also stops the browser's own action
    // (Ctrl+S would otherwise save the web page, Ctrl+P print it).
    return command != null && _run(command);
  }

  /// Carries out a keyboard shortcut; false if there was nothing to do.
  bool _run(CanvasCommand command) {
    switch (command) {
      case CanvasCommand.undo:
        _drawing.undo();
      case CanvasCommand.redo:
        _drawing.redo();
      case CanvasCommand.zoomIn:
        zoomCenter(1.25);
      case CanvasCommand.zoomOut:
        zoomCenter(0.8);
      case CanvasCommand.fitView:
        resetView();
      case CanvasCommand.actualSize:
        showActualSize();
      case CanvasCommand.save:
        if (_hasPainting) _savePainting();
      case CanvasCommand.print:
        printPainting(context, widget.session.currentDoc());
      case CanvasCommand.selectAll:
        _selection.selectAll();
      case CanvasCommand.paste:
        _selection.paste();
      case CanvasCommand.copy:
        _selection.copy();
      case CanvasCommand.cut:
        _selection.cut();
      case CanvasCommand.duplicate:
        _selection.duplicate();
      case CanvasCommand.deleteSelection:
        _selection.delete();
      case CanvasCommand.smallerBrush || CanvasCommand.biggerBrush:
        final step = command == CanvasCommand.smallerBrush ? -2 : 2;
        _settings.size = (_settings.size + step).clamp(1, 60).toDouble();
      case CanvasCommand.showShortcuts:
        showShortcutsDialog(context);
      case CanvasCommand.escape:
        // One thing at a time: the selection, then the tools, then ✋.
        if (!_selection.isEmpty) {
          _selection.clear();
        } else if (_toolsShown) {
          _closeTools();
        } else if (panMode.value) {
          panMode.value = false;
        } else {
          return false;
        }
      case CanvasCommand.togglePan:
        panMode.value = !panMode.value;
      case CanvasCommand.pen:
        _settings.brush = BrushType.pen;
      case CanvasCommand.eraser:
        _settings.brush = BrushType.eraser;
      case CanvasCommand.text:
        _settings.brush = BrushType.text;
      case CanvasCommand.move:
        _settings.brush = BrushType.move;
      case CanvasCommand.turnRight || CanvasCommand.turnLeft:
        if (!_settings.level.rotation) return false;
        _view.rotateCenter(
          (command == CanvasCommand.turnRight ? 1 : -1) * math.pi / 12,
        );
      case CanvasCommand.picker:
        if (!_settings.level.allows(BrushType.picker)) return false;
        _settings.brush = BrushType.picker;
    }
    return true;
  }

  /// The ⌘ key on Apple keyboards, Ctrl elsewhere.
  static String get commandKey => commandKeyLabel;

  // --- Tools on the paper -------------------------------------------------

  late final _drawTool = DrawTool(
    drawing: _drawing,
    settings: _settings,
    paperWidth: () => widget.session.canvasSize.width,
    eraserCursor: _eraserCursor,
  );
  late final _textTool = TextTool(
    drawing: _drawing,
    settings: _settings,
    context: () => context,
  );
  late final _moveTool = MoveTool(_selection);
  late final _panTool = PanTool(_view);
  late final _pickerTool = PickerTool(
    settings: _settings,
    sample: _samplePaper,
    loupe: _loupe,
    place: _onStage,
    returnTo: () => _brushBeforePicker,
  );

  late final _fillTool = FillTool(
    drawing: _drawing,
    settings: _settings,
    pixels: () {
      final size = widget.session.canvasSize;
      return paperPixels(
        size: size,
        paper: _drawing.paper,
        painter: (canvas) => _paintKept(canvas, size),
        // Browsers work it out on the screen's own thread: fewer pixels.
        maxSide: kIsWeb ? 1024 : 2048,
      );
    },
  );

  /// What the color picker's loupe shows.
  final _loupe = ValueNotifier<PickerLoupe?>(null);

  /// The brush the picker goes back to.
  BrushType _brushBeforePicker = BrushType.pen;

  /// The color seen at [at] on the paper, read from the kept pictures.
  Future<PaperSample> _samplePaper(Offset at) {
    final size = widget.session.canvasSize;
    return PaperSampler.sample(
      at,
      size: size,
      paper: _drawing.paper,
      painter: (canvas) => _paintKept(canvas, size),
    );
  }

  /// Every shown layer, from the kept pictures (as on screen).
  void _paintKept(Canvas canvas, Size size) => layerCache.paint(
    canvas,
    size,
    _drawing.strokes,
    _drawing.layers,
    _drawing.paper,
    _cacheRatio.value,
  );

  /// A screen position in the canvas stack's coordinates.
  Offset _onStage(Offset global) {
    final stack = _stackKey.currentContext?.findRenderObject();
    return stack is RenderBox ? stack.globalToLocal(global) : global;
  }

  /// The tool that has the current touch, picked when it started.
  CanvasTool? _tool;

  CanvasTool get _toolForTouch {
    if (_panning.value) return _panTool;
    // Alt + click picks a color with any tool, on a computer.
    if (HardwareKeyboard.instance.isAltPressed &&
        _settings.level.allows(BrushType.picker)) {
      return _pickerTool;
    }
    return switch (_settings.brush) {
      BrushType.text => _textTool,
      BrushType.move => _moveTool,
      BrushType.picker => _pickerTool,
      BrushType.bucket => _fillTool,
      _ => _drawTool,
    };
  }

  void _onDown(PointerDownEvent e) {
    // Ignore extra fingers here: a second finger starts a pinch (handled by
    // the frame listener), and nothing draws until every finger lifts.
    if (_activePointer != null || _view.pinching) return;
    final tool = _toolForTouch;
    _activePointer = e.pointer;
    // Nothing goes onto a hidden or locked layer; say why. The touch stays
    // taken, so it doesn't move the paper either.
    if (!_drawing.canDrawOnActive &&
        (tool == _drawTool || tool == _textTool || tool == _fillTool)) {
      _tool = null;
      _explainLayer();
      return;
    }
    (_tool = tool).down(ToolPointer(e));
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _activePointer || _view.pinching) return;
    _tool?.move(ToolPointer(e));
  }

  void _onUp(PointerEvent e) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    _tool?.up(ToolPointer(e));
    _tool = null;
  }

  // --- Layers --------------------------------------------------------------

  /// How big the tools button is, so the layers button can sit right above
  /// (or below) it when they share a corner.
  Size? _launcherSize;

  Future<void> _openLayers() {
    final size = widget.session.canvasSize;
    return showLayerSheet(
      context,
      drawing: _drawing,
      paperSize: size,
      thumbnail: (id) => layerCache.imageOf(id, _drawing.strokesOn(id), size),
    );
  }

  void _explainLayer() {
    final s = S.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _drawing.active.visible ? s.layerLocked : s.layerHidden,
          ),
        ),
      );
  }

  // --- Move tool: select, move, resize, turn ------------------------------

  late final _selection = SelectionController(
    drawing: _drawing,
    settings: _settings,
  );

  /// The strokes the move tool has selected, outlined on the paper.
  ValueNotifier<List<Stroke>> get selected => _selection.selected;

  /// The dashed box around [selected], with its resize and turn handles.
  ValueNotifier<SelectionFrame?> get selectionFrame => _selection.frame;

  /// The box being dragged out over empty paper to select several strokes.
  ValueNotifier<Rect?> get selectionBox => _selection.box;

  /// The selection bar hides while a finger moves the selection; it comes
  /// back when the finger lifts.
  void _onMovingChanged() {
    if (!_selection.moving.value) _scheduleBarAnchor();
  }

  /// Where the selection is on screen (in the canvas stack's coordinates),
  /// so the selection bar can sit next to it. Null while a finger is moving
  /// the selection, which hides the bar.
  final _barAnchor = ValueNotifier<Rect?>(null);
  final _stackKey = GlobalKey();
  final _paperBoxKey = GlobalKey();
  bool _anchorScheduled = false;

  /// Measured after the next layout, when the paper's place on screen is
  /// known (never during build).
  void _scheduleBarAnchor() {
    if (_anchorScheduled) return;
    _anchorScheduled = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        _anchorScheduled = false;
        if (mounted) _updateBarAnchor();
      })
      ..ensureVisualUpdate();
  }

  void _updateBarAnchor() {
    final f = selectionFrame.value;
    final paper = _paperBoxKey.currentContext?.findRenderObject();
    final stack = _stackKey.currentContext?.findRenderObject();
    _barAnchor.value =
        f == null ||
            _selection.moving.value ||
            paper is! RenderBox ||
            stack is! RenderBox
        ? null
        : selectionAnchor(f, paper, stack);
  }

  /// Rebuilds the floating controls (their corners and the brush they show)
  /// and keeps the move tool's selection in step with the brush.
  void _onSettingsChanged() {
    _selection.syncWithBrush();
    if (_settings.brush != BrushType.picker) {
      _brushBeforePicker = _settings.brush;
    }
    setState(() {});
  }

  /// A mouse or stylus hovering with the eraser previews its range too.
  void _onHover(PointerHoverEvent e) {
    _eraserCursor.value = _erasing ? e.localPosition : null;
  }

  Future<void> _pickColor() async {
    final picked = await showAppColorPicker(context, _settings.color);
    if (picked != null) {
      _settings
        ..color = picked
        ..addCustomColor(picked);
    }
  }

  Future<void> _pickPaper() async {
    final picked = await pickPaperColor(context, _drawing.paper);
    if (picked != null) {
      _drawing.setPaper(picked);
      _settings.paper = picked;
    }
  }

  /// A photo to trace, at the bottom: on its own locked, see-through
  /// layer where there are layers; otherwise see-through at the bottom of
  /// the drawing, where the move tool can move, resize or fade it.
  Future<void> _importPhoto() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await pickPhotoBytes();
    if (bytes == null) return;
    final paper = widget.session.canvasSize;
    final photo = await photoFromBytes(bytes, paper * 0.9);
    if (photo == null) {
      messenger.showSnackBar(SnackBar(content: Text(s.photoUnreadable)));
      return;
    }
    final topLeft = paper.center(Offset.zero) - photo.size.center(Offset.zero);
    if (_settings.level.layers &&
        _drawing.layers.length < PaintingLayer.maxLayers) {
      final id = 'photo${DateTime.now().millisecondsSinceEpoch}';
      _drawing.addUnder(
        Stroke.photo(topLeft: topLeft, photo: photo, layer: id),
        newLayer: PaintingLayer(
          id: id,
          name: s.photoLayer,
          opacity: 0.5,
          locked: true,
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(s.photoAddedOnLayer)));
    } else {
      _drawing.addUnder(
        Stroke.photo(
          topLeft: topLeft,
          photo: photo,
          opacity: 0.5,
          layer: _drawing.newStrokeLayer,
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(s.photoAdded)));
    }
  }

  Future<void> _confirmClear() async {
    if (await confirmClear(context)) _drawing.clear();
  }

  /// Whether there's a painting worth saving or deleting (not a blank,
  /// never-saved page).
  bool get _hasPainting =>
      _drawing.strokes.isNotEmpty || widget.session.isSaved;

  /// The ☰ menu.
  Future<void> _openMenu() => showCanvasMenu(
    context,
    session: widget.session,
    settings: _settings,
    panMode: panMode,
    hasPainting: _hasPainting,
    onReplay: () => showReplay(context, widget.session.currentDoc()),
    onShortcuts: () => showShortcutsDialog(context),
    onPaperColor: _pickPaper,
    onImportPhoto: _settings.level.photos ? _importPhoto : null,
    onDefaultPaperSize: () {
      _drawing.setPaperSize(null);
      resetView();
    },
    onNew: _newPainting,
    onRename: _renamePainting,
    onDelete: _confirmDeletePainting,
    onSettings: widget.onOpenSettings,
  );

  Future<void> _renamePainting() async {
    final s = S.of(context);
    final name = await showNameDialog(
      context,
      title: s.renameTitle,
      initial: widget.session.name,
    );
    if (name != null) await widget.session.rename(widget.session.id, name);
  }

  /// Saves right now (autosave would too, a moment later) and says so.
  Future<void> _savePainting() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // A failure is already reported by the session's onSaveError.
    if (await widget.session.save()) {
      messenger.showSnackBar(SnackBar(content: Text(s.paintingSaved)));
    }
  }

  Future<void> _confirmDeletePainting() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirmDeletePainting(context)) return;
    await widget.session.delete(widget.session.id);
    messenger.showSnackBar(SnackBar(content: Text(s.paintingDeleted)));
  }

  Future<void> _newPainting() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (await widget.session.newPainting()) {
      messenger.showSnackBar(SnackBar(content: Text(s.newPaintingStarted)));
    }
  }

  /// The brush in use before the move tool was picked at the top.
  BrushType? _beforeMove;

  /// The 选择移动 button: picks the move tool, or goes back to the brush.
  void _toggleMove() {
    if (_settings.brush == BrushType.move) {
      _settings.brush = _beforeMove ?? BrushType.pen;
    } else {
      _beforeMove = _settings.brush;
      _settings.brush = BrushType.move;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    _view.animate = _animate;
    _view.rotates = _settings.level.rotation;
    return Scaffold(
      appBar: GradientAppBar(
        // The kid's board, and the open painting's name (tap to rename).
        title: ListenableBuilder(
          listenable: widget.session,
          builder: (context, _) => AppLogoTitle(
            text: s.boardTitle(_settings.kidName),
            subtitle: widget.session.name,
            onTap: _renamePainting,
            tapLabel: s.rename,
          ),
        ),
        actions: [
          CanvasBarActions(
            changes: Listenable.merge([_drawing, widget.session, _settings]),
            settings: _settings,
            canClear: () => _drawing.strokes.isNotEmpty,
            panMode: panMode,
            onMove: _toggleMove,
            onClear: _confirmClear,
            onMenu: _openMenu,
          ),
        ],
      ),
      // While the tools drawer is open, Back closes it instead of leaving.
      body: PopScope(
        canPop: !_toolsShown,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeTools();
        },
        child: LayoutBuilder(
          builder: (context, outer) {
            // A pinned palette sits beside the paper instead of sliding over it.
            final locked = _settings.paletteLocked;
            // An upright phone has no room for the whole palette beside the
            // paper: a one-row strip sits below it instead, and "More" still
            // slides the full drawer in.
            final strip = locked && outer.maxWidth < 600;
            final stage = LayoutBuilder(
              builder: (context, box) {
                final drawerWidth = math.min(
                  drawerMaxWidth,
                  box.maxWidth * 0.88,
                );
                final slide = CurvedAnimation(
                  parent: _tools,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                final area = box.biggest;
                final margin = EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  16 + MediaQuery.paddingOf(context).bottom,
                );
                // The drawer opens from the side the tools button is on.
                final fromLeft = _settings.toolsCorner.isLeft;
                final layers = _settings.level.layers;
                return Stack(
                  key: _stackKey,
                  children: [
                    Positioned.fill(child: _buildPaper(s, cute)),
                    Positioned.fill(child: PickerLoupeView(loupe: _loupe)),
                    // A fill can take a moment on a big painting. Positioned
                    // even when hidden: a non-positioned child would size
                    // the whole stack.
                    Positioned(
                      top: 8,
                      left: 16,
                      right: 16,
                      child: ValueListenableBuilder(
                        valueListenable: _fillTool.busy,
                        builder: (context, busy, _) => busy
                            ? LinearProgressIndicator(semanticsLabel: s.filling)
                            : const SizedBox.shrink(),
                      ),
                    ),
                    // Centered at the top, clear of every corner.
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ZoomChip(view: view, onReset: resetView),
                      ),
                    ),
                    // What the move tool can do with the selection, right next to
                    // it (and under the corner controls, which stay usable).
                    if (_settings.brush == BrushType.move)
                      Positioned.fill(
                        child: ValueListenableBuilder(
                          valueListenable: _barAnchor,
                          builder: (context, anchor, bar) => anchor == null
                              ? const SizedBox.shrink()
                              : CustomSingleChildLayout(
                                  delegate: NextToSelection(anchor),
                                  child: bar,
                                ),
                          child: SelectionBar(
                            selected: selected,
                            hide: slide,
                            actions: selectionActions(
                              s,
                              _selection,
                              onStyle: () => showSelectionStyleSheet(
                                context,
                                _selection,
                                _settings,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Undo/redo, the tools button and the layers button can
                    // each be dragged to any corner. Undo/redo never shares
                    // one; the layers button sits above (or below) the tools
                    // button when they share one.
                    CornerFloat(
                      key: undoFloatKey,
                      corner: _settings.undoCorner,
                      blocked: {
                        _settings.toolsCorner,
                        if (layers) _settings.layersCorner,
                      },
                      area: area,
                      margin: margin,
                      onCornerChanged: (c) => _settings.undoCorner = c,
                      child: UndoRedoBar(drawing: _drawing, hide: slide),
                    ),
                    if (layers)
                      CornerFloat(
                        key: layersFloatKey,
                        corner: _settings.layersCorner,
                        blocked: {_settings.undoCorner},
                        area: area,
                        margin: margin,
                        stackOver: (c) => !locked && c == _settings.toolsCorner
                            ? (_launcherSize?.height ?? 56) + 10
                            : 0,
                        onCornerChanged: (c) => _settings.layersCorner = c,
                        child: LayersButton(
                          drawing: _drawing,
                          hide: slide,
                          onOpen: _openLayers,
                        ).bouncy(),
                      ),
                    if (!locked)
                      CornerFloat(
                        key: toolsFloatKey,
                        corner: _settings.toolsCorner,
                        blocked: {_settings.undoCorner},
                        area: area,
                        margin: margin,
                        onSize: (size) => setState(() => _launcherSize = size),
                        onCornerChanged: (c) => _settings.toolsCorner = c,
                        child: ToolsLauncher(
                          key: toolsButtonKey,
                          settings: _settings,
                          fromLeft: fromLeft,
                          // Fades and shrinks away as the drawer slides in.
                          hide: slide,
                          onTap: _openTools,
                        ).bouncy(),
                      ),
                    if ((!locked || strip) && _toolsShown)
                      Positioned.fill(
                        child: SlidingToolDrawer(
                          progress: _tools,
                          slide: slide,
                          width: drawerWidth,
                          settings: _settings,
                          pinned: locked,
                          onOpen: _openTools,
                          onClose: _closeTools,
                          onTogglePin: _togglePaletteLock,
                          onMoreColors: _pickColor,
                        ),
                      ),
                  ],
                );
              },
            );
            if (!locked) return stage;
            return PinnedPaletteLayout(
              stage: stage,
              availableWidth: outer.maxWidth,
              maxPanelWidth: drawerMaxWidth,
              panelKey: dockedPaletteKey,
              settings: _settings,
              onUnpin: _togglePaletteLock,
              onMore: _openTools,
              onMoreColors: _pickColor,
            );
          },
        ),
      ),
    );
  }

  /// Pins the palette beside the paper, or lets it slide away again.
  void _togglePaletteLock() {
    _settings.paletteLocked = !_settings.paletteLocked;
    // The docked panel replaces the sliding one, and the other way round.
    _tools.value = 0;
  }

  static const dockedPaletteKey = CanvasKeys.dockedPalette;
  static const drawerMaxWidth = 360.0;

  /// Finds the tools button and the drawer's scrolling list in tests.
  static const toolsButtonKey = CanvasKeys.toolsButton;
  static const toolsFloatKey = CanvasKeys.toolsFloat;
  static const undoFloatKey = CanvasKeys.undoFloat;
  static const layersFloatKey = CanvasKeys.layersFloat;
  static const toolsListKey = CanvasKeys.toolsList;
  static const selectionBarKey = CanvasKeys.selectionBar;

  /// The paper, like a sketchbook sheet, inside a zoomable view, with grips
  /// on its right and bottom edges to make it wider or taller.
  ///
  /// A painting has its own paper size once its grips are dragged; until
  /// then the paper fills the space available, but is never smaller than
  /// what's already drawn. A paper bigger than the space is scaled down to
  /// fit (see [fitPaper]). FittedBox and the zoom Transform both map touches
  /// back to paper coordinates, so drawing lands under the finger at any
  /// scale.
  Widget _buildPaper(S s, CuteTheme cute) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: ListenableBuilder(
        // An opened painting brings its own content and paper size.
        listenable: Listenable.merge([
          widget.session,
          _drawing.paperSizeListenable,
          _resizer.held,
          _panning,
        ]),
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final room = constraints.biggest;
            _view.room = room;
            final drawn = _drawing.contentBounds;
            final size =
                _drawing.paperSize ??
                Size(
                  math.max(room.width, drawn.right),
                  math.max(room.height, drawn.bottom),
                );
            widget.session.canvasSize = size;
            final layout = _view.layout =
                _resizer.held.value ?? fitPaper(room, size);
            // The cache follows the paper's scale on screen, after this frame.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _updateCacheRatio(),
            );
            final sheet = PaperSheet(
              size: size,
              layout: layout,
              drawing: _drawing,
              cache: layerCache,
              cacheRatio: _cacheRatio,
              overlay: CanvasOverlayPainter(
                settings: _settings,
                eraserCursor: _eraserCursor,
                selected: selected,
                frame: selectionFrame,
                selectionBox: selectionBox,
                accent: cute.spec.primary,
                ink: cute.ink,
              ),
              panning: _panning.value,
              repaintKey: _paperBoxKey,
              onDown: _onDown,
              onMove: _onMove,
              onUp: _onUp,
              onHover: _onHover,
              onExit: () => _eraserCursor.value = null,
            );
            final paper = ClipRect(
              child: Listener(
                // Sees every finger (in screen-area coordinates) to detect
                // pinches; the paper's own listener below does the drawing.
                onPointerDown: _onFrameDown,
                onPointerMove: _onFrameMove,
                onPointerUp: _onFrameUp,
                onPointerCancel: _onFrameUp,
                onPointerSignal: (e) {
                  if (e is PointerScrollEvent) {
                    _view.zoomAt(
                      e.localPosition,
                      math.exp(-e.scrollDelta.dy / 400),
                    );
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: ValueListenableBuilder(
                  valueListenable: view,
                  builder: (context, matrix, child) =>
                      Transform(key: zoomKey, transform: matrix, child: child),
                  child: sheet,
                ),
              ),
            );
            return Stack(
              children: [
                Positioned.fill(child: paper),
                // On top, outside the zoom: always the same size on screen.
                ValueListenableBuilder(
                  valueListenable: view,
                  // Grips sit on an upright paper's edges; none while turned.
                  builder: (context, matrix, _) =>
                      rotationOf(matrix).abs() > 0.001
                      ? const SizedBox.shrink()
                      : PaperGrips(
                          room: room,
                          paperRect: MatrixUtils.transformRect(
                            matrix,
                            layout.corner & size * layout.scale,
                          ),
                          paperSize: size,
                          floats: {
                            _settings.toolsCorner,
                            _settings.undoCorner,
                            if (_settings.level.layers) _settings.layersCorner,
                          },
                          onDown: _resizer.start,
                          onMove: _resizer.move,
                          onUp: _resizer.end,
                          onStep: _resizer.step,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Finds the zoom transform in tests.
  static const zoomKey = CanvasKeys.zoom;

  /// Finds the paper in tests.
  static const paperKey = CanvasKeys.paper;
}
