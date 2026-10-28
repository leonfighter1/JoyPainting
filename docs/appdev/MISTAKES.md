# Mistakes and lessons: 靖瑶的画板 (JingyaoPaint)

## Rules (read before every task)
1. Create Flutter projects with every platform you'll debug on: `flutter create --platforms android,web,windows`.
2. Before using a plugin, check its supported platforms on pub.dev. Put Android/desktop-only plugins (like `gal`) behind a conditional import (`if (dart.library.js_interop)`).
3. On a Windows host, plugin builds need **Developer Mode** (for symlinks). Check it before promising a Windows desktop build.
4. Don't run `flutter run` as a background task for the user. It has no keyboard input, so hot reload can't be used. Let the user press F5 in VS Code. Use background runs only to confirm that the app starts.
5. When replacing template code, update `test/widget_test.dart` in the same step.
6. Fix type mismatches at the source. Never silence them with `as dynamic`.
7. Generated IDs must be guaranteed unique (time plus a counter that only goes up). Code that saves user data needs tests that create several items quickly.
8. Use `dart:convert`'s `utf8` for text encoding. Don't hand-roll encoders.
9. Any async save must finish (or be awaited) before a delete of the same item. Otherwise the save can bring the deleted item back.
10. Never hard-code text or icon colors (like `Colors.white`) on themed backgrounds. Derive them with `Contrast.bestOn` / `CuteTheme.onColor`, and keep the accessibility guideline tests passing for every theme.
11. Don't use overshooting curves (`easeOutBack`, `elasticOut`) on `AnimatedContainer`s that animate shadows or other values that must stay non-negative.
12. Any row that holds tappable chips or buttons must be at least 48px tall. `androidTapTargetGuideline` fails otherwise.
13. In widget tests, scroll to items in horizontal lists before tapping them (`ensureVisible`), and use `skipOffstage: false` when only checking that they exist.
14. Items far down a lazy list aren't built at all, so `skipOffstage: false` won't find them. Use `scrollUntilVisible`, and resolve the scrollable to an element first, because a finder relative to an item that scrolls away stops matching.
15. Run `textContrastGuideline` on a screen tall enough that no text is half-cut at a scroll edge. Clipped text gets measured against the background and fails falsely.
16. Tap chips and menu items by their widget (`widgetWithText(ChoiceChip, …)` or the `PopupMenuItem` ancestor), not by their inner text, to avoid "would not hit test" warnings.
17. Put VS Code launch configs in the folder VS Code actually has open. The repo's `C:\AIProjects\JingyaoPaint\.vscode\launch.json` covers opening the project itself; `C:\AIProjects\.vscode\launch.json` (outside the repo, `cwd: ${workspaceFolder}/JingyaoPaint`) covers opening the parent folder.
18. Use single-code-point emoji in UI text. Variation selectors (U+FE0F, as in ☁️ ❤️ ✏️) have no Noto font, so Flutter web logs "Could not find a set of Noto fonts". `theme_test` checks the theme emoji.
19. Install Android SDK packages with `cmdline-tools\latest\bin\android.exe --sdk=<sdk> sdk install "ndk;28.2.13676358"`, not `sdkmanager.bat`. The .bat splits arguments at `;`, so every package name fails ("Package ndk not found"). Gradle's automatic NDK install goes through the same .bat, so pre-install the NDK version Flutter asks for (`ndkVersion` in `FlutterExtension.kt`).
20. Unzip big archives with `unzip`/`tar`, not PowerShell 5.1 `Expand-Archive`, which failed on the command-line tools zip.
21. Save `.ps1` scripts that contain Chinese (or any non-ASCII) as UTF-8 **with BOM**. Windows PowerShell 5.1 reads BOM-less files as ANSI, and the script fails to parse.
22. In Git Bash, set `MSYS_NO_PATHCONV=1` before `adb push/shell` with device paths. Otherwise `/sdcard/...` is rewritten to `C:/Program Files/Git/sdcard/...` and the command fails.
23. Read a 2D zoom from the matrix's x-axis scale, never `getMaxScaleOnAxis()`.
24. Never change a notifier (ValueNotifier, setState on another widget) inside build or LayoutBuilder; react in a listener or a post-frame callback.
25. When a `Semantics` uses `excludeSemantics: true` around a button, give it the action (`onTap`) too, and test that the semantics node can be tapped.
26. If an emulator draws black, cold-boot it (`-no-snapshot-load`) before suspecting the app; launch from the launcher, not `am start` right after install.
27. In widget tests, leave Settings with `find.byType(BackButton)`, not `pageBack()`, which needs the English tooltip.
28. `num.clamp(lo, hi)` throws when `hi < lo`. When the upper bound is "space minus size", wrap it in `math.max(lo, …)`: on tiny screens with large text, a widget can be bigger than its area.
29. Hit-test strokes against the segments between points, not just the points: a quick swipe records few points far apart.
30. Floating controls must never cover handles the user has to grab. Anchor them next to what they act on, and test that the handle can still be dragged after the selection grows.
31. When scripting the emulator, wait for snackbars to go before tapping bottom controls; a snackbar covers them and every tap misses.
32. In Git Bash with `MSYS_NO_PATHCONV=1`, pass Windows paths (`C:/...`) to adb.exe for local files; `/c/...` is no longer translated.
33. Wrap section titles and other single-line labels in a Row with `Flexible`, and run the 360×640 large-text test in English, whose words are longer.
34. Files made by `flutter create` on Windows have CRLF line endings. Convert them to LF (or match `\r?\n`) before regex edits, and check every edit landed (list the plist keys afterwards).
35. When native code can't be compiled here (Swift on Windows), read the exact framework headers for the SDK revision in use before writing it, and say plainly that it hasn't been compiled until CI runs it.
36. In widget tests, `pump()` after `enterText` before tapping a button that the typing enables; the button turns on only in the next frame.
37. `scrollUntilVisible` stops as soon as the item is built, which can be below the screen (in the cache area). Call `ensureVisible` after it before tapping.
38. Don't infer what happened from a plugin's result without reading its code: `share_plus` on the web returns "unavailable" both after the share menu and after its download fallback.
39. A feature must change what the user sees. After an action whose effect could be invisible (a bigger paper fitted into the same screen), show the result and say how to use it.
40. In a browser, don't start audio before the user's first touch or click, and put a time limit on awaiting platform media calls: a refused start can stay pending forever. A touch counts when the finger lifts, a mouse click when pressed.
41. In `flutter test` output, a failure's details are printed before that test's `[E]` line, not after it.
42. `IndexedStack` keeps hidden children's tickers on; use `Visibility.of(context)` to know whether a page is showing.
43. Don't cover a curved edge with one very wide freehand stroke: perfect_freehand keeps outline points only about size × smoothing apart, so the edge turns into chords. Use several thin strokes or filled shapes, and check the edge in a zoomed crop.
44. Give dart:ui gradients stops whenever there are more than two colors; build even stops when a file or caller gives none.
45. A gradient stroke's see-through-ness comes from its gradient's colors, never from its base `color`'s alpha.
46. A `Semantics` with `onIncrease`/`onDecrease` and a `value` also needs `increasedValue` and `decreasedValue`, or Flutter asserts.
47. Controls on the paper's edge keep their whole touch area inside the paper area and clear of the floating buttons (the phone tools button is wide). Test them with a real drag from their center, which goes through hit testing.
48. Never feed a computed line number or variable into `sed` (or any scripted edit) without checking it isn't empty: an empty address runs the command on every line. Use the Edit tool for multi-line changes; if a file gets damaged, restore it from git and reapply your edits.
49. A texture takes paint away from a stroke, so whatever is behind it shows through. For an object that must stay opaque, paint it solid and add the grain as a separate layer on top.
50. Keep blending (the blender) inside a shape's edge (pull the outline in), or it mixes in the background and leaves a light halo around the shape.
51. Atmosphere layers (haze, glow) must follow the shape they belong to, not its bounding box, or a straight band shows where the box ends.
52. When ordering points around a center by angle, measure the angle from a reference direction, so the jump at ±180° never falls inside the run.
53. In widget tests, don't wrap calls on objects made in the test's fake-time zone in `tester.runAsync`: their futures wait for fake time that never comes. Asset loading works without it.
54. Test helpers that find widgets by Chinese labels fail in English tests; use the label for the test's language.
55. Adding a section near the top of a lazy settings or setup page pushes lower items out of the built range: tests must scroll to them (rule 37), and a short page can simply be non-lazy.
56. Before saying what is or isn't verified, or what this PC can do, read the newest DEVLOG entries first and check the machine itself (`flutter doctor -v`, `emulator -list-avds`); a "not verified" note in an older FEATURES entry may be stale. When something gets verified later, update the older note in the same step.
57. Never edit the project while a harness run is going in the background: it reads half-changed files and its result means nothing. Wait for it, or start editing only after it has finished.
58. Never pass a Windows path (`$TEMP`, `C:\...`) to `awk -v`: awk reads backslashes as escapes and the path breaks silently. Use a forward-slash path (`/tmp/...`) and read it with `ENVIRON["NAME"]`, then check the inserted text landed.
59. Release APKs are split per CPU type, which adds 4000 (x86_64), 2000 (arm64) or 1000 (armv7) to the version code. Build emulator APKs with `--split-per-abi` (or `tool\build_apk.ps1`); an unsplit APK has a lower code and fails to install over them as a downgrade.
60. Every child of the canvas stacks must stay positioned (`Positioned`, `Positioned.fill`, `CornerFloat`), even when it shows nothing: a `Stack` with loose constraints sizes itself to its non-positioned children, so a builder returning `SizedBox.shrink()` collapses the paper area to 0×0 (NaN layout). Wrap the builder in the `Positioned`, not the other way round.
61. When a new floating control goes on the paper, search the tests for strokes, drags and taps at fixed spots in its corner (on the 393×829 test phone too) and move them clear, so they don't land on the control.
62. Don't run `dart format` on a whole existing file: the repo isn't laid out by the current formatter, so it rewrites hundreds of untouched lines and buries the real change. Format only new files, and match the layout around an edit by hand.
63. Before changing how existing strokes paint, count how many strokes in the samples (and the local tarot cards) the change touches. If it would change approved art, put the new look behind a flag that only new strokes get.

## Log

### 2026-10-28: The formatter rewrote whole files; a texture fix nearly changed the samples
- **Symptom:** after `dart format` on six edited files, the diff showed 274 changed lines in `stroke.dart` and 522 in `v4_test.dart` for edits of a few lines each. And the first fix for thin textured lines (the grain fading on every thin stroke) would have changed 1,279 strokes of the approved 湖畔晨光 sample.
- **Root cause:** the files were written in the formatter's older layout, and the new formatter rewraps everything. The texture fix was tried on test lines before checking which existing paintings use thin textured strokes.
- **Fix:** kept the reformatting (no behavior change, analyze clean) and stopped formatting whole files; the texture fix only applies to strokes with `fadesGrain`, which new strokes get.
- **Rule:** 62, 63.

### 2026-10-28: Test strokes landed on the new layers button
- **Symptom:** five selection tests failed after the layers button was added (a stroke missing, a box selecting the wrong strokes).
- **Root cause:** the tests drew their third line at (250–330, 650) on the 393×829 test phone, exactly where the layers button now sits above the tools button; the drag went to the button, not the paper.
- **Fix:** the line moved to (230–310, 560), clear of the corner controls.
- **Rule:** 61.

### 2026-10-27: A hidden progress bar collapsed the paper to nothing
- **Symptom:** every canvas test failed with `'height == null || !height.isNaN'` in `PaperSheet`'s Stack, thousands of times per test (a full widget_test run hit the 10-minute limit).
- **Root cause:** the paint bucket's progress bar was a `ValueListenableBuilder` placed directly in the canvas stack, returning `Positioned(...)` when busy and `SizedBox.shrink()` otherwise. The non-positioned zero-size child made the stack 0×0, so the paper's fit scale became 0/0.
- **Fix:** `Positioned` outside, the builder inside it.
- **Rule:** 60.

### 2026-10-27: Refactor snags (awk paths, APK version codes)
- **Symptom:** a code block meant for `canvas_page.dart` was silently not inserted (awk warned "escape sequence `\U' treated as plain `U'"); later `adb install` of a fresh x86_64 APK failed with INSTALL_FAILED_VERSION_DOWNGRADE (13 vs 4011).
- **Root cause:** `awk -v blk="$TEMP/..."` got `C:\Users\...`, whose backslashes awk treats as escapes, so `getline` read nothing. The emulator had a split-per-ABI build (version code 4000 + build), and the new APK was built unsplit (version code = build).
- **Fix:** inserted the block with the Edit tool, then used `/tmp` paths through `ENVIRON`; rebuilt with `--split-per-abi`. `tool/android_smoke.ps1` now prints adb's real install error.
- **Rule:** 58, 59.

### 2026-10-27: A baseline harness run read half-edited files
- **Symptom:** the pre-refactor baseline failed at analyze with ~1000 "Undefined name 'BrushType'" errors.
- **Root cause:** I started the harness in the background and then split `stroke.dart` while it ran; analyze saw the file mid-move.
- **Fix:** used the 4.0.0 release result (313 tests passing) as the baseline and re-ran the harness after the split.
- **Rule:** 57.

### 2026-10-27: Told the user there was no Android SDK, from a stale note
- **Symptom:** while suggesting improvements, I said the Android "open with" feature was unverified because this PC had no Android SDK. The user pointed out the SDK is installed.
- **Root cause:** I quoted the v1.4.0 FEATURES entry ("not verified yet, no Android SDK"), written hours before the SDK was installed. The DEVLOG of the same day records the SDK install, the AVDs, and "open with" passing on the emulator (running and cold start), but the FEATURES note was never updated, and I didn't read the newer records or check the machine.
- **Fix:** checked `flutter doctor -v` (SDK 36, emulator, AVDs `medium_phone` and `medium_tablet`), corrected the v1.4.0 FEATURES note, and told the user.
- **Rule:** 56.

### 2026-10-27: v4 snags
- **Symptom:** a scripted edit put `});` after every `);` in `app_theme.dart`; textured cloth, hair and the dog let the sky show through (they looked checkered or grey); light halos around blended shapes; a straight light band between two mountain ranges and a straight line inside a cloud in the lake painting; tests hung on sample paintings; an English test failed on a Chinese tooltip; settings and setup tests couldn't find lower items.
- **Root cause:** the line-number variable was empty, so `sed` ran on every line; a texture is a mask, so on an opaque object it cuts holes; a blender area reaching the edge blurs in the background; haze was a rectangle, not the mountain's shape; rim points were sorted by raw angle, which jumps at ±180°; `tester.runAsync` awaited futures from the fake-time zone; the new level and text-size sections pushed items down a lazy list.
- **Fix:** restored the file from git and redid the edits with exact replacements; solid fill plus a grain layer; blending inset from the edge; haze clipped to the ridge; angles measured from the sun's direction; plain awaits in those tests; scrolling (and a non-lazy setup page).
- **Rule:** 48 to 55.

### 2026-10-27: v3 snags found by renders and tests
- **Symptom:** rendering the semi-realistic tarot card crashed ("colors must have length 2 if colorStops is omitted"); then most of its light effects (sun glow, rays, haze, shadows) were invisible; the new paper grips couldn't be dragged in tests; turning on semantics asserted.
- **Root cause:** dart:ui needs stops for three or more colors; a gradient stroke took its overall alpha from its base color, which for a fade was the transparent end; half of each grip lay outside the paper area when the paper filled it, and the bottom grip sat under the wide 画笔 · 颜色 button; the grips' semantics had a value but no next/previous value.
- **Fix:** even stops by default; alpha from the gradient; grips kept inside and a quarter along the bottom edge, away from the floating buttons; increased/decreased values.
- **Rule:** 44 to 47.

### 2026-10-27: tarot frame showed sky past the arch
- **Symptom:** a zoomed crop of the 愚人 card showed blue sky between the gold arch and the navy frame near the top.
- **Root cause:** the navy cover over the arch's corners was one 136px-wide marker stroke; perfect_freehand drops outline points closer than about size × smoothing (~68px), so its inner edge was a few straight chords.
- **Fix:** six 30px rings at first; since v3 one filled free shape cut exactly along the arch.
- **Rule:** 43.

### 2026-10-25: v2.2 reports: "bigger paper not implemented", music broken with old settings
- **Symptom:** the user saw no effect from 画纸大小; music misbehaved in a normal browser window but worked in incognito.
- **Root cause:** the bigger sheet was scaled to fit the screen, so 4× looked like 1× with smaller drawings. With music saved as on, the web player started before any touch; the browser's audio-context start stayed pending, and `BackgroundMusic`'s queue awaited it forever. Incognito starts with music off, so it started from a tap.
- **Fix:** zoom to real size after enlarging, plus a hint; the web player waits for the first touch, uses the finger-up event, and limits each call to 8 s; stale track ids fall back.
- **Rule:** 39, 40.

### 2026-10-25: v2.2 test snags
- **Symptom:** shortcut tests seemed to fail on paste, and keys reached the canvas while My Paintings was showing.
- **Root cause:** I read the failure printed before an `[E]` line as belonging to the test named after it (paste only had a pending autosave timer). `IndexedStack` uses `Visibility.maintain`, so `TickerMode` stays on for hidden tabs.
- **Fix:** let the autosave timer run in those tests; check `Visibility.of(context)`.
- **Rule:** 41, 42.

### 2026-10-25: v2.1 test snags
- **Symptom:** the add-kid test never added the kid; the reset and play-order tests tapped off screen (y 1024); a "Welcome!" finder missed "Welcome! 🌸".
- **Root cause:** Save was still disabled in the frame right after typing; `scrollUntilVisible` stopped once the item was built below the screen; the heading includes the theme emoji.
- **Fix:** pump after typing, `ensureVisible` after scrolling, `textContaining`.
- **Rule:** 36, 37 (and 13/14 again for a lazy horizontal theme list).

### 2026-10-25: Half of the Info.plist edits silently didn't apply
- **Symptom:** after a scripted edit, the plist was missing the Photos texts, the exported type and two flags, with no error.
- **Root cause:** `flutter create` wrote the plist with CRLF line endings; patterns with a bare `\n` didn't match, while patterns without newlines did.
- **Fix:** converted the file to LF, re-ran the edits and listed every key to check.
- **Rule:** 34.

### 2026-10-25: A quick straight stroke couldn't be picked up in the middle
- **Symptom:** in a widget test, tapping the middle of a fast straight line with the move tool selected nothing.
- **Root cause:** `Stroke.hits` measured the distance to the recorded points only. A fast swipe records just its two ends, 80px apart.
- **Fix:** distance to each segment; `touches` (box selection) walks each segment in 4px steps.
- **Rule:** 29.

### 2026-10-25: The selection bar covered the turn knob
- **Symptom:** after resizing the selection 2×, dragging its turn knob did nothing in the test.
- **Root cause:** the bar sat at a fixed spot near the top of the paper, over the knob, and took the touch.
- **Fix:** the bar follows the selection (below it, or above when there's no room), measured after layout, and hides while a finger moves the selection.
- **Rule:** 30.

### 2026-10-25: Settings overflowed by 39px in English with large text
- **Symptom:** "A RenderFlex overflowed by 39 pixels" in the 360×640, 1.3× text, English test.
- **Root cause:** the new "Background music" section title was too wide for a plain Row.
- **Fix:** `_SectionTitle` wraps its text in `Flexible`.
- **Rule:** 33.

### 2026-10-25: Emulator scripting slips
- A snackbar ("已新建画作") covered the tools button, so a scripted brush pick missed and the strokes ran as move-tool boxes. Rule 31.
- `adb install /c/AIProjects/...` failed with "No such file": `MSYS_NO_PATHCONV=1` stops Git Bash translating the path. Rule 32.

### 2026-10-25: Print screen couldn't be left (user report)
- **Symptom:** after choosing 打印, the user couldn't get back out.
- **Root cause:** Android's print screen (`PrintActivity`) has no close or back button; with gesture navigation only an edge swipe or Back leaves it, which a child doesn't know. The app opened it directly.
- **Fix:** an in-app print preview with a ✕, a big 关闭 button and a hint about Back, which opens the system screen only when 打印 is tapped. Back from the system screen returns to the preview.
- **Rule:** none new; a general lesson: don't send a child straight into a system screen.

### 2026-10-25: Corner control crashed on a small phone with large text
- **Symptom:** `ArgumentError: Invalid argument(s): 0.0` in the 360×640 English, 1.3× text test.
- **Root cause:** `CornerFloat` clamped its position to `area - size`, which was negative because the control was wider than its area.
- **Fix:** the upper bound is `math.max(0, area - size)`.
- **Rule:** 28.

### 2026-10-25: Zoom couldn't go below 100%
- **Symptom:** the zoom test stuck at 1.0 when zooming out; the chip would show 100% at any zoom-out.
- **Root cause:** `Matrix4.getMaxScaleOnAxis()` includes the z axis, which a 2D zoom leaves at 1, so it never reports less than 1.
- **Fix:** `CanvasPageState.zoomLevel` reads the x-axis scale.
- **Rule:** 23.

### 2026-10-25: "setState() called during build" when opening another painting
- **Symptom:** an exception when the session switched paintings.
- **Root cause:** the zoom view was reset inside a LayoutBuilder's build, which notified other widgets mid-build.
- **Fix:** reset the view from a session listener instead.
- **Rule:** 24.

### 2026-10-25: Screen readers couldn't press the tools button
- **Symptom:** on the emulator, uiautomator showed the button as `clickable="false"`. Flutter's tap-target and label guidelines passed anyway, because they only check nodes that already have a tap action.
- **Root cause:** `Semantics(excludeSemantics: true)` also dropped the InkWell's tap action.
- **Fix:** pass `onTap` to that Semantics, and added a test that activates the button through semantics.
- **Rule:** 25.

### 2026-10-25: Emulator showed a black or blank screen
- **Symptom:** the app (and even system Settings) drew black after an emulator restart; once, it drew nothing right after reinstall plus rotation.
- **Root cause:** the emulator's graphics state, not the app (no errors in logcat). A quick-boot snapshot saved after a forced stop restored a broken GPU state.
- **Fix:** `emulator -avd <name> -no-snapshot-load -gpu host`, then launch from the launcher (`adb shell monkey -p <pkg> -c android.intent.category.LAUNCHER 1`) instead of `am start` straight after install.
- **Rule:** 26.

### 2026-10-25: Test-only snags with the new UI
- `tester.pageBack()` looks for the English "Back" tooltip and fails in the Chinese UI; tap `find.byType(BackButton)` instead.
- Lazy lists (the drawer, and the menu at first) don't build off-screen rows; the menu is now a non-lazy Column, and drawer tests use `scrollUntilVisible`.
- **Rule:** 14 (existing) and 27.

### 2026-10-24: Android SDK packages "not found"; APK build failed on the NDK
- **Symptom:** `sdkmanager "platforms;android-36"` reported "Package platforms not found / Package android-36 not found". The first `flutter build apk` then failed with "sdkmanager did not install NDK 28.2.13676358".
- **Root cause:** the new `sdkmanager.bat` is a cmd wrapper. cmd treats `;` as an argument separator, so `platforms;android-36` arrived as two arguments. Gradle's NDK auto-install calls the same wrapper.
- **Fix:** installed the platform, build-tools and NDK with `android.exe sdk install`, then rebuilt.
- **Rule:** 19 (and 20 for the earlier `Expand-Archive` failure).

### 2026-10-24: Web console warned "Could not find a set of Noto fonts"
- **Symptom:** running in Chrome logged "Could not find a set of Noto fonts to display all missing characters".
- **Root cause:** the 棉花糖 theme emoji ☁️ is U+2601 plus the variation selector U+FE0F, and Flutter web has no Noto font that covers U+FE0F. The settings page is built at startup, inside an IndexedStack, so the warning appeared immediately.
- **Fix:** changed the emoji to 🍭 (a single code point), and added a test that fails on variation selectors in theme emoji.
- **Rule:** 18.

### 2026-10-24: F5 said "cannot find a class with the main method"
- **Symptom:** the user pressed F5 and got a Java error instead of the app starting.
- **Root cause:** the VS Code workspace is `C:\AIProjects`, but `launch.json` was only in `my_paint_app/.vscode/`, so VS Code didn't see it. With no config, F5 picked a debugger from the open file (`GeneratedPluginRegistrant.java`), and the installed Java extension pack tried to run it as a Java program.
- **Fix:** added `C:\AIProjects\.vscode\launch.json` with Dart configs that use `cwd: ${workspaceFolder}/my_paint_app`.
- **Rule:** 17.

### 2026-10-24: Contrast test failed on half-visible "开源许可"
- **Symptom:** 4 of 5 themes failed `textContrastGuideline` with 1.15:1 on the 开源许可 tile.
- **Root cause:** the longer settings page pushed that tile half below the viewport. The guideline sampled the clipped background, not the text. The real colors pass.
- **Fix:** accessibility tests use a 393×1200 screen. Small-screen layout is still covered by the separate 360×640 overflow test.
- **Rule:** 15.

### 2026-10-24: Fill-chip test couldn't find its target
- **Symptom:** `Bad state: No element`, first for the 填充 chip and then for the scroll row itself.
- **Root cause:** the 9th chip is beyond the lazy list's build range, and the row finder was relative to 自由画, which scrolled away during `scrollUntilVisible`.
- **Fix:** resolve the row's element once, then `scrollUntilVisible`.
- **Rule:** 14.

### 2026-10-24: v1.1 header used white text on a pale gradient
- **Symptom:** the user asked for accessible text colors ("如果主题颜色偏淡，那么字体颜色不要为白色"). The v1.1 header had white text on a violet→pink→peach gradient, and on the peach stop that is about 1.9:1, well below WCAG AA's 4.5:1. The pink "new painting" button with white text also failed.
- **Root cause:** foreground colors were picked by eye and never measured.
- **Fix:** themes are now JSON templates. Text colors are derived from contrast math, and tests check WCAG AA plus Flutter's accessibility guidelines on every theme and screen.
- **Rule:** 10.

### 2026-10-24: Brush button crashed with "blur radius should be non-negative"
- **Symptom:** a widget test crashed when switching brushes, followed by a 99,937px overflow.
- **Root cause:** `Curves.easeOutBack` overshoots past 1.0. While the selected tile's shadow faded out, the overshoot made its blur radius negative.
- **Fix:** switched to `Curves.easeOut`.
- **Rule:** 11.

### 2026-10-24: Year filter chips were too small to tap
- **Symptom:** `androidTapTargetGuideline` failed with chips 40px tall.
- **Root cause:** the chip row was 56px high with 8px padding, which squeezed the chips' 48px tap area.
- **Fix:** made the row 60px tall with 6px padding.
- **Rule:** 12.

### 2026-10-24: Tests couldn't find off-screen list items
- **Symptom:** finders for the 8th brush and the 4th theme card found nothing.
- **Root cause:** sideways-scrolling lists only count visible items as "onstage".
- **Fix:** `skipOffstage: false` for existence checks, and `ensureVisible` before tapping.
- **Rule:** 13.

### 2026-10-24: Deleting during an autosave could bring the painting back
- **Symptom:** found in review. Deleting the open painting while its autosave was rendering the thumbnail let the save finish after the delete, re-adding the painting to the gallery.
- **Root cause:** `delete()` didn't wait for the save already in progress.
- **Fix:** the session keeps the latest save's future, and `delete()` awaits it before deleting. Covered by the test "deleting while an autosave is running does not bring it back".
- **Rule:** 9.

### 2026-10-24: Painting IDs collided, so a new painting could overwrite the old one
- **Symptom:** two model tests failed, because "new painting" got the same ID as the previous painting.
- **Root cause:** IDs were `DateTime.now().microsecondsSinceEpoch`. On Windows the clock can return the same value twice in quick succession.
- **Fix:** `_newId()` now takes `max(now, last + 1)`.
- **Rule:** 7.

### 2026-10-24: Hand-rolled UTF-8 encoding didn't compile
- **Symptom:** analyzer error "Utf8Codec isn't a class" in `store_backend_io.dart`.
- **Root cause:** overcomplicated code that guessed at the system encoding.
- **Fix:** `utf8.encode(value)`.
- **Rule:** 8.

### 2026-10-23: Save in Chrome threw MissingPluginException
- **Symptom:** the user saw `MissingPluginException` when pressing Save in the Chrome debug session.
- **Root cause:** `gal` has no web implementation, but was called on every platform.
- **Fix:** `lib/image_saver.dart` picks `image_saver_io.dart` (gallery) or `image_saver_web.dart` (browser download) through a conditional export.
- **Rule:** 2.

### 2026-10-23: Windows debug build failed ("requires symlink support")
- **Symptom:** `flutter build windows` stopped with "Building with plugins requires symlink support".
- **Root cause:** Windows Developer Mode is off.
- **Fix:** used Chrome as the debug target. The user can turn on Developer Mode (`start ms-settings:developers`) to use Windows.
- **Rule:** 3.

### 2026-10-23: Project only had the Android platform
- **Symptom:** there was no way to debug before the Android SDK was installed.
- **Root cause:** created with `--platforms android`.
- **Fix:** `flutter create --platforms windows,web .`
- **Rule:** 1.

### 2026-10-23: Background `flutter run` couldn't hot reload
- **Symptom:** the Chrome session started by Claude couldn't take `r`/`R` keys.
- **Root cause:** background tasks have no keyboard input.
- **Fix:** added `.vscode/launch.json` so the user can run with F5, with hot reload on save.
- **Rule:** 4.

### 2026-10-23: Default widget test referenced the removed `MyApp`
- **Symptom:** analyzer error after `main.dart` was rewritten.
- **Fix:** rewrote `test/widget_test.dart` for the new app.
- **Rule:** 5.

### 2026-10-23: Used `as dynamic` to get past a type mismatch
- **Symptom:** `exportPng` returned `List<int>` but `Gal.putImageBytes` needs `Uint8List`.
- **Fix:** made `exportPng` return `Uint8List`.
- **Rule:** 6.
