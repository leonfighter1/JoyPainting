import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'drawing/drawing_controller.dart';
import 'drawing/render/render_image.dart';
import 'drawing/stroke.dart';
import 'gallery/level_samples.dart';
import 'gallery/painting_archive.dart';
import 'gallery/painting_file.dart';
import 'gallery/painting_store.dart';
import 'l10n.dart';
import 'settings.dart';
import 'skill_level.dart';

/// Renders a thumbnail for the gallery. Swappable so widget tests can skip
/// real image encoding, which doesn't complete under fake async.
typedef Thumbnailer = Future<Uint8List> Function(
  List<Stroke> strokes,
  Size size,
  Color paper,
  List<PaintingLayer> layers,
);

/// Longest side of a gallery thumbnail, in pixels.
const thumbnailMaxSide = 360.0;

Future<Uint8List> renderThumbnail(
  List<Stroke> strokes,
  Size size,
  Color paper,
  List<PaintingLayer> layers,
) {
  final scale = thumbnailMaxSide / math.max(size.width, size.height);
  return renderPng(strokes, size, scale, paper: paper, layers: layers);
}

/// A painting being opened: its name (empty if not known yet) and how
/// much of the opening is done, 0 to 1.
@immutable
class OpeningProgress {
  const OpeningProgress(this.name, this.done);

  final String name;
  final double done;
}

/// The painting currently open on the canvas, and keeping it saved.
///
/// Every finished edit schedules an autosave; switching or creating a
/// painting saves first, so work is never silently dropped.
class PaintingSession extends ChangeNotifier {
  PaintingSession({
    required this.store,
    required this.settings,
    this.thumbnailer = renderThumbnail,
    this.autosaveDelay = const Duration(milliseconds: 800),
  }) : id = _newId(),
       createdAt = DateTime.now() {
    drawing.paper = settings.paper;
    drawing.addListener(_onDrawingChanged);
  }

  /// The current kid's paintings (see [switchStore]).
  PaintingStore store;
  final AppSettings settings;
  final Thumbnailer thumbnailer;
  final Duration autosaveDelay;
  final drawing = DrawingController();

  String id;
  DateTime createdAt;

  /// The open painting's name, like "My painting 1".
  String name = '';

  /// The open painting's paper size, in canvas units: set by the canvas on
  /// every layout to the space available, but never smaller than what's
  /// drawn (see `CanvasPage`). An opened painting starts at its saved size.
  Size canvasSize = Size.zero;

  /// Called when an autosave fails, so the UI can tell the user.
  void Function(Object error)? onSaveError;

  int _savedRevision = 0;

  /// Whether this painting exists in the store yet. Untouched new paintings
  /// aren't saved, so the gallery doesn't fill up with blank pages.
  bool _persisted = false;
  Timer? _autosave;

  bool get hasUnsavedChanges => drawing.revision != _savedRevision;

  /// Whether this painting is in My Paintings yet.
  bool get isSaved => _persisted;

  static int _lastId = 0;

  /// Time-based ids, forced to increase: the clock can return the same
  /// microsecond twice, and a repeated id would overwrite another painting.
  static String _newId() {
    _lastId = math.max(DateTime.now().microsecondsSinceEpoch, _lastId + 1);
    return _lastId.toString();
  }

  /// Reopens the painting that was open when the app last closed, or names
  /// the blank page if there's none. Also numbers paintings saved before
  /// v2.1, which have no names.
  Future<void> restoreLast() async {
    await store.nameUnnamed(_s.defaultPaintingName);
    final lastId = settings.lastPaintingId;
    if (lastId != null) {
      try {
        final doc = await _load(lastId, '');
        if (doc != null) {
          _show(doc);
          return;
        }
      } catch (e) {
        debugPrint('Could not reopen painting $lastId: $e');
      }
    }
    name = await _nextName();
    notifyListeners();
  }

  /// Texts in the app's language, for default names.
  S get _s => S(settings.locale.value.languageCode);

  /// "My painting N" for the first N not taken yet, counting on from how
  /// many paintings there are.
  Future<String> _nextName() async {
    final paintings = await store.list();
    final taken = {for (final m in paintings) m.name};
    var n = paintings.length + 1;
    while (taken.contains(_s.defaultPaintingName(n))) {
      n++;
    }
    return _s.defaultPaintingName(n);
  }

  /// Renames a painting (the open one, or one in the gallery). Blank names
  /// are ignored.
  Future<void> rename(String paintingId, String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty) return;
    if (paintingId == id) {
      name = clean;
      notifyListeners();
      // A blank page isn't stored yet; it keeps the name for its first save.
      if (!_persisted) return;
    }
    await store.rename(paintingId, clean);
  }

  /// Saves the open painting and switches to another kid's paintings,
  /// reopening the one that kid last had open. With `saveFirst: false` the
  /// open painting is dropped (the app is being reset).
  Future<bool> switchStore(PaintingStore other, {bool saveFirst = true}) async {
    _autosave?.cancel();
    if (saveFirst && !await save()) return false;
    await _lastSave;
    store = other;
    _reset(_newId(), DateTime.now(), const [], settings.paper);
    _persisted = false;
    await restoreLast();
    notifyListeners();
    return true;
  }

  void _onDrawingChanged() {
    if (!hasUnsavedChanges) return;
    _autosave?.cancel();
    _autosave = Timer(autosaveDelay, save);
  }

  /// Saves now if anything changed. Safe to call any time.
  ///
  /// Returns false if saving failed, so callers about to leave this
  /// painting can stop instead of losing work.
  Future<bool> save() => _lastSave = _save();

  /// The most recent save, so [delete] can wait for it rather than have it
  /// finish afterwards and bring the deleted painting back.
  Future<bool> _lastSave = Future.value(true);

  Future<bool> _save() async {
    _autosave?.cancel();
    if (!hasUnsavedChanges) return true;
    final revision = drawing.revision;
    if (drawing.strokes.isEmpty && !_persisted) {
      _savedRevision = revision;
      return true;
    }
    // Snapshot first: the user may keep drawing while this save runs.
    final strokes = List<Stroke>.of(drawing.strokes);
    final paper = drawing.paper;
    final paperSize = drawing.paperSize;
    final layers = drawing.layers;
    final size =
        paperSize ?? (canvasSize.isEmpty ? _boundsOf(strokes) : canvasSize);
    final paintingId = id;
    if (name.isEmpty) name = await _nextName();
    final paintingName = name;
    try {
      final thumbnail = await thumbnailer(strokes, size, paper, layers);
      await store.save(
        PaintingDoc(
          meta: PaintingMeta(
            id: paintingId,
            name: paintingName,
            createdAt: createdAt,
            updatedAt: DateTime.now(),
            width: size.width,
            height: size.height,
            strokeCount: strokes.length,
          ),
          strokes: strokes,
          paper: paper,
          paperSize: paperSize,
          layers: layers,
        ),
        thumbnail,
      );
      // Only mark saved if the user is still on the same painting.
      if (paintingId == id) {
        _savedRevision = revision;
        _persisted = true;
        settings.lastPaintingId = id;
      }
      return true;
    } catch (e) {
      debugPrint('Autosave failed: $e');
      onSaveError?.call(e);
      return false;
    }
  }

  /// Saves the current painting and starts a blank one.
  /// Returns false (and stays put) if the current painting couldn't be saved.
  Future<bool> newPainting() async {
    if (!await save()) return false;
    _reset(_newId(), DateTime.now(), const [], settings.paper);
    _persisted = false;
    settings.lastPaintingId = null;
    name = await _nextName();
    notifyListeners();
    return true;
  }

  /// The open painting as a document, for sending or printing.
  PaintingDoc currentDoc() {
    final strokes = List<Stroke>.of(drawing.strokes);
    final size =
        drawing.paperSize ??
        (canvasSize.isEmpty ? _boundsOf(strokes) : canvasSize);
    return PaintingDoc(
      meta: PaintingMeta(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        width: size.width,
        height: size.height,
        strokeCount: strokes.length,
      ),
      strokes: strokes,
      paper: drawing.paper,
      paperSize: drawing.paperSize,
      layers: drawing.layers,
    );
  }

  /// Adds a `.jypaint` file someone sent as a new painting and opens it.
  /// It gets a fresh id, so it never overwrites an existing painting.
  /// Returns false if [bytes] isn't a painting file or saving failed.
  Future<bool> importPainting(Uint8List bytes) async {
    final PaintingDoc incoming;
    try {
      incoming = PaintingFile.decode(bytes);
    } on FormatException catch (e) {
      debugPrint('Import rejected: $e');
      return false;
    }
    return openCopyOf(incoming);
  }

  /// Saves the open painting, then adds a copy of [doc] as a new painting
  /// (a fresh id) and opens it: an imported file, a coloring page.
  Future<bool> openCopyOf(PaintingDoc doc) async {
    if (!await save()) return false;
    final copy = await _addCopy(doc);
    if (copy == null) return false;
    _show(copy);
    return true;
  }

  /// Adds every painting in a `.zip` (see [PaintingArchive]) to My
  /// Paintings, without opening any. Returns how many were added: 0 if
  /// [bytes] isn't a zip or holds no paintings.
  Future<int> importArchive(Uint8List bytes) async {
    final List<PaintingDoc> incoming;
    try {
      incoming = PaintingArchive.decode(bytes);
    } on FormatException catch (e) {
      debugPrint('Import rejected: $e');
      return 0;
    }
    if (incoming.isEmpty || !await save()) return 0;
    var added = 0;
    for (final doc in incoming) {
      if (await _addCopy(doc) != null) added++;
    }
    return added;
  }

  /// Puts [level]'s sample painting (see [LevelSamples]) into the current
  /// kid's My Paintings, without opening it: only when the kid picks it,
  /// never by itself. Returns it, or null if it couldn't be added (or one
  /// is still being added).
  Future<PaintingDoc?> addSample(SkillLevel level) async {
    if (makingSample.value != null) return null;
    makingSample.value = LevelSamples.name(level, _s);
    try {
      return await _addCopy(
        await LevelSamples.load(level, _s),
        thumbnail: await LevelSamples.thumbnail(level),
      );
    } catch (e) {
      debugPrint('Sample painting not added: $e');
      return null;
    } finally {
      makingSample.value = null;
    }
  }

  /// [level]'s sample as a small picture, for choosing one.
  Future<Uint8List> samplePreview(SkillLevel level) async {
    if (await LevelSamples.thumbnail(level) case final made?) return made;
    final doc = await LevelSamples.load(level, _s);
    return thumbnailer(doc.strokes, doc.paperSize!, doc.paper, doc.layers);
  }

  /// The name of the sample painting being added (it can take a moment on
  /// a big one), or null.
  final makingSample = ValueNotifier<String?>(null);

  /// Adds a copy of [paintingId] named [name], next to it in My Paintings
  /// (the open one is saved first, so the copy has everything). Returns the
  /// copy, or null if it couldn't be made.
  Future<PaintingDoc?> duplicate(String paintingId, String name) async {
    final PaintingDoc? doc;
    if (paintingId == id) {
      if (!await save()) return null;
      doc = currentDoc();
    } else {
      doc = await store.load(paintingId);
    }
    if (doc == null) return null;
    return _addCopy(
      PaintingDoc(
        meta: PaintingMeta(
          id: '',
          name: name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          width: doc.meta.width,
          height: doc.meta.height,
          strokeCount: doc.strokes.length,
        ),
        strokes: doc.strokes,
        paper: doc.paper,
        paperSize: doc.paperSize,
        layers: doc.layers,
      ),
    );
  }

  /// Stores [incoming] as a new painting (fresh id, its own name or the
  /// next free "My painting N"). Null if saving failed.
  Future<PaintingDoc?> _addCopy(
    PaintingDoc incoming, {
    Uint8List? thumbnail,
  }) async {
    final copy = PaintingDoc(
      meta: PaintingMeta(
        id: _newId(),
        name: incoming.meta.name.isNotEmpty
            ? incoming.meta.name
            : await _nextName(),
        createdAt: incoming.meta.createdAt,
        updatedAt: DateTime.now(),
        width: incoming.meta.width,
        height: incoming.meta.height,
        strokeCount: incoming.strokes.length,
      ),
      strokes: incoming.strokes,
      paper: incoming.paper,
      paperSize: incoming.paperSize,
      layers: incoming.layers,
    );
    try {
      final size = Size(copy.meta.width, copy.meta.height);
      await store.save(
        copy,
        thumbnail ??
            await thumbnailer(
              copy.strokes,
              size.isEmpty ? _boundsOf(copy.strokes) : size,
              copy.paper,
              copy.layers,
            ),
      );
      return copy;
    } catch (e) {
      onSaveError?.call(e);
      return null;
    }
  }

  /// Saves the current painting and opens [paintingId] (called [name])
  /// from the store, showing [opening] while a big one takes a while.
  /// Returns false if saving the current one or loading the new one failed.
  Future<bool> open(String paintingId, {String name = ''}) async {
    if (paintingId == id) return true;
    if (!await save()) return false;
    final doc = await _load(paintingId, name);
    if (doc == null) return false;
    _show(doc);
    return true;
  }

  /// The painting being opened, which takes a moment when it's big: its
  /// name and how much is done, or null. Reading it is the first part;
  /// the canvas putting it on the paper (see [paperProgress]) the rest.
  final opening = ValueNotifier<OpeningProgress?>(null);

  /// The part of [opening] that reading the painting takes, when it's read
  /// in steps.
  static const _readShare = 0.4;

  /// Whether the painting being opened was read in steps.
  bool _readInSteps = false;

  /// Whether a painting is being read now.
  bool _reading = false;

  Future<PaintingDoc?> _load(String paintingId, String name) async {
    _readInSteps = false;
    _reading = true;
    try {
      final doc = await store.load(paintingId, onProgress: (done) {
        _readInSteps = true;
        opening.value = OpeningProgress(name, done * _readShare);
      });
      if (doc == null) opening.value = null;
      return doc;
    } catch (_) {
      opening.value = null;
      rethrow;
    } finally {
      _reading = false;
    }
  }

  /// Told by the canvas how much of the open painting it has put on the
  /// paper ([done], 0 to 1) while a big one is painted a slice per frame,
  /// and null once it's all there.
  void paperProgress(double? done) {
    // About the painting before the one being read.
    if (_reading) return;
    if (done == null) {
      opening.value = null;
      _readInSteps = false;
      return;
    }
    final start = _readInSteps ? _readShare : 0.0;
    opening.value = OpeningProgress(name, start + (1 - start) * done);
  }

  Future<void> delete(String paintingId) async {
    if (paintingId == id) {
      // Discard instead of saving: the user asked for it to be gone.
      _reset(_newId(), DateTime.now(), const [], settings.paper);
      _persisted = false;
      settings.lastPaintingId = null;
      notifyListeners();
    }
    await _lastSave;
    await store.delete(paintingId);
    if (paintingId != id && !_persisted && name.isEmpty) {
      name = await _nextName();
      notifyListeners();
    }
  }

  void _show(PaintingDoc doc) {
    _reset(
      doc.meta.id,
      doc.meta.createdAt,
      doc.strokes,
      doc.paper,
      size: doc.paperSize ?? Size(doc.meta.width, doc.meta.height),
      paperSize: doc.paperSize,
      layers: doc.layers,
    );
    name = doc.meta.name;
    _persisted = true;
    settings.lastPaintingId = id;
    // Read in steps: the canvas takes it from here.
    if (_readInSteps) opening.value = OpeningProgress(name, _readShare);
    notifyListeners();
  }

  /// [size] is the painting's paper size; empty means "take whatever the
  /// canvas has room for", as for a new painting.
  void _reset(
    String newId,
    DateTime created,
    List<Stroke> strokes,
    Color paper, {
    Size size = Size.zero,
    Size? paperSize,
    List<PaintingLayer> layers = const [PaintingLayer.base],
  }) {
    id = newId;
    name = '';
    createdAt = created;
    canvasSize = size.isEmpty ? Size.zero : size;
    drawing.load(strokes, paper: paper, paperSize: paperSize, layers: layers);
    _savedRevision = drawing.revision;
    // Loading notifies listeners, which schedules an autosave; nothing
    // changed yet, so drop it.
    _autosave?.cancel();
  }

  static Size _boundsOf(List<Stroke> strokes) {
    var w = 1.0, h = 1.0;
    for (final s in strokes) {
      for (final p in s.points) {
        w = math.max(w, p.x + s.size);
        h = math.max(h, p.y + s.size);
      }
    }
    return Size(w, h);
  }

  @override
  void dispose() {
    _autosave?.cancel();
    drawing.dispose();
    makingSample.dispose();
    opening.dispose();
    super.dispose();
  }
}
