# Dev log: JoyPainting (快乐涂鸦), formerly JingyaoPaint

## 2026-10-28: v6.1.0 (my own brushes, helpers, a simpler title bar)
- 6.0.0 after pushing: Web and iOS passed (live version.json 6.0.0+25).
- Asked: remove new and save from the title bar (autosave), put the move tool there, simplify the brushes and let kids make their own, and give the tools that aren't brushes (picker, eraser) their own extendable group, keeping the basic ones. Asked back which "custom brushes" meant; the answer: both choosing which brushes show and saving presets.
- Done: `BrushPreset` and 我的画笔 (save, pick, long-press delete); `ToolGroup.brushes` and `ToolGroup.helpers` (小帮手) with basic and addable members; the title bar with 选择移动, 清空, ✋, ☰; 新建画作 in the ☰ menu (there was none there, so removing the button alone would have lost it); the phone strip following the drawer.
- Mistakes: none new.
- Harness: PASS (analyze 0 issues, 418 tests, build web ok).
- Not tested: on a real device.
- After pushing: Web passed (live version.json 6.1.0+26). iOS failed at "Start on the iPhone and iPad simulators": the iPhone ran; the iPad was "not running" 30 s after launch, with no crash report and ordinary log lines up to the end (as with 4.1.0's iPhone, which the next run passed). This record's push runs the check again.
- Next: from the plan, background cache rebuilds and replay keyframes (measure first).

## 2026-10-28: v6.0.0 (adding tools)
- 5.4.3 after pushing: Web and iOS passed (live version.json 5.4.3+24); that iOS run also covers 5.4.2's code.
- Asked: make shapes, textures and the like an "add" feature, a multi-select popup that puts each choice in its own group, the drawer keeping only basic options; enrich shapes, textures and the other intermediate and advanced options. Later: add arc and wave shapes.
- Done: `ToolCatalog` (basic options, what each level can add), `AppSettings.addedTools`, the drawer showing basic + added + chosen with 「＋ 添加」 per group and 添加工具 at the bottom, `showAddToolsSheet` with pictures drawn by the options themselves; 14 shapes, 4 stamps, 4 gradients, 4 light & shadow modes, 6 textures, each saved so older versions degrade gently (new shapes keep their outline as points).
- Found by tests: two English "Glow"s (gradient and light mode; the light one is now "Shine"); the dots texture left the single sampled row nearly empty (bigger dots; the texture test reads several rows) and hatching never reached full paint (solid line cores). By eye: the cloud looked like a pile (flatter, four puffs); picked chips in the popup were too faint (filled now); gradient pictures in black all looked alike (blue for grays).
- Mistakes: MISTAKES rule 66.
- Harness: PASS (analyze 0 issues, 414 tests, build web ok).
- Not tested: on a real device.
- Next: from the plan, background cache rebuilds and replay keyframes (measure first).

## 2026-10-28: v5.4.3 (shapes with light & shadow)
- 5.4.2 after pushing: Web passed (live version.json 5.4.2+23); iOS never ran ("The job was not acquired by Runner of type hosted even after multiple attempts", macOS runner capacity). No `gh` here to re-run it; this push runs it again.
- Reported: with light & shadow on, shapes other than freehand and free shapes showed no trail; asked to look for other combinations too. Cause: my 5.4.2 change; `moveShapeEnd` didn't signal the layer to repaint. A new sweep test (`test/live_stroke_test.dart`) checks every brush × blend × shape the draw tool makes (560) as the screen repaints them: 336 failed on 5.4.2, none now; mirror, texture, low opacity and a see-through layer also pass.
- Also this session: painted 泼墨山水 for the user from the app's strokes (`local_art/ink/`, not in git; 6,959 strokes, opens in the app as a .jypaint).
- Mistakes: MISTAKES rule 65.
- Harness: PASS (analyze 0 issues, 404 tests, build web ok).
- Next: from the plan, background cache rebuilds and replay keyframes (measure first).

## 2026-10-28: v5.4.2 (light & shadow while drawing)
- 5.4.1 after pushing: Web and iOS passed (live version.json 5.4.1+22).
- Reported: with freehand + charcoal + soft light, no trail while drawing. Cause: the stroke being drawn blended with the white paper (soft light, overlay and screen leave white unchanged); finished strokes blend only with their own layer. Strokes with a blend now go into their layer while drawn, like the eraser; the replay too.
- Mistakes: MISTAKES rule 64 (5.4.1 chased thin lines because my probes never set a blend).
- Harness: PASS (analyze 0 issues, 401 tests, build web ok).
- Not tested: on a real device.
- Next: from the plan, background cache rebuilds and replay keyframes (measure first).

## 2026-10-28: v5.4.1 (thin textured lines, samples without the stall)
- 5.4.0 after pushing: Web and iOS passed (live version.json 5.4.0+21).
- Asked: a stall when changing the level (a progress bar while the sample is made, and "（示例）" in sample names); textured strokes showing no trail. The user later found the second fine on another computer.
- Found by measuring (VM test, then a probe page in Chrome, `local_art/probe/`, not in git): adding a sample is mostly painting its gallery thumbnail, 4.2 s in Chrome for 湖畔晨光 and 2.7 s for 海边的晚霞; loading and saving it about 0.4 s. Textured strokes did show while drawing (Chrome, through the real canvas with simulated touches); asked, the user said to try a thin pen and a straight line: at size 1 the bristles texture hid the line entirely and the others left a faint dashed line (worst on 1× screens, which fits "fine on another computer").
- Done: ready-made thumbnails for the intermediate and advanced samples; `makingSample` and `SampleProgressCard` while a sample is added, then a snackbar; sample names with （示例）; `fadesGrain` on new strokes so thin textured lines keep part of their paint (the samples and older paintings unchanged). Found by a test along the way: a reset could add the beginner sample before the first-start setup (`addSampleOnce` now waits for onboarding).
- Checked by eye: the progress card on a phone (`local_art/screens/out/6_phone_sample_card.png`).
- Mistakes: MISTAKES rules 62 and 63 (the formatter rewriting whole files; a texture fix that would have changed the approved advanced sample).
- Harness: PASS (analyze 0 issues, 400 tests, build web ok).
- Not tested: the progress card and the texture fix on a real phone or tablet.
- Next: from the plan, background cache rebuilds and replay keyframes (measure first).

## 2026-10-28: v5.4.0 (a tidier drawer, the layers button, quiet between tracks)
- After pushing 5.3.0 and 5.3.1: 5.3.0's Web passed and its iOS run was cancelled by the 5.3.1 push; 5.3.1's Web and iOS both passed (live version.json 5.3.1+20).
- Asked (while 5.3.1 was being finished): drawer groups that open and close, everyday ones open by default; size and opacity under the colors; layers as their own draggable button next to the tools button; a 3-second pause after each music track; a shortcut list at least 500 wide that fits small screens.
- Done: `ToolSection`s with `SectionHeading`s (remembered per section; closed headings show what's picked), sliders under the colors and the tool tip under the brushes; `LayersButton` in its own `CornerFloat` (stacked above the tools button while sharing its corner, following it until dragged; `blocked` became a set); music plays each track once and `BackgroundMusic` waits `gap` before the next (also on repeat); the shortcut list's width. `ToolSection`/`SectionHeading` live in `canvas/tool_section.dart` so `tool_drawer.dart` stays at 744 lines.
- Checked by eye: screenshots from a local test with the real fonts (`local_art/screens/shots_test.dart`, not in git): phone canvas with the layers button above the tools button, the drawer on a phone and a tablet as a new user sees it, the shortcut list on a tablet and a 360×640 phone.
- Mistakes: MISTAKES rule 61 (test strokes drawn where the new layers button now sits).
- Harness: PASS (analyze 0 issues, 397 tests, build web ok).
- Not tested: on a real phone or tablet (see DEVICE_CHECKLIST.md); the 3-second pause with real audio (the end of a track is reported by the player, as before).
- Next: from the plan, background cache rebuilds and replay keyframes (measure first).

## 2026-10-28: v5.3.1 (the plan's leftovers)
- Asked: check for unfinished items, then do them. Found five planned details left out (TECH_PLAN section 5, "剩余"); did the first three.
- Done: a 照片也放进去 switch in the download and send format sheets (pictures without the photo; `.jypaint` keeps it); in a browser, Settings says whether the browser promised to keep the paintings, with a button that asks it to (`navigator.storage.persist()`); `docs/appdev/DEVICE_CHECKLIST.md` for real-device checks after each release.
- APK: release APKs built for 5.3.1 (arm64 32.4 MB, armv7 30.4 MB, x86_64 34.0 MB); the x86_64 one installed over the earlier install on the Pixel Tablet emulator (Android 15) and passed `tool/android_smoke.ps1` (started, drew, no errors in the log; earlier paintings still there). First APK check since 4.1.0.
- Mistakes: none new.
- Harness: PASS (analyze 0 issues, 391 tests, build web ok).
- Not tested: the storage button in a real browser that says no (Chrome decides by itself; Firefox asks).
- Next: 5.4.0, as asked meanwhile: collapsible sections in the brushes & colors drawer (basic ones open), size and opacity right under the colors, layers as their own draggable floating button; a 3-second pause after each music track; a wider keyboard shortcut list (500 px, narrower only on small screens). Still open from the plan: background cache rebuilds and replay keyframes (measure first).

## 2026-10-28: v5.3.0 (coloring book)
- 5.2.0 after pushing: Web and iOS passed (live version.json 5.2.0+18). 5.1.0's iOS run was cancelled by the 5.2.0 push (same workflow group); 5.2.0 holds all of 5.1.0 and passed.
- Done: F7's coloring book (8 line drawings on a locked top layer, the 涂色本 sheet in My Paintings, opening a page as a new painting with the layer under the lines active). The overview was shown to the user (local_art/out/coloring/all.png) before pushing; they said to go on.
- Mistakes: none new.
- Harness: PASS (analyze 0 issues, 386 tests, build web ok).
- Not tested: coloring on a real phone or tablet.
- Next: the TECH_PLAN items are in, but some planned details were left out (TECH_PLAN section 5, "剩余"): leaving the photo layer out of exports, the browser storage status in Settings, APK builds and the emulator smoke test since 4.1.0, background cache rebuilds, replay keyframes.

## 2026-10-28: v5.2.0 (turning the paper)
- Done: F8 (two-finger rotation with quarter-turn snapping, R / Shift+R, the angle on the zoom chip, grips hidden while turned, off for beginners).
- Mistakes: a bash-quoted perl edit with `${...}` failed with "bad substitution" (nothing changed; redone with the Edit tool, as rule 48 says for such edits).
- Harness: PASS (analyze 0 issues, 383 tests, build web ok).
- Not tested: rotating with real fingers on a phone or tablet.
- Next: the coloring pages (to be shown before pushing). The TECH_PLAN items F1–F8 are otherwise done.

## 2026-10-28: v5.1.0 (a photo to trace)
- 5.0.0 after pushing: Web and iOS passed (live version.json 5.0.0+16).
- Done: F7's photo part (photo strokes saved inside paintings, decoding once with repaints, import with upright turn, shrinking and fitting in the background, a locked see-through photo layer at the advanced level). The coloring pages are new artwork, so by the user's rule they wait for review before any push and were left out of 5.1.0.
- Mistakes: none new.
- Harness: PASS (analyze 0 issues, 378 tests, build web ok).
- Not tested: HEIC photos from an iPhone's library (the image package can't read HEIC; the app says the picture can't be read), very large photos on an older phone.
- Next: draw the coloring pages and show them; F8 canvas rotation for 5.2.0.

## 2026-10-28: v5.0.0 (layers)
- Done: F6 layers (model, undoable layer edits, strokes kept in layer order, per-layer rendering and kept pictures, layered exports/thumbnails/replay/GIF, active-layer-only picking, the layers panel at the advanced level, refusing to draw on hidden or locked layers). Released on its own as 5.0.0 (it changes how paintings are made and saved); the plan now puts F7 in 5.1.0 and F8 in 5.2.0.
- Found while testing: a touch refused on a hidden layer was still seen by the zoom/pan listener as a drag outside the paper and moved the paper; the refused touch now stays taken. Two shape tests had to scroll to their chips, now below the layers row (MISTAKES rule 55).
- Chrome benchmark after the change (3,058 strokes, one layer): drawing 5.7 + 1.5 ms per frame, erasing 5.8 + 1.3, undo 3.9 + 0.8, a fill 144 ms: as in 4.1.
- Mistakes: none new (the blocked touch was caught by the new test).
- Harness: PASS (analyze 0 issues, 373 tests, build web ok).
- Not tested: a real tablet with many layers; how a layered painting looks when opened in 4.x (by design: flat, hidden layers shown).
- Next: F7 (photo underlay, coloring pages) for 5.1.0.

## 2026-10-28: v4.2.0 (replay and GIF, backup reminders)
- Done: F4 replay (timeline, partial strokes, frames from the kept picture, page with play/pause, speeds and a slider; GIF export encoded in the background, cancellable; entries in the ☰ menu and the gallery card menu) and F5 backup reminders (when to remind, the banner with one-tap backup and "later", per kid, a Settings switch, sooner in a browser without persistent storage). Tests turn the reminder off by default (`testDefaults`), as with the samples; backup_test turns it on.
- 4.1.0 after pushing: the Web workflow deployed it (live version.json 4.1.0+14); the iOS workflow failed at "Start on the iPhone and iPad simulators": the iPhone was "not running" 30 s after launch, the iPad was fine. Every earlier iOS run passed. Logs and artifacts need a GitHub sign-in, so the cause is unknown (a crash from the new code, or the busy macOS runners); `ios_sim_smoke.sh` now puts the log's telling lines and the crash report into annotations, which this 4.2.0 push will show.
- Mistakes: none new.
- Harness: PASS (analyze 0 issues, 363 tests, build web ok).
- After pushing: Web and iOS both passed for 4.2.0 (iPhone and iPad simulators running; live version.json 4.2.0+15). 4.2.0 holds all of 4.1.0, so the 4.1.0 iPhone failure was a one-off on the runners.
- Next: F6 layers (5.0.0).

## 2026-10-28: v4.1.0 (code split, smooth big paintings, color picker, paint bucket)
- Asked: turn the suggested improvements into a technical plan with code reuse and splitting first (docs/appdev/TECH_PLAN.md), check the Android SDK (it was installed on 2026-10-24; my "no SDK" claim came from a stale FEATURES note), keep records current, then build the items one by one, picking version numbers and pushing each version without asking; use Chrome when the emulator fails.
- Done:
  - R, the split: `canvas_page.dart` 3,556 → 764 lines; `lib/drawing/canvas/` (tools, selection, view, resizer, shortcuts, menu, paper, drawer, palette strip) and `lib/drawing/render/`; `stroke.dart` 1,551 → 586 lines plus five type files and a painting part. The 313 old tests passed unchanged (four render calls renamed); the 5,131-stroke 愚人 re-rendered byte for byte the same.
  - F9: `tool/android_smoke.ps1` (install, launch like the launcher, draw, screenshot, log check); passed on the Pixel Tablet emulator.
  - F1: `StrokeLayerCache` keeps the finished strokes as a picture (new strokes added onto it, the eraser painted over it, recent states kept for undo/redo). Chrome, 3,058 strokes, ms per frame (build + raster): drawing 15 + 178 → 5.5 + 1.4, erasing 291 + 353 → 5.4 + 1.1, undo 197 + 294 → 4 + 1. Measured with `tool/bench/` (Chrome) and `integration_test/` (devices).
  - F2: the color picker with a loupe (intermediate+), Alt + click and I.
  - F3: the paint bucket (every level): flood fill with gap closing, holes, one pixel under the edges, saved as an exact `area`; 96 ms per fill on 3,058 strokes in Chrome.
  - Also fixed: a pinch during ✋ left the next touch moving the paper.
- Emulator: the Pixel Tablet emulator smoke-tested the split build. The emulator crashed in 4 of 5 runs on the 3,058-stroke sample (host GPU and software rendering alike), so big-painting measurements moved to Chrome; the Windows desktop build fails here (VS 2019 too old for the audioplayers/gal plugins).
- Mistakes: MISTAKES rules 56–60 (stale notes, a background harness during edits, awk with Windows paths, split-APK version codes, a non-positioned child collapsing the canvas stack).
- Harness: PASS (analyze 0 issues, 350 tests, build web ok). APK: the split x86_64 release build passed the emulator smoke test after the refactor; not rebuilt after F2/F3 (Dart-only changes).
- Not tested: a real phone or iPad (smoothness, fills by finger, the loupe under a real finger); the bucket on the Android emulator by hand.
- Next: 4.2.0 (F4 replay and GIF, F5 backup reminder).

## 2026-10-27: v4.0.0 (drawing levels, realistic painting tools, level samples, text size, menu button)
- Asked, in steps: the 愚人 card still too cartoonish, wanted a mature, realistic style with more realistic painting tools, and the traveler holding only his luggage; then a simpler tools drawer with levels (beginner / intermediate / advanced) chosen on first start and in Settings; a clearer top-right menu icon; a text size slider for accessibility; tarot code kept off git in a local folder (and removed from main); a detailed README per release, also as a rule in the appdev skill; three sample paintings (one per level, the top one to the 愚人 standard, in the repo); then push as one big update.
- Done: see FEATURES v4.0.0 and the README release notes. The 愚人 card was repainted (dawn backlight, fractal mountains with erosion streaks and snow, a grassy headland, a man of seven and a half heads with a leather bag, the dog; face cleaned up after feedback, stubble kept) and lives in `local_art/` with its tooling. The appdev skill now requires README release notes for every version.
- Checked by rendering: the card and the three samples were rendered from their saved files and looked at (whole picture and crops: face, edges, sun area).
- Mistakes: MISTAKES rules 48 to 55.
- Harness: PASS (analyze 0 issues, 313 tests, build web ok).
- Not tested: the blender's speed and textures on a real phone or iPad; the text size slider with a real screen reader; the sample paintings opening on a slow phone (the advanced one is 2.6 MB).
- Next: feedback on the samples; tarot cards I to XXI locally.

## 2026-10-27: v3.0.0 (painted looks, resizable paper, download formats, tarot cards)
- Asked, in steps: a beautiful tarot deck made with the app, one style with text, starting with 0 愚人; then, after seeing it, a semi-realistic look instead of cartoon, with the app gaining whatever that needs as real tools (chosen: semi-realistic painting, not photo-realistic; as brushes and options, not only display); then a paper resized by dragging (drawings keep their size, undoable), no zoom items in 视图, download as PNG/JPG/PDF, the tarot paper exactly the card; then version 3 and deploy.
- Done: see FEATURES v3.0.0. The first card was cartoon-style (triangles placed by transforms); the semi-realistic one uses the new free shapes, gradients, blur and blend modes (488 strokes, 80 blurred, 84 blended). New paintings still fill the screen until a grip is dragged.
- Checked by rendering: the card PNG is drawn from its saved file read back, and crops were looked at (arch, head, clouds).
- Mistakes: MISTAKES rules 43 to 47.
- Harness: PASS (analyze 0 issues, 279 tests, build web ok).
- Not tested: drawing on top of the card on a real phone (speed with many blurred strokes); the grips with a real finger and mouse; PDF to the share menu and JPG to the gallery on real devices.
- Next: cards I to XXI (`tool/tarot/deck.dart`); feedback on the 愚人 art.

## 2026-10-25: v2.2.0 (shortcuts, bigger paper, music, sample painting, copying)
- Asked: common keyboard shortcuts in the browser; the bigger paper "not implemented"; music problems with settings from earlier versions (fine in incognito); five calm tracks with shuffle as default; then a sample painting, copying paintings, Ctrl+C for selected strokes, and default kid names 靖瑶 / Athena.
- Causes found: the bigger paper worked but was shrunk to fit the screen, so nothing looked different. Music: with music already on from an earlier visit, the web player tried to start before any touch; the browser's audio start then never finished, and the player's queue waited on it forever. Incognito starts with music off, so it began only after a tap.
- Done: see FEATURES v2.2.0. The two old tracks were regenerated slower, at 12 kHz.
- Mistakes: MISTAKES rules 39 to 42.
- Harness: PASS (analyze 0 issues, 244 tests, build web ok).
- Emulator (2560×1600 tablet, x86_64 release APK 2.2.0 installed over 2.1.1): existing paintings and settings kept; 快乐的一天 added with 你好呀！; 复制一份 made 快乐的一天 副本; 4× paper zoomed to 200% with the drawing in place, the hint, and 适应屏幕 showing the whole sheet; no 键盘快捷键 item on Android.
- Not tested: music in real browsers (iPhone Safari, desktop Chrome with old settings); shortcuts in a real browser (Ctrl+P / Ctrl+S overriding the browser; tests cover the key handling); the tracks by ear beyond the generator's checks.

## 2026-10-25: v2.1.1 (import/export, bigger paper, pinned palette, moving the paper)
- Asked, in steps: an obvious import button; export from My Paintings with checkmarks, multi-select and the filter, several as a zip and one as its own file; import reading both; the web loading text English until the language is set; a paper up to 4× bigger; a pinned palette, which on small screens became a slim strip; ✋ move-the-paper; dragging outside the paper moves it with one finger.
- Clarified: "锁住调色板" means pinning it on screen (not a parental lock).
- Done: see FEATURES v2.1.1. `archive` added for zips.
- Found by tests: the wider undo bar (with ✋) overlapped the tools button on a 393px phone, so ✋ moved to the title bar; the title's pencil icon overflowed a 360px phone at 1.3× text, so it became part of the text; the strip's colors started off screen, so it got a second row.
- Harness: PASS (analyze 0 issues, 227 tests, build web ok).
- Emulator (2560×1600 tablet, x86_64 release APK 2.1.1): 导入/导出 buttons (then left-aligned with the year chips); checkmark selection of 2 paintings; export opened the share sheet with 快乐涂鸦_20261025_2幅.zip; ✋ in the title bar; pinning docked the palette on the right and the painting scaled to fit beside it; no app errors in logcat.
- Not tested: browser downloads, Space-to-move on a real keyboard, the strip on a real phone, importing the exported zip on another device.

## 2026-10-25: v2.1.0 (JoyPainting, first-start setup, kids, painting names)
- Asked: first-start language/theme (English default), email attachment from the web, default painting names with rename, kid's name in Settings and setup, device-specific texts, music play order, add/delete kids and reset behind a multiplication question; then rename the app JoyPainting / 快乐涂鸦 and a web address that ignores capitals.
- Interpreted: kids each get their own paintings; the grown-up check guards add, delete and reset (not renaming); installs from before v2.1 see the setup once, keeping Chinese and 靖瑶; internal IDs keep "Jingyao" so updates install in place.
- Done: see FEATURES v2.1.0. Web address: GitHub Pages matches project paths exactly (`/jingyaopaint/` was a 404), so a root site repo `leonfighter1.github.io` was prepared locally (404.html redirects any capitalization of `/jingyaopaint` or `/joypainting`; the front page opens the app). It needs the user to create that repository.
- Mistakes: test-side only (MISTAKES rules 36 to 38): Save disabled until a frame after typing, scrollUntilVisible stopping at items built in the cache, `share_plus` on the web not telling a share from a download.
- Harness: PASS (analyze 0 issues, 209 tests, build web ok).
- Not tested: the web email path in real browsers, the iOS Chinese name and prompts (need the iOS workflow and a device), the setup and kids on a real phone.
- Moved (user's choice): the code and history now live in https://github.com/leonfighter1/JoyPainting; the web app is at /JoyPainting/. The old repository got a last commit that turns its site into redirects (/JingyaoPaint/… to /JoyPainting/…) and stops its workflows. Paintings saved in the browser stay, since storage belongs to leonfighter1.github.io, not the path. For any capitals, the user created `leonfighter1.github.io` (local copy at `C:\AIProjects\leonfighter1.github.io`); its 404.html forwards /joypainting or /jingyaopaint in any capitals to /JoyPainting/, and its front page opens the app. Checked in headless Chrome: /joypainting/ and /JOYPAINTING/ open the app. First runs in the new repository: iOS and Web green.

## 2026-10-25: Web version on GitHub Pages
- Why: without a paid Apple account, an iOS build only installs for 7 days at a time; the web version added to the home screen has no signing or expiry. The user chose GitHub's free address over a custom domain or another host for now.
- Done: IndexedDB storage (with persistence request and localStorage migration), music that waits for the first touch in browsers, home-screen meta and opaque apple-touch icon, no portrait lock, loading screen, `.github/workflows/web.yml` (browser storage tests in Chrome, build with self-hosted CanvasKit, deploy to Pages), README web section. `--base-href /JingyaoPaint/` build checked locally.
- Mistakes: none reached the user. The new music test caught retries slipping past the "wait for a touch" state; fixed. Chrome and Edge can't start headless from this PC's tool shell, so the browser test runs in CI only.
- Harness: PASS (analyze 0 issues, 192 tests; web release build ok).
- The user enabled Pages. First deploy (run 40235752058): green, including the IndexedDB tests in Chrome; site returns 200 with base href /JingyaoPaint/, app code, CanvasKit, icon, manifest and music; a headless Chrome screenshot at 1180×820 shows the canvas page drawn in the cute font. Moved upload-pages-artifact and deploy-pages to v5 (Node 24).
- Not tested: Safari on a real iPhone/iPad (home-screen launch, Pencil, storage persistence), whether github.io and the fallback fonts load well where the family is.

## 2026-10-25: iOS version (same repo, built on GitHub Actions)
- Decision (with the user): keep iOS in this repo, since Flutter shares all of `lib/`; build on GitHub-hosted Macs, which are free for this public repo. Signing and TestFlight wait for an Apple Developer account.
- Done: `flutter create --platforms ios` (Flutter 3.47.8 template: SceneDelegate, implicit engine, Swift Package Manager); bundle ID set to match Android; Info.plist (name, zh-Hans/en, Photos texts, `.jypaint` document and exported type, no in-place opening, no-encryption flag); `OpenFilePlugin` in AppDelegate.swift written against the engine headers at revision 737ba8f885 (scene lifecycle delegate; Flutter replays launch options to it); single 1024px opaque icon from `make_icons.ps1`; ambient audio session on iOS; Apple-only music formats; iPad share anchor; `.github/workflows/ios.yml` and `tool/ios_sim_smoke.sh`; README iOS section.
- Mistakes: plist CRLF made regex edits miss (rule 34). Rule 35 added for native code that can't be compiled here.
- Harness: PASS (analyze 0 issues, 191 tests, build web ok). Android/web icons unchanged after regenerating.
- **Not verified:** nothing iOS has been compiled or run. The Swift code, Info.plist and the workflow get their first real check when this is pushed and the iOS workflow runs. Also untested: a real device, Apple Pencil pressure, AirPrint on iPad, "Open in" from Files/AirDrop.
- First workflow run (40227038101, commit 662a376): all steps green in 12 minutes (analyze, 191 tests, release build, simulator build, app running on the iPhone and iPad simulators). Fixed its only warning: actions/checkout and upload-artifact moved from v4 (Node 20, deprecated) to v5. Screenshots are in the run's artifacts; downloading needs a GitHub login, so they haven't been looked at here.
- Next: look at the screenshots; for hands-on testing from Windows, a simulator build zip could go to a browser simulator (Appetize); signing and TestFlight once there's an Apple Developer account.

## 2026-10-25: v2.0.0 (box selection, copy/resize/turn, recolor/fade, background music, print preview)
- Done: the move tool selects several strokes with a box; the selection can be copied, resized (corner knob or buttons), turned (top knob or buttons), recolored, faded and deleted, each as one undo step, with a bar that follows the selection. Strokes gained a saved `StrokeTransform`. Looping background music with two synthesized built-in tracks, uploads of common formats, volume, track choice, a ⋮ quick switch and pause in the background (`audioplayers`). Printing now goes through an in-app preview with a big close button. README gained a Versions table.
- Clarified by the user: "颜色和透明度" means the selected elements, not the whole board. A started paper color/transparency change was dropped.
- Emulator (2560×1600 tablet, x86_64 release APK 2.0.0, installed over 1.6.0 with the user's paintings kept): box select (2 of 3 strokes), quarter turn by the knob, 1.5× resize by the knob, copy, recolor to purple and fade to 40%, one undo restoring the opacity, print preview → system print screen → Back → preview → 关闭; music on (active 16 kHz track at −8 dB in the mixer), paused on HOME and resumed on return, looping every 17 s; a WAV added through the system picker played and was deleted again. Test painting, test song and Download file removed afterwards; music left off.
- Mistakes: sparse-point hit test, bar over the turn knob, English large-text overflow, two scripting slips (MISTAKES rules 29–33). The print bug is logged as a user report.
- Harness: PASS (analyze 0 issues, 186 tests, build web ok). Release APKs: arm64 28.2 MB / armv7 25.9 MB / x86_64 29.6 MB.
- Not tested: a real phone (fingers on the knobs, real speakers, MP3/M4A files from a real music library, a real printer); actual sound quality of the built-in tracks (the emulator gives no audio to listen to).

## 2026-10-25: v1.6.0 (corner controls, move tool, round eraser)
- Done: undo/redo default to the top right. The undo bar and tools launcher can be dragged, snapping only to the paper's four corners and never overlapping (positions are remembered). The drawer slides in from the launcher's side. New 选择移动 tool auto-selects the last stroke and drags any stroke, with one-step undo. The eraser has no colors or shapes.
- Emulator (2560×1600 tablet, portrait, x86_64 release APK 1.6.0) checks: undo bar at top right; launcher dragged to bottom left; drawer opens from the left; eraser panel shows only the round-tip hint and sliders; move tool selects the last stroke and drags it; one undo restores it; undo bar dropped on the launcher's corner snaps to bottom right.
- Mistakes: clamp with a negative upper bound (rule 28). Avoided setState in initState by splitting the selection sync.
- Harness: PASS (analyze 0 issues, 151 tests). Release APKs: arm64 26.5 MB / armv7 24.2 MB / x86_64 27.9 MB.
- Not tested yet: a real phone (dragging with a real finger, stylus).

## 2026-10-25: v1.5.0 (tablets, pinch zoom, tools drawer, new layout, small APKs)
- Done: tablet/landscape support (side rail, paper scales to fit and never crops, centered settings); pinch zoom and pan with a fit chip, wheel zoom and menu zoom; tools moved into a sliding drawer opened by a "画笔 · 颜色" button; save and clear top right; delete, settings, zoom, mirror, paper, share and print in an unfolding grouped ⋮ menu; undo/redo at top left; settings removed from the bottom bar; split-per-ABI obfuscated APKs (arm64 26.4 MB).
- Emulator (2560×1600 tablet, Android 15), on the final build: install, landscape canvas, drawer open/close/select, drawing with the backdrop closing the drawer, menu zoom to 156% and drawing while zoomed, fit animation, settings from ⋮ and back, portrait rotation without cropping, delete with confirmation, and the new ⋮ dropdown.
- Found and fixed through testing: zoom stuck at 100% (z-axis scale), a notifier changed during build, the tools button not activatable by screen readers (found on the emulator, now covered by a test).
- Unexplained, once: after Back closed the drawer in a freshly rotated session, one tap on delete opened the send sheet. It didn't reproduce in 3 retries (2 scripted, 1 manual) and delete has since moved into the menu. Watch for it on real devices.
- Harness: PASS (analyze 0 issues, 138 tests). Release APKs built: arm64 / armv7 / x86_64.
- Not tested yet: a real phone (pinch with real fingers, stylus, WeChat file sharing, real printer).

## 2026-10-24: APK tested on an emulator (Android 16, 1080×2400)
- Setup: the user enabled Windows Hypervisor Platform (WHPX usable). Installed the emulator and a system image, created AVD `medium_phone` with `android.exe emulator create medium_phone`, and started it with `android.exe emulator start medium_phone`.
- PASS: APK installs; app launches with no errors in logcat; 快乐体 font and 樱花粉 theme render; freehand drawing; color change; autosave (the drawing appeared in the gallery after an import replaced it on the canvas).
- PASS: "open with" for `.jypaint`, both while the app is running (`onNewIntent`) and from a fully stopped app (cold start, `takeInitialFile`). The imported painting (bold centered bubble text, filled heart, marker line, pink paper) matched the file exactly, got a new id, and kept its 2025 creation date in the year filter.
- PASS: send → JPG opened the system chooser; print opened the Android print UI with a correct A4 preview (it loads after a few seconds).
- Known limit: with a generic type (`application/octet-stream`), Android only offers JingyaoPaint when the link contains the `.jypaint` name. File-manager style links do; bare MediaStore ids (`content://media/external/file/16`) don't. The in-app 导入画作文件 button covers that case.
- Not tested: real WeChat/QQ (not on the emulator), stylus pressure, a real printer.

## 2026-10-24: Android SDK installed, renamed, first APK
- Done: installed the Android SDK (cmdline-tools 16111833, platform 36, build-tools 36.0.0, NDK 28.2; Gradle also pulled platforms 34 and 35); renamed to JingyaoPaint (`com.personal.jingyaopaint`); built `dist\JingyaoPaint-v1.4.0.apk` (64.7 MB); added build and watch scripts.
- Licenses: the Android SDK licenses were accepted on the user's behalf, because they asked for the SDK to be installed.
- Mistakes: sdkmanager.bat semicolon splitting, Expand-Archive failure, a BOM-less Chinese .ps1 (MISTAKES rules 19–21).
- Harness: PASS (analyze 0 issues, 112 tests); `flutter build apk --release` OK, so `MainActivity.kt` now compiles.
- Not verified yet: running on a real phone ("open with" from chat apps, sharing, printing, stylus). The emulator needs Windows Hypervisor Platform (admin + reboot).
- Next: install on a phone and go through the test checklist. Consider `--split-per-abi` (an arm64-only APK is much smaller) and a private release keystore before sharing the APK widely.

## 2026-10-24: v1.4.0 (send, print, import, text tool)
- Done: send as PNG/JPG/PDF/.jypaint via the share sheet; print via the system dialog; import from a file picker and (Android) "open with"; a text tool with full formatting; snapshot-based undo that covers every edit.
- Also fixed: ☁️ emoji warning on web (MISTAKES rule 18); F5 launching the Java debugger (rule 17).
- Mistakes: none reached the user. A generic brush test needed to skip the text tool, and a Kotlin nullable smart-cast error was caught by reading the code, since it can't be compiled here.
- Harness: PASS (analyze 0 issues, 112 tests, build web ok).
- **Not verified:** `MainActivity.kt` and the intent filters have never been compiled or run (no Android SDK). Sharing and printing on a real phone, and how chat apps (WeChat, QQ) label `.jypaint` files, are also untested. These are the first things to check once the APK builds.
- Next: install the Android SDK (Android Studio setup wizard), run `check.ps1 -Build apk`, and test "open with" from a chat app.

## 2026-10-24: v1.3.0 (shapes, eraser range circle, cute fonts)
- Done: 7 shapes with fill that work with every brush, color and opacity; an eraser range circle on long press or hover; 3 OFL cute Chinese fonts plus system (default 快乐体), font picker, licenses page.
- Mistakes: half-clipped text failing the contrast check, a lazy-list finder in tests (see MISTAKES.md). No app bugs reached the user; the harness caught both before reporting.
- Harness: PASS (analyze 0 issues, 84 tests, build web ok, fonts present in the web bundle).
- Not verified yet: how the fonts actually look (widget tests use a box test font), glyph coverage of rare characters (they fall back to the system font), and APK size with fonts (about +15 MB).
- Next: install the Android SDK and build the APK. Consider dropping 黄油体 if the APK size matters.

## 2026-10-24: v1.2.0 (more brushes, cute themes, accessibility)
- Done: spray, rainbow and stamp (heart/star/flower) brushes; a per-brush opacity slider; mirror drawing; paper colors; a collapsible tool panel; cute rounded style; a portable theme module (`lib/theme/`) with 5 JSON themes; WCAG-derived text colors.
- Added harness checks: theme contrast tests, plus Flutter accessibility guidelines (text contrast, 48px tap targets, labels) on 3 screens × 5 themes, plus a 360×640 phone at 1.3× text size in zh and en.
- Mistakes: white text on a pale header, easeOutBack crash, small chip tap targets, off-screen test finders (see MISTAKES.md).
- Harness: PASS (analyze 0 issues, 67 tests, build web ok).
- Not verified yet: APK and real-phone feel (the Android SDK still isn't installed). Widget tests render Chinese and emoji in a box test font, so the visual look still needs checking in Chrome.
- Next: install the Android SDK and build the APK. Possible next features: fill bucket, layers, and an eyedropper color picker.

## 2026-10-24: v1.1.0 (UI refresh, gallery, autosave, languages)
- Done: new header "靖瑶的画板", app icon (`tool/make_icons.ps1`), gradient app bar, colorful bottom navigation, large brush buttons (5 brushes), autosave with reopen-on-launch, My Paintings gallery with dates, year filter and delete, remembered brush/color/size/custom colors, zh (default) and en.
- Code split out of the single `main.dart` into `drawing/`, `gallery/`, `painting_session.dart`, `settings.dart`, `l10n.dart` and `app_theme.dart`.
- Mistakes: ID collision, UTF-8 encoder, delete during autosave (see MISTAKES.md).
- Harness: PASS (analyze 0 issues, 27 tests, build web ok).
- Not verified yet: APK build and on-device behaviour (the Android SDK setup wizard hasn't been run), stylus pressure, and Windows (needs Developer Mode).
- Next: install the Android SDK and build the APK. Consider caching finished strokes as a picture if drawing slows down with hundreds of strokes.

## 2026-10-23: v1.0.0 (first working app)
- Done: set up the toolchain (Flutter 3.47.8 in `C:\dev\flutter`, Android Studio, VS Code Flutter extensions), freehand canvas, colors, size, eraser, undo/redo, save PNG, Chrome debug target.
- Mistakes: Android-only project, gal on web, Windows symlinks, background run without hot reload.
- Harness: analyze clean, 1 test passing, web build ok.
