import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'drawing/canvas_page.dart';
import 'family.dart';
import 'gallery/gallery_page.dart';
import 'gallery/sample_progress_card.dart';
import 'gallery/store_backend.dart';
import 'l10n.dart';
import 'music/background_music.dart';
import 'music/music_files.dart';
import 'music/music_library.dart';
import 'onboarding_page.dart';
import 'painting_session.dart';
import 'settings.dart';
import 'settings_page.dart';
import 'share/import_actions.dart';
import 'share/incoming_files.dart';
import 'theme/cute_theme.dart';
import 'theme/theme_spec.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  final settings = await AppSettings.load();
  final themes = await ThemeSpec.loadAll(kThemeIds);
  final backend = createStoreBackend();
  final session = PaintingSession(
    store: Family.storeFor(backend, settings.currentKid),
    settings: settings,
  );
  await session.restoreLast();
  final music = MusicLibrary(createMusicFiles());
  await music.load();
  final family = Family(
    settings: settings,
    backend: backend,
    session: session,
    music: music,
  );
  final player = BackgroundMusic(
    settings: settings,
    library: music,
    engine: AudioPlayersEngine(),
  )..start();
  runApp(
    PaintApp(
      settings: settings,
      session: session,
      themes: themes,
      music: music,
      family: family,
      player: player,
    ),
  );
}

/// Lists the bundled fonts' licenses on Flutter's licenses page, as the
/// SIL Open Font License asks.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final font in kFonts) {
      if (font.licenseAsset case final asset?) {
        yield LicenseEntryWithLineBreaks([
          font.family!,
        ], await rootBundle.loadString(asset));
      }
    }
  });
}

class PaintApp extends StatelessWidget {
  PaintApp({
    super.key,
    required this.settings,
    required this.session,
    required this.themes,
    required this.music,
    required this.family,
    this.player,
  });

  final AppSettings settings;
  final PaintingSession session;
  final List<ThemeSpec> themes;
  final MusicLibrary music;
  final Family family;

  /// Plays the background music; null in tests that don't need it.
  final BackgroundMusic? player;

  /// Built themes, one per theme and font combination actually used.
  final Map<(String, String), ThemeData> _cache = {};

  ThemeData _theme(String themeId, String fontId) =>
      _cache.putIfAbsent((themeId, fontId), () {
        // An unknown saved theme id (say, a removed theme) falls back to the
        // first bundled one.
        final spec = themes.firstWhere(
          (t) => t.id == themeId,
          orElse: () => themes.first,
        );
        return CuteTheme.build(spec, fontFamily: fontById(fontId).family);
      });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        settings.locale,
        settings.themeId,
        settings.fontId,
        settings.textScale,
        settings.onboarded,
      ]),
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => S.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: _theme(settings.themeId.value, settings.fontId.value),
        locale: settings.locale.value,
        supportedLocales: [
          for (final code in AppSettings.supportedLanguages) Locale(code),
        ],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Browsers only allow sound after a touch or click; the first one
        // starts music that was switched on. A mouse counts when its button
        // goes down, a finger or pen only when it lifts.
        // Text is scaled by the size picked in Settings, on top of the
        // system's own text size.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(context).scale(16) /
                  16 *
                  settings.textScale.value,
            ),
          ),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) {
              if (e.kind == PointerDeviceKind.mouse) player?.userTouched();
            },
            onPointerUp: (e) {
              if (e.kind != PointerDeviceKind.mouse) player?.userTouched();
            },
            child: child,
          ),
        ),
        // A new install (or a reset) starts with the setup page.
        home: settings.onboarded.value
            ? HomeShell(
                settings: settings,
                session: session,
                themes: themes,
                music: music,
                family: family,
                player: player,
              )
            : OnboardingPage(settings: settings, themes: themes),
      ),
    );
  }
}

/// The three main screens behind a colorful bottom navigation bar.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.settings,
    required this.session,
    required this.themes,
    required this.music,
    required this.family,
    this.player,
  });

  final AppSettings settings;
  final PaintingSession session;
  final List<ThemeSpec> themes;
  final MusicLibrary music;
  final Family family;
  final BackgroundMusic? player;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.session
      ..onSaveError = _showSaveError
      ..makingSample.addListener(_onMakingSample)
      ..opening.addListener(_onOpening);
    widget.player?.onError = _showMusicError;
    // After the first frame, so the snackbar and translations are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      IncomingFiles.listen(_openIncoming);
    });
  }

  /// Says a sample painting is being added while it is: a big one takes a
  /// moment.
  OverlayEntry? _sampleProgress;

  void _onMakingSample() {
    _sampleProgress?.remove();
    _sampleProgress = null;
    final name = widget.session.makingSample.value;
    if (name == null || !mounted) return;
    _sampleProgress = OverlayEntry(
      builder: (_) => SampleProgressCard(name: name),
    );
    Overlay.of(context, rootOverlay: true).insert(_sampleProgress!);
  }

  /// Shows how far opening a big painting has got, from reading it to
  /// putting it on the paper.
  OverlayEntry? _openingCard;

  void _onOpening() {
    final busy = widget.session.opening.value != null;
    if (!mounted || busy == (_openingCard != null)) return;
    if (!busy) {
      _openingCard!.remove();
      _openingCard = null;
      return;
    }
    _openingCard = OverlayEntry(
      builder: (_) => ValueListenableBuilder(
        valueListenable: widget.session.opening,
        builder: (_, progress, _) => progress == null
            ? const SizedBox.shrink()
            : OpeningProgressCard(progress: progress),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_openingCard!);
  }

  /// A painting file opened from another app (Android "open with").
  Future<void> _openIncoming(Uint8List bytes) async {
    if (!mounted) return;
    await importBytes(
      ScaffoldMessenger.of(context),
      S.of(context),
      widget.session,
      bytes,
      () => _selectTab(0),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.session
      ..onSaveError = null
      ..makingSample.removeListener(_onMakingSample)
      ..opening.removeListener(_onOpening);
    _sampleProgress?.remove();
    _openingCard?.remove();
    widget.player?.onError = null;
    super.dispose();
  }

  /// Saves right away when the app goes to the background, since Android may
  /// kill it before the autosave timer fires.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) widget.session.save();
  }

  void _showMusicError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(S.of(context).musicPlayFailed)));
  }

  void _showSaveError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).autosaveFailed(error))),
    );
  }

  /// Screens at least this wide get a side navigation rail.
  static const railMinWidth = 600.0;

  void _openSettings() {
    widget.session.save();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          settings: widget.settings,
          themes: widget.themes,
          music: widget.music,
          family: widget.family,
        ),
      ),
    );
  }

  void _selectTab(int i) {
    // Leaving the canvas is a natural moment to save, so the gallery is
    // up to date when it opens.
    if (_tab == 0 && i != 0) widget.session.save();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    // Settings isn't a tab: it opens from the ⋮ menu, leaving the bar to
    // the two places you actually work in.
    final destinations = [
      (Icons.brush_outlined, Icons.brush_rounded, s.navCanvas),
      (Icons.photo_library_outlined, Icons.photo_library_rounded, s.navGallery),
    ];
    Color navColor(int i) => cute.nav[i % cute.nav.length];
    final pages = IndexedStack(
      index: _tab,
      children: [
        CanvasPage(
          session: widget.session,
          settings: widget.settings,
          onOpenSettings: _openSettings,
        ),
        GalleryPage(
          session: widget.session,
          onOpened: () => _selectTab(0),
          onOpenSettings: _openSettings,
        ),
      ],
    );
    final indicator = navColor(_tab)
        .withValues(alpha: ThemeSpec.navIndicatorAlpha);

    // Tablets and turned phones: tabs move to a side rail, leaving the full
    // height for the paper (Material's guidance for medium+ widths).
    if (MediaQuery.sizeOf(context).width >= railMinWidth) {
      return Scaffold(
        body: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(cute.radius),
              ),
              child: NavigationRail(
                selectedIndex: _tab,
                onDestinationSelected: _selectTab,
                indicatorColor: indicator,
                labelType: NavigationRailLabelType.all,
                groupAlignment: 0,
                destinations: [
                  for (final (i, (icon, selectedIcon, label))
                      in destinations.indexed)
                    NavigationRailDestination(
                      icon: Icon(icon, color: navColor(i)),
                      selectedIcon: Icon(
                        selectedIcon,
                        color: navColor(i),
                        size: 28,
                      ),
                      label: Text(label),
                    ),
                ],
              ),
            ),
            Expanded(child: pages),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages,
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(cute.radius)),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _selectTab,
          indicatorColor: indicator,
          height: 68,
          destinations: [
            for (final (i, (icon, selectedIcon, label)) in destinations.indexed)
              NavigationDestination(
                // Full-strength tab colors: theme tests check them for 3:1
                // contrast on the bar and on the selected pill.
                icon: Icon(icon, color: navColor(i)),
                selectedIcon: Icon(selectedIcon, color: navColor(i), size: 28),
                label: label,
              ),
          ],
        ),
      ),
    );
  }
}
