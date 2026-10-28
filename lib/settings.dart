import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drawing/brush_preset.dart';
import 'drawing/stroke.dart';
import 'skill_level.dart';
import 'widgets/corner_float.dart';

/// One child using the app. Each kid has their own paintings.
@immutable
class Kid {
  const Kid(this.id, this.name);

  final String id;
  final String name;

  /// The first kid keeps the storage paintings had before kids existed.
  static const firstId = 'main';

  /// Put before each of this kid's stored item names (see
  /// `PrefixedStoreBackend`).
  String get storePrefix => id == firstId ? '' : 'kid-$id-';

  Kid withName(String name) => Kid(id, name);

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  static Kid? fromJson(Object? json) => switch (json) {
    {'id': final String id, 'name': final String name} => Kid(id, name),
    _ => null,
  };
}

/// How background music moves on when a track ends.
enum MusicMode {
  /// The same track again and again.
  repeatOne,

  /// Every track in list order, then from the top.
  sequence,

  /// A random other track each time.
  shuffle;

  static MusicMode fromName(String? name) =>
      values.firstWhere((m) => m.name == name, orElse: () => shuffle);
}

/// User choices that survive app restarts: language, theme, brush, colors,
/// sizes, opacity, stamp shape, shapes and their look (fill, free shapes,
/// gradient, blend), mirror mode, paper, music and the kids.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs)
    : locale = ValueNotifier(
        Locale(_prefs.getString(_kLanguage) ?? _defaultLanguage(_prefs)),
      ),
      onboarded = ValueNotifier(_prefs.getBool(_kOnboarded) ?? false),
      themeId = ValueNotifier(_prefs.getString(_kTheme) ?? defaultThemeId),
      fontId = ValueNotifier(_prefs.getString(_kFont) ?? defaultFontId),
      textScale = ValueNotifier(
        (_prefs.getDouble(_kTextScale) ?? 1)
            .clamp(minTextScale, maxTextScale)
            .toDouble(),
      ),
      _shape = ShapeKind.fromName(_prefs.getString(_kShape)),
      _undoCorner = Corner.fromName(
        _prefs.getString(_kUndoCorner),
        Corner.topRight,
      ),
      _toolsCorner = Corner.fromName(
        _prefs.getString(_kToolsCorner),
        Corner.bottomRight,
      ),
      _fill = _prefs.getBool(_kFill) ?? false,
      _freeShape = _prefs.getBool(_kFreeShape) ?? false,
      _fillGap = (_prefs.getInt(_kFillGap) ?? defaultFillGap).clamp(
        0,
        maxFillGap,
      ),
      _gradient = GradientStyle.fromName(_prefs.getString(_kGradient)),
      _blend = StrokeBlend.fromName(_prefs.getString(_kBlend)),
      _texture = StrokeTexture.fromName(_prefs.getString(_kTexture)),
      _level = SkillLevel.fromName(_prefs.getString(_kLevel)),
      _brush = BrushType.fromName(_prefs.getString(_kBrush)),
      _color = Color(_prefs.getInt(_kColor) ?? Colors.black.toARGB32()),
      _stamp = StampShape.fromName(_prefs.getString(_kStamp)),
      _mirror = _prefs.getBool(_kMirror) ?? false,
      _paper = Color(_prefs.getInt(_kPaper) ?? 0xFFFFFFFF),
      _musicOn = _prefs.getBool(_kMusicOn) ?? false,
      _musicVolume = _prefs.getDouble(_kMusicVolume) ?? defaultMusicVolume,
      _musicTrack = _prefs.getString(_kMusicTrack) ?? defaultMusicTrack,
      _musicMode = MusicMode.fromName(_prefs.getString(_kMusicMode)),
      _kids = _readKids(_prefs),
      _currentKidId = _prefs.getString(_kCurrentKid) ?? Kid.firstId,
      _customColors = [
        for (final v in _prefs.getStringList(_kCustomColors) ?? const [])
          if (int.tryParse(v) case final int argb) Color(argb),
      ];

  static Future<AppSettings> load() async =>
      AppSettings(await SharedPreferences.getInstance());

  /// English for a new install. Versions before 2.1 were Chinese unless
  /// changed, so an existing install (any saved setting) stays Chinese.
  static String _defaultLanguage(SharedPreferences prefs) =>
      prefs.getKeys().isEmpty ? 'en' : 'zh';

  static List<Kid> _readKids(SharedPreferences prefs) {
    final raw = prefs.getString(_kKids);
    if (raw != null) {
      try {
        final kids = [
          for (final k in jsonDecode(raw) as List) ?Kid.fromJson(k),
        ];
        if (kids.isNotEmpty) return kids;
      } catch (_) {}
    }
    // This app was made for 靖瑶: an install from before kids existed keeps
    // her name, so the title stays the same.
    return [Kid(Kid.firstId, prefs.getKeys().isEmpty ? '' : '靖瑶')];
  }

  static const supportedLanguages = ['zh', 'en'];
  static const defaultThemeId = 'sakura';
  static const defaultFontId = 'kuaile';
  static const maxCustomColors = 8;
  static const minOpacity = 0.05;
  static const defaultMusicVolume = 0.4;
  static const defaultMusicTrack = 'builtin:sunny';

  static const _kLanguage = 'language';
  static const _kTheme = 'theme';
  static const _kFont = 'font';
  static const _kTextScale = 'textScale';
  static const _kShape = 'shape';
  static const _kFill = 'fill';
  static const _kFreeShape = 'freeShape';
  static const _kFillGap = 'fillGap';
  static const _kBackupReminders = 'backupReminders';
  static String _kBackup(String kid) => 'backup.$kid';
  static String _kBackupSnooze(String kid) => 'backupSnooze.$kid';
  static const _kGradient = 'gradient';
  static const _kBlend = 'blend';
  static const _kTexture = 'texture';
  static const _kLevel = 'level';
  static const _kTextStyle = 'textStyle';
  static const _kUndoCorner = 'undoCorner';
  static const _kToolsCorner = 'toolsCorner';
  static const _kLayersCorner = 'layersCorner';
  static String _kSection(String section) => 'toolSection.$section';
  static const _kAddedTools = 'addedTools';
  static const _kBrushPresets = 'brushPresets';
  static const _kBrush = 'brush';
  static const _kColor = 'color';
  static const _kStamp = 'stamp';
  static const _kMirror = 'mirror';
  static const _kPaper = 'paper';
  static const _kCustomColors = 'customColors';
  static const _kLastPainting = 'lastPaintingId';
  static const _kMusicOn = 'musicOn';
  static const _kMusicVolume = 'musicVolume';
  static const _kMusicTrack = 'musicTrack';
  static const _kMusicMode = 'musicMode';
  static const _kOnboarded = 'onboarded';
  static const _kKids = 'kids';
  static const _kCurrentKid = 'currentKid';
  static const _kPaletteLocked = 'paletteLocked';
  static String _kSize(BrushType b) => 'size.${b.name}';
  static String _kOpacity(BrushType b) => 'opacity.${b.name}';

  final SharedPreferences _prefs;

  /// Kept separate from the other settings so changing a brush doesn't
  /// rebuild the whole MaterialApp.
  final ValueNotifier<Locale> locale;
  final ValueNotifier<String> themeId;
  final ValueNotifier<String> fontId;

  /// How much bigger (or smaller) than usual all text in the app is, on
  /// top of the system's own text size.
  final ValueNotifier<double> textScale;
  static const minTextScale = 0.8;
  static const maxTextScale = 1.5;

  /// Whether the first-start setup (language, theme, name) is done.
  final ValueNotifier<bool> onboarded;

  set onboardingDone(bool value) {
    _prefs.setBool(_kOnboarded, value);
    onboarded.value = value;
  }

  List<Kid> _kids;
  String _currentKidId;

  List<Kid> get kids => List.unmodifiable(_kids);

  /// The kid whose paintings are shown.
  Kid get currentKid =>
      _kids.firstWhere((k) => k.id == _currentKidId, orElse: () => _kids.first);

  /// The current kid's name ("" when not given), shown in the title.
  String get kidName => currentKid.name;

  void _saveKids() =>
      _prefs.setString(_kKids, jsonEncode([for (final k in _kids) k.toJson()]));

  /// Switches to [id]'s paintings (see `Family`).
  set currentKidId(String id) {
    if (!_kids.any((k) => k.id == id) || id == _currentKidId) return;
    _currentKidId = id;
    _prefs.setString(_kCurrentKid, id);
    notifyListeners();
  }

  Kid addKid(String name) {
    final kid = Kid(
      DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name.trim(),
    );
    _kids.add(kid);
    _saveKids();
    notifyListeners();
    return kid;
  }

  void renameKid(String id, String name) {
    final i = _kids.indexWhere((k) => k.id == id);
    if (i < 0) return;
    _kids[i] = _kids[i].withName(name.trim());
    _saveKids();
    notifyListeners();
  }

  /// Removes [id] from the list (its paintings are deleted by `Family`).
  /// The last kid can't be removed; reset the app instead.
  void removeKid(String id) {
    if (_kids.length < 2) return;
    _kids.removeWhere((k) => k.id == id);
    _prefs.remove('$_kLastPainting.$id');
    _saveKids();
    if (_currentKidId == id) currentKidId = _kids.first.id;
    notifyListeners();
  }

  /// Forgets every setting and kid, as on a fresh install: English, the
  /// default theme, and the first-start setup again.
  Future<void> resetAll() async {
    await _prefs.clear();
    _shape = null;
    _fill = false;
    _freeShape = false;
    _gradient = GradientStyle.none;
    _fillGap = defaultFillGap;
    _blend = StrokeBlend.normal;
    _texture = StrokeTexture.none;
    _level = SkillLevel.beginner;
    _undoCorner = Corner.topRight;
    _toolsCorner = Corner.bottomRight;
    _brush = BrushType.pen;
    _color = Colors.black;
    _stamp = StampShape.heart;
    _mirror = false;
    _paper = const Color(0xFFFFFFFF);
    _musicOn = false;
    _musicVolume = defaultMusicVolume;
    _musicTrack = defaultMusicTrack;
    _musicMode = MusicMode.shuffle;
    _customColors.clear();
    _kids = [const Kid(Kid.firstId, '')];
    _currentKidId = Kid.firstId;
    locale.value = const Locale('en');
    themeId.value = defaultThemeId;
    fontId.value = defaultFontId;
    textScale.value = 1;
    onboarded.value = false;
    notifyListeners();
  }

  ShapeKind? _shape;
  bool _fill;
  bool _freeShape;
  int _fillGap;
  GradientStyle _gradient;
  StrokeBlend _blend;
  StrokeTexture _texture;
  SkillLevel _level;
  Corner _undoCorner;
  Corner _toolsCorner;

  /// Where the floating undo/redo buttons sit (default: top right, for the
  /// right thumb).
  Corner get undoCorner => _undoCorner;

  /// Where the "画笔 · 颜色" button sits; the drawer opens from that side.
  Corner get toolsCorner => _toolsCorner;

  set undoCorner(Corner value) {
    _undoCorner = value;
    _prefs.setString(_kUndoCorner, value.name);
    notifyListeners();
  }

  set toolsCorner(Corner value) {
    _toolsCorner = value;
    _prefs.setString(_kToolsCorner, value.name);
    notifyListeners();
  }

  /// Where the layers button sits (advanced level). Until it's dragged, the
  /// tools button's corner: right next to it.
  Corner get layersCorner => switch (_prefs.getString(_kLayersCorner)) {
    final name? => Corner.fromName(name, _toolsCorner),
    null => _toolsCorner,
  };

  set layersCorner(Corner value) {
    _prefs.setString(_kLayersCorner, value.name);
    notifyListeners();
  }

  /// Whether the tools drawer's [section] is open; [byDefault] until it's
  /// opened or closed.
  bool sectionOpen(String section, {required bool byDefault}) =>
      _prefs.getBool(_kSection(section)) ?? byDefault;

  void setSectionOpen(String section, bool open) {
    _prefs.setBool(_kSection(section), open);
    notifyListeners();
  }

  /// The drawer options added with 添加工具, as `group.name` keys (see
  /// `ToolCatalog`). The basic ones always show, so they're not in it.
  Set<String> get addedTools => {...?_prefs.getStringList(_kAddedTools)};

  set addedTools(Set<String> value) {
    _prefs.setStringList(_kAddedTools, value.toList()..sort());
    notifyListeners();
  }

  /// 我的画笔: brushes saved with their settings, oldest first.
  List<BrushPreset> get brushPresets => [
        for (final raw in _prefs.getStringList(_kBrushPresets) ?? const [])
          ?_decodePreset(raw),
      ];

  static BrushPreset? _decodePreset(String raw) {
    try {
      return BrushPreset.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  set brushPresets(List<BrushPreset> value) {
    _prefs.setStringList(
        _kBrushPresets, [for (final p in value) jsonEncode(p.toJson())]);
    notifyListeners();
  }

  /// The brush in use with its settings, as [name] (see [brushPresets]).
  BrushPreset presetNow(String id, String name) => BrushPreset(
        id: id,
        name: name,
        brush: brush,
        size: size,
        opacity: opacity,
        color: color,
        gradient: gradient,
        blend: blend,
        texture: texture,
      );

  /// Picks [p]'s brush with its settings.
  void usePreset(BrushPreset p) {
    brush = p.brush;
    size = p.size;
    opacity = p.opacity;
    if (p.brush.usesColor) color = p.color;
    gradient = p.gradient;
    blend = p.blend;
    texture = p.texture;
  }

  /// Whether the brush in use is [p], with the same settings.
  bool isPreset(BrushPreset p) =>
      brush == p.brush &&
      (size - p.size).abs() < 0.01 &&
      (opacity - p.opacity).abs() < 0.01 &&
      (!p.brush.usesColor || color.toARGB32() == p.color.toARGB32()) &&
      gradient == p.gradient &&
      blend == p.blend &&
      texture == p.texture;

  BrushType _brush;
  Color _color;
  StampShape _stamp;
  bool _mirror;
  Color _paper;
  final List<Color> _customColors;

  /// The shape tool, or null for freehand drawing.
  ShapeKind? get shape => _shape;

  /// Whether closed shapes are drawn filled.
  bool get fill => _fill;

  /// Whether drawing makes free shapes: the area a line goes around is
  /// filled (see [Stroke.fill]). [shape] is null meanwhile.
  bool get freeShape => _level.freeShape && _freeShape;

  /// How big a gap (in paper points, about twice this) the paint bucket
  /// closes, so a shape that isn't quite closed fills without leaking.
  /// Beginners always get the default.
  int get fillGap => _level.freeShape ? _fillGap : defaultFillGap;

  /// Whether My Paintings reminds to back the paintings up (on by default).
  bool get backupReminders => _prefs.getBool(_kBackupReminders) ?? true;
  set backupReminders(bool value) {
    _prefs.setBool(_kBackupReminders, value);
    notifyListeners();
  }

  /// When the current kid's paintings were last all exported, or null.
  DateTime? get lastBackup => _time(_kBackup(currentKid.id));

  /// Until when the backup reminder is put off for the current kid.
  DateTime? get backupSnoozedUntil => _time(_kBackupSnooze(currentKid.id));

  DateTime? _time(String key) => switch (_prefs.getInt(key)) {
    final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
    _ => null,
  };

  /// All the current kid's paintings were exported at [when].
  void markBackedUp(DateTime when) {
    _prefs
      ..setInt(_kBackup(currentKid.id), when.millisecondsSinceEpoch)
      ..remove(_kBackupSnooze(currentKid.id));
    notifyListeners();
  }

  /// "Later": no reminder for the current kid until [until].
  void snoozeBackup(DateTime until) {
    _prefs.setInt(_kBackupSnooze(currentKid.id), until.millisecondsSinceEpoch);
    notifyListeners();
  }

  static const defaultFillGap = 2;
  static const maxFillGap = 6;

  /// The gradient new lines and shapes get from the chosen color.
  GradientStyle get gradient =>
      _level.gradients ? _gradient : GradientStyle.none;

  /// How new strokes mix with what's under them.
  StrokeBlend get blend => _level.lightAndShadow ? _blend : StrokeBlend.normal;

  /// The grain new strokes are painted with.
  StrokeTexture get texture => _level.textures ? _texture : StrokeTexture.none;

  /// The brush in use; one the [level] hides counts as the pen.
  BrushType get brush => _level.allows(_brush) ? _brush : BrushType.pen;
  Color get color => _color;
  StampShape get stamp => _stamp;
  bool get mirror => _mirror;

  /// Paper color for new paintings: the last one picked.
  Color get paper => _paper;
  List<Color> get customColors => List.unmodifiable(_customColors);

  /// Each brush remembers its own size and opacity.
  double get size => sizeFor(brush);
  double sizeFor(BrushType b) =>
      _prefs.getDouble(_kSize(b)) ??
      switch (b) {
        BrushType.pencil => 6,
        BrushType.text => 16,
        _ => 10,
      };
  double get opacity => _level.opacity ? opacityFor(brush) : 1;
  double opacityFor(BrushType b) => _prefs.getDouble(_kOpacity(b)) ?? 1;

  /// The painting the current kid last had open.
  String? get lastPaintingId => _prefs.getString(_lastPaintingKey);

  String get _lastPaintingKey => _currentKidId == Kid.firstId
      ? _kLastPainting
      : '$_kLastPainting.$_currentKidId';

  set language(String code) {
    if (!supportedLanguages.contains(code)) return;
    _prefs.setString(_kLanguage, code);
    locale.value = Locale(code);
  }

  set theme(String id) {
    _prefs.setString(_kTheme, id);
    themeId.value = id;
  }

  /// The formatting used for the last text added (its words are not kept),
  /// or null before any text was added.
  TextContent? get textStyle {
    final raw = _prefs.getString(_kTextStyle);
    if (raw == null) return null;
    try {
      return TextContent.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return null;
    }
  }

  set textStyle(TextContent value) => _prefs.setString(
    _kTextStyle,
    jsonEncode(value.copyWith(text: '').toJson()),
  );

  set font(String id) {
    _prefs.setString(_kFont, id);
    fontId.value = id;
  }

  set textSize(double value) {
    final v = value.clamp(minTextScale, maxTextScale).toDouble();
    _prefs.setDouble(_kTextScale, v);
    textScale.value = v;
  }

  set shape(ShapeKind? value) {
    _shape = value;
    _freeShape = false;
    _prefs.setBool(_kFreeShape, false);
    if (value == null) {
      _prefs.remove(_kShape);
    } else {
      _prefs.setString(_kShape, value.name);
    }
    notifyListeners();
  }

  set fill(bool value) {
    _fill = value;
    _prefs.setBool(_kFill, value);
    notifyListeners();
  }

  set freeShape(bool value) {
    if (value) shape = null;
    _freeShape = value;
    _prefs.setBool(_kFreeShape, value);
    notifyListeners();
  }

  set fillGap(int value) {
    _fillGap = value.clamp(0, maxFillGap);
    _prefs.setInt(_kFillGap, _fillGap);
    notifyListeners();
  }

  set gradient(GradientStyle value) {
    _gradient = value;
    _prefs.setString(_kGradient, value.name);
    notifyListeners();
  }

  set blend(StrokeBlend value) {
    _blend = value;
    _prefs.setString(_kBlend, value.name);
    notifyListeners();
  }

  set texture(StrokeTexture value) {
    _texture = value;
    _prefs.setString(_kTexture, value.name);
    notifyListeners();
  }

  /// Which tools the drawing screen shows. Options a level hides read as
  /// their plain defaults (no gradient, full opacity, ...) but are kept, so
  /// they come back with a higher level.
  SkillLevel get level => _level;
  set level(SkillLevel value) {
    _level = value;
    _prefs.setString(_kLevel, value.name);
    notifyListeners();
  }

  set brush(BrushType value) {
    _brush = value;
    _prefs.setString(_kBrush, value.name);
    notifyListeners();
  }

  set color(Color value) {
    _color = value;
    _prefs.setInt(_kColor, value.toARGB32());
    // Picking a color means the user wants to paint with it.
    if (!_brush.usesColor) brush = BrushType.pen;
    notifyListeners();
  }

  set size(double value) {
    _prefs.setDouble(_kSize(brush), value);
    notifyListeners();
  }

  set opacity(double value) {
    _prefs.setDouble(_kOpacity(brush), value.clamp(minOpacity, 1));
    notifyListeners();
  }

  set stamp(StampShape value) {
    _stamp = value;
    _prefs.setString(_kStamp, value.name);
    notifyListeners();
  }

  /// Whether the brushes-and-colors palette is pinned beside the paper
  /// instead of sliding in when needed.
  bool get paletteLocked => _prefs.getBool(_kPaletteLocked) ?? false;

  set paletteLocked(bool value) {
    _prefs.setBool(_kPaletteLocked, value);
    notifyListeners();
  }

  set mirror(bool value) {
    _mirror = value;
    _prefs.setBool(_kMirror, value);
    notifyListeners();
  }

  set paper(Color value) {
    _paper = value;
    _prefs.setInt(_kPaper, value.toARGB32());
    notifyListeners();
  }

  bool _musicOn;
  double _musicVolume;
  String _musicTrack;
  MusicMode _musicMode;

  /// What happens when a track ends.
  MusicMode get musicMode => _musicMode;

  set musicMode(MusicMode value) {
    _musicMode = value;
    _prefs.setString(_kMusicMode, value.name);
    notifyListeners();
  }

  /// Whether background music plays while the app is open.
  bool get musicOn => _musicOn;

  /// Background music volume, 0 to 1.
  double get musicVolume => _musicVolume;

  /// The background music track's id (see MusicLibrary).
  String get musicTrack => _musicTrack;

  set musicOn(bool value) {
    _musicOn = value;
    _prefs.setBool(_kMusicOn, value);
    notifyListeners();
  }

  set musicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
    _prefs.setDouble(_kMusicVolume, _musicVolume);
    notifyListeners();
  }

  set musicTrack(String id) {
    _musicTrack = id;
    _prefs.setString(_kMusicTrack, id);
    notifyListeners();
  }

  /// Whether the current kid has been given the sample painting for
  /// [level] (once each: deleting it doesn't bring it back). Before v4
  /// there was one sample, the beginner's.
  bool sampleAddedFor(SkillLevel level) => _samplesAdded.contains(level.name);

  void markSampleAdded(SkillLevel level) => _prefs.setStringList(
    _samplesKey,
    {..._samplesAdded, level.name}.toList(),
  );

  List<String> get _samplesAdded =>
      _prefs.getStringList(_samplesKey) ??
      [if (_prefs.getBool(_sampleKey) ?? false) SkillLevel.beginner.name];

  String get _sampleKey => _currentKidId == Kid.firstId
      ? 'sampleAdded'
      : 'sampleAdded.$_currentKidId';

  String get _samplesKey => _currentKidId == Kid.firstId
      ? 'samplesAdded'
      : 'samplesAdded.$_currentKidId';

  set lastPaintingId(String? id) {
    if (id == null) {
      _prefs.remove(_lastPaintingKey);
    } else {
      _prefs.setString(_lastPaintingKey, id);
    }
  }

  /// Remembers a color picked from the full picker, newest first.
  void addCustomColor(Color value) {
    _customColors
      ..removeWhere((c) => c.toARGB32() == value.toARGB32())
      ..insert(0, value);
    if (_customColors.length > maxCustomColors) _customColors.removeLast();
    _prefs.setStringList(_kCustomColors, [
      for (final c in _customColors) c.toARGB32().toString(),
    ]);
    notifyListeners();
  }

  @override
  void dispose() {
    locale.dispose();
    onboarded.dispose();
    themeId.dispose();
    fontId.dispose();
    textScale.dispose();
    super.dispose();
  }
}
