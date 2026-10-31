# JoyPainting (快乐涂鸦)

JoyPainting is a cute drawing app for Android and iOS phones and tablets, built with Flutter, with a web version too. All of them come from the same code in this repository.

**Try it in a browser:** https://leonfighter1.github.io/JoyPainting/ (any capitals work, also `/joypainting`, and the old `/JingyaoPaint/` forwards) (on iPhone or iPad: open it in Safari, then Share → Add to Home Screen).
The app starts in English and asks for a language, a theme, a drawing level and the little artist's name on first launch; all can be changed any time in Settings. Until v2.1 the app was called JingyaoPaint (靖瑶的画板); the repository moved to https://github.com/leonfighter1/JoyPainting (the old JingyaoPaint repository and web address forward here).

What it does:

- **Drawing levels** (功能等级: 初级 / 中级 / 高级, Beginner / Intermediate / Advanced): the tools drawer shows only what the level includes, so beginners aren't swamped. Beginner: pen, pencil, marker, spray, rainbow, stamps, the paint bucket, text, eraser, colors, shapes and size. Intermediate adds the highlighter, soft brush, move tool, color picker, opacity, free shapes and gradients. Advanced adds the blender, light & shadow, textures and layers. Picked on first start, changed in Settings; paintings look the same at every level.
- **Drawing**:
  - 14 tools: pen, pencil, marker, highlighter, soft brush, blender, spray, rainbow, stamps, paint bucket, text, move, color picker and a round eraser.
  - **Paint bucket** (油漆桶): tap an area to fill it; small gaps in the lines around it are closed for you. The fill is a filled shape like any other: move, recolor, erase or undo it.
  - **Color picker** (吸管): touch the paper and a loupe shows the color under your finger; let go to paint with it (also Alt + click, or I, on a computer).
  - Big paintings stay smooth: thousands of strokes draw, erase and undo without slowing down.
  - Pressure-sensitive strokes, opacity, shapes with fill, mirror drawing and paper colors.
  - Painted looks: the soft brush (blurred, see-through edges for shading and glows), free shapes (draw around an area and it's filled), gradients made from the chosen color (lit top, dark bottom, fade, glow, rounded) and light & shadow (shadow, light, overlay, soft light).
  - Realistic painting: the **blender** (晕染笔) softens and mixes colors already painted, like a finger in wet paint; **textures** (纹理) lay any brush's paint with the grain of canvas, paper, charcoal or bristles.
- **Editing what's drawn** (move tool):
  - Tap a stroke, or drag a box over empty paper to select several at once.
  - Drag to move, drag the corner knob to resize (same proportions), drag the top knob to turn.
  - A bar next to the selection copies, resizes, turns, recolors, changes opacity and deletes. Every change undoes in one step.
- **Canvas**:
  - Pinch to zoom and pan (the paper stays upright: turning it was taken out in 6.6.0 because it slowed everything down); ✋ (or holding Space, or a drag outside the paper) moves the paper with one finger or the mouse.
  - Drag the grips on the paper's right and bottom edges to make it wider or taller (or narrower and shorter). What's drawn keeps its size, and undo puts the paper back. The ☰ menu → 画纸恢复默认大小 makes it fill the screen again.
  - Pin the palette beside the paper (a slim strip under it on an upright phone) to change brushes and colors while drawing.
  - Brushes and colors live in a drawer that opens from the "画笔 · 颜色" button. Its groups open and close with a tap on their heading: the everyday brushes, colors and shapes start open, and the extras of higher levels (more brushes, gradients, light & shadow, textures) start closed. Size and opacity sit right under the colors.
  - The drawer keeps brushes (画笔: pen, pencil, marker, spray to start) apart from helpers (小帮手: eraser, paint bucket, text, and the color picker when added). Save the brush in use, with its size, opacity, color, gradient, light & shadow and texture, as one of 我的画笔; tap it to paint with it again, press it long to delete it.
  - The title bar has, left to right, ✋ (move the paper), 选择移动 (the move tool; tap again to go back to the brush), 清空画布 (a broom) and ☰. Paintings save themselves; 新建画作 is in the ☰ menu.
  - The stamps (印章) are always in the drawer: picking one picks the stamp brush.
  - Brushes, helpers, shapes, stamps, gradients, light & shadow and textures show only their basic choices at first; 「＋ 添加」 in each group (or 添加工具 at the bottom) picks more, several at once: 21 shapes (clouds, moons, lightning, speech bubbles, arcs, waves…), 7 stamps, 10 gradients (rainbow too), 9 kinds of light & shadow and 11 textures (watercolor, crayon, dots, hatching, wood…), as the level allows.
  - At the Advanced level a layers button sits right above the "画笔 · 颜色" button.
  - These buttons and the undo bar can be dragged to any corner of the paper.
- **Kids**:
  - Each kid has their own paintings; the title is their board ("Jingyao's Drawing Board").
  - Switch kids in Settings. Adding or deleting a kid and resetting the app ask a grown-up a multiplication first (like 12 × 15).
- **Paintings**:
  - Autosave, and a gallery (我的画作) with names, dates and a year filter.
  - Export: check paintings (the year filter helps) and export one as its `.jypaint` or several as one `.zip`. Import reads both.
  - Every painting gets a name ("My painting 1" / "我的画作 1"); rename or copy it from the title or its gallery card.
  - **Samples** (示例): a sample painting for each level, shown first for the kid's own level: 快乐的一天 / A Happy Day (beginner: pens, shapes and stamps), 海边的晚霞 / Sunset by the Sea (intermediate: soft brush, gradients, free shapes) or 湖畔晨光 / Dawn on the Lake (advanced: a realistic painting with textures, the blender and light & shadow). Put one into My Paintings when you want it; their names end in 「（示例）」 / "(sample)".
  - **A photo to trace** (导入照片): put a picture under your drawing, half see-through (Intermediate and up).
  - **Coloring book** (涂色本): line drawings to color in, for each level: 8 simple ones (ages 5–8), 6 scenes (about 12) and 6 detailed pages (about 18). The lines stay locked on top, so brushes, the paint bucket and the eraser work under them.
  - **Replay** (回放作画过程): watch a painting draw itself again, stroke by stroke, at ½× to 4×, and save the replay as a looping GIF.
  - **Backup reminders** (备份提醒): My Paintings reminds you to keep a copy when the paintings haven't been backed up for a while; one tap exports them all.
  - Download as PNG, JPG, PDF or SVG (in the apps, pictures go to the photo gallery, and a PDF or SVG to the share menu).
  - SVG (矢量图) keeps every line, shape, fill and gradient as a shape that stays sharp at any size, and text as the outlines of its letters, so a painting can become a logo or go to a printer. PNG and SVG can leave out the paper color (带上纸的颜色) for a see-through background.
  - Send as PNG, JPG, PDF, SVG or an editable `.jypaint` file, named after the painting. In a browser it goes to an email as an attachment.
  - Print from an in-app preview with a big close button (Android's own print screen has none).
  - Open `.jypaint` files received from other apps.
- **Background music**:
  - Plays while you draw and pauses in the background. On/off in the ☰ menu (top right); volume, track and play order (shuffle by default, in order, repeat one) in Settings. Each track ends with 3 quiet seconds before the next.
  - Five calm built-in tracks (阳光散步, 小星星摇篮曲, 欢乐颂, 两只老虎, 云朵飘飘), or add your own (MP3, M4A/AAC, WAV, OGG/Opus, FLAC, MIDI…).
- **Keyboard** (browser, computer, iPad keyboard): Ctrl/⌘+Z undo, Ctrl+Y redo, Ctrl+S save, Ctrl+P print, Ctrl+C/X/V/D copy, cut, paste and duplicate the selection, Ctrl+A select all, Delete, Ctrl +/−/0/1 zoom, Space to move the paper, P/E/T/V tools, I or Alt + click for the color picker, [ ] size, Esc. Press ? for the list.
- **Look**:
  - 5 portable JSON themes checked against WCAG contrast.
  - 4 bundled cute fonts, and a text size slider in Settings (文字大小, 80%–150%, with − and + buttons) that makes all text in the app bigger or smaller, on top of the system's own size.
  - A clear menu button at the top right (☰ ▾) on the canvas and My Paintings.
  - Works on tablets in both orientations.

Package name `com.personal.jingyaopaint`, Dart package `jingyao_paint`. The version is in `pubspec.yaml` (current: **6.6.0**).

## Versions

| Version | Date | Highlights |
|---|---|---|
| **6.6.0** | 2026-10-30 | The paper no longer turns (two fingers, R): a turned paper made every frame two to three times as costly and the app lag; two fingers now only zoom and move it, and the edge grips always show |
| 6.5.0 | 2026-10-30 | Livelier controls: buttons give a little when pressed and spring back, ripples spread from the finger, switches with a jelly knob, sliders whose number glides with the thumb, check marks that draw themselves, rolling counts, ☰ turning into ✕, placeholders while My Paintings loads, and half/full-screen sheets for samples, the coloring book and adding tools |
| 6.4.0 | 2026-10-29 | Download or send a painting as an SVG (矢量图): lines, shapes, fills and text stay sharp at any size, each layer a named group; PNG and SVG can leave the paper color out for a see-through background |
| 6.3.0 | 2026-10-29 | Samples (示例) beside the coloring book, added only when picked, for any level; a coloring book for each level (8 simple pages, 6 scenes for about age 12, 6 detailed pages for about age 18); a four-arrow icon for moving the paper and a finger for select & move |
| 6.2.0 | 2026-10-28 | Opening a big painting shows a card with its name, a progress bar and the percentage; the painting is read and put on the paper a piece at a time, so the screen no longer freezes |
| 6.1.1 | 2026-10-28 | The stamps are always in the drawer (picking one picks the stamp brush); the title bar reads ✋, 选择移动, 清空 (now a broom) |
| 6.1.0 | 2026-10-28 | My own brushes (我的画笔); brushes and helpers (小帮手) apart, each starting with the basic ones; the move tool in the title bar; no save or new buttons there (paintings save themselves; new is in the ☰ menu) |
| 6.0.0 | 2026-10-28 | Add tools as you need them (添加工具): the drawer keeps the basic choices, and a popup adds more, several at once; 14 new shapes (arc and wave too), 4 stamps, 4 gradients, 4 kinds of light & shadow and 6 textures |
| 5.4.3 | 2026-10-28 | Shapes (line, rectangle, circle…) with light & shadow show while you drag them |
| 5.4.2 | 2026-10-28 | Light & shadow (soft light, overlay, highlight) show while you draw, as they look once the finger lifts |
| 5.4.1 | 2026-10-28 | Thin lines with a texture show again; picking a level no longer stalls while its sample painting is added (a card says it's being made); sample paintings are named "（示例）" |
| 5.4.0 | 2026-10-28 | A tidier brushes & colors drawer (groups that open and close, size and opacity under the colors), the layers button floating next to it, 3 quiet seconds between music tracks, a wider keyboard shortcut list |
| 5.3.1 | 2026-10-28 | Download or send a picture without its photo; in a browser, Settings says whether the paintings are kept and can ask the browser to keep them |
| 5.3.0 | 2026-10-28 | A coloring book in My Paintings: 8 line drawings to color in, the lines locked on top so coloring, filling and erasing go under them |
| 5.2.0 | 2026-10-28 | Turn the paper with two fingers (snaps straight; R on a computer), from the Intermediate level |
| 5.1.0 | 2026-10-28 | Add a photo to trace (Intermediate and up): under the drawing, half see-through; on its own locked layer at the Advanced level |
| 5.0.0 | 2026-10-28 | Layers at the Advanced level: add, reorder, hide, lock, rename, merge and fade layers; the eraser and blender work on one layer; exports, replays and GIFs show the layers |
| 4.2.0 | 2026-10-28 | Replay a painting stroke by stroke (with speeds and a slider) and save it as a GIF; backup reminders in My Paintings with a one-tap backup |
| 4.1.0 | 2026-10-28 | The paint bucket, the color picker, big paintings that stay smooth (drawing, erasing and undoing), and a tidier code base behind the drawing screen |
| 4.0.0 | 2026-10-27 | Drawing levels (beginner, intermediate, advanced) chosen on first start, realistic painting tools (the blender, four textures, overlay and soft light), a sample painting for each level, a text size slider, a clearer ☰ menu button |
| 3.0.0 | 2026-10-27 | Painted looks (soft brush, gradients, light & shadow, free shapes, soft edges), a paper resized by dragging its edges (undoable, drawings keep their size), download as PNG, JPG or PDF, a simpler View menu (no zoom buttons), and a faster canvas for big paintings |
| 2.2.0 | 2026-10-25 | Keyboard shortcuts (Ctrl+Z, Ctrl+C/V, Delete, zoom, tool keys; ? lists them), a bigger paper shows at real size, music that copes with old settings and browsers, five calm built-in tracks with shuffle by default, the sample painting 快乐的一天, copying paintings, default kid name 靖瑶 / Athena |
| 2.1.1 | 2026-10-25 | Import/export buttons, export several paintings as a zip, paper up to 4× the screen, pinned palette (slim strip on phones), ✋ move the paper, web loading text in English until the language is set |
| 2.1.0 | 2026-10-25 | Renamed JoyPainting (快乐涂鸦). First-start setup (language, theme, name), several kids with their own paintings, painting names and renaming, music play order, email sending from the web, texts that fit each device, grown-up check for adding/deleting kids and resetting |
| 2.0.0 | 2026-10-25 | First iOS (iPhone and iPad) version. Box-select several strokes; copy, resize, turn, recolor and fade the selection; looping background music (built-in or your own, with volume); print preview with an easy way out |
| 1.6.0 | 2026-10-25 | Draggable corner controls, move tool, round eraser |
| 1.5.0 | 2026-10-25 | Tablet and landscape layouts, pinch zoom, tools drawer, smaller APKs |
| 1.4.0 | 2026-10-24 | Send, print, import `.jypaint`, text tool, undo for every edit; renamed to JingyaoPaint |
| 1.3.0 | 2026-10-24 | Shapes with fill, eraser range circle, cute fonts |
| 1.2.0 | 2026-10-24 | Spray, rainbow and stamp brushes, opacity, mirror drawing, paper colors, themes |
| 1.1.0 | 2026-10-24 | New name and icon, gallery, autosave, Chinese and English |
| 1.0.0 | 2026-10-23 | Freehand drawing, undo/redo, colors, save to album |

The full list of what each version added, with the code and tests behind it, is in [docs/appdev/FEATURES.md](docs/appdev/FEATURES.md).

## Release notes

What changed in each version, newest first, in the app's own words (Chinese UI names in brackets). After each release, [docs/appdev/DEVICE_CHECKLIST.md](docs/appdev/DEVICE_CHECKLIST.md) lists what to try on a real phone or tablet.

### 6.6.0 (2026-10-30): a paper that stays upright

**Changed**
- **The paper doesn't turn any more (转动画纸 is gone).** Turning the paper with two fingers (from the Intermediate level) and with R / Shift+R on a computer made the whole app lag, more so with many strokes. Measured on the 3,000-stroke 高级 sample, every frame took two to three times as long while the paper was turned, because the turned picture has to be redrawn every frame and its rounded edge and shadow lose their fast paths. That cost comes with turning itself, so it was taken out.
- Two fingers now only zoom and move the paper, so a pinch no longer twists it by accident.
- The grips on the paper's right and bottom edges (for resizing it) always show; they used to hide while the paper was turned.
- The zoom chip shows only the zoom (no angle), and the shortcut list (?) no longer has R · Shift+R.

**Good to know**
- Turning a selection (the move tool's top knob, 向左转 / 向右转) is a different thing and stays.
- Not yet tried on a real phone or tablet.

### 6.5.0 (2026-10-30): livelier controls

**New**
- **Buttons you can feel.** Every button (the title bar's, the tools and layers buttons, brushes, colors, the tool chips, and the buttons in menus, sheets and dialogs) shrinks a little while it's held and springs back, just past its size, when let go. A button that can't be used stays still.
- **Ripples from the finger.** Tapping a button or a card starts its ripple exactly where the finger touched, and it spreads from there until it covers the button.
- **Jelly switches.** The switches (播放背景音乐 / Play background music, 备份提醒 / Backup reminders, the download sheet's 照片也放进去 / Include the photo and 带上纸的颜色 / Keep the paper color, 对称绘画 / Mirror drawing in the ☰ menu) have a knob that stretches into a capsule as it slides, squashes against the end and rounds up again.
- **Sliders that glide.** Brush size (笔刷大小), opacity (不透明度), the paint bucket's 补缝隙 (Close gaps), layer opacity, text size, volume and the text tool's font size: the filled track, the thumb and the number in the bubble above it move to the new value together, on one animation, so the number never runs ahead. The numbers beside the sliders (volume, text size, layer opacity, font size) move with them.
- **A check mark that draws itself.** Choosing paintings to export (导出) in My Paintings (我的画作): the check is drawn stroke by stroke, from its lower left up to its upper right, in about 0.2 s.
- **Rolling numbers.** How many paintings are chosen (已选 N 幅 and 导出 N 幅), the count in My Paintings' title, and the percentage while a painting opens roll to their new value, slowing down as they get there.
- **☰ turns into ✕.** While the ☰ menu is open, its top and bottom lines swing into a cross, the middle one fades and the little arrow turns up; closing turns them back.
- **Placeholders while loading.** While My Paintings reads the list of paintings, grey cards the size of the real ones (with lines where the name and date go) stand in the same grid, and each picture waits behind a grey block; when they arrive, they take the placeholders' places and nothing moves. The samples (示例) show a grey block until their picture is painted.
- **Sheets with two heights.** The samples (示例), the coloring book (涂色本) and adding tools (添加工具) open at half the screen. Pull up for the whole screen; pull down past half the sheet's height (or flick down) to close it. Tapping the little bar at the top switches between half and whole.

**Good to know**
- With the system's reduce-motion setting on, buttons, switches, sliders, check marks, numbers and ☰ go straight to where they end up. Ripples and the sheets' snapping still move.
- The replay's timeline (回放作画过程) is still a plain slider, so it shows exactly where the replay is.
- The layers, text, share and selection-color sheets keep fitting their content: they're short, and a full-screen stop would only add empty space.
- There is no like or favorite button, card flipping or card stack in the app, so those effects weren't added.

### 6.4.0 (2026-10-29): SVG pictures, see-through backgrounds

**New**
- **Download or send as SVG (矢量图（SVG）).** In 下载图片 and 发送给别人, pick 矢量图（SVG）. Everything you drew becomes real shapes rather than pixels, so the picture stays sharp however big it's printed or shown: good for a logo, a sign, a T-shirt print or a printer.
  - Lines, shapes, paint-bucket fills, gradients, stamps, spray, rainbow lines, mirrored and turned strokes all come out as shapes.
  - The eraser, light & shadow (multiply, screen and the rest), soft edges and textures look as they do in the app.
  - Text keeps its font: each letter of 快乐体, 黄油体 and 手写体 becomes its outline, so the picture looks the same on a computer without those fonts. Text in the device's own font (系统默认) stays as text.
  - Each shown layer is a group with the layer's name, which Inkscape shows as a layer.
  - What can't be a shape goes in as a picture: photos, and what the blender (混色) smudged.
  - In the apps, the SVG goes to the share menu (save it to Files, or send it); in a browser it downloads.
- **A see-through background (带上纸的颜色).** The download and send menus have a switch: turn it off and PNG and SVG pictures leave the paper's color out, so the drawing sits on whatever it's placed on. JPG and PDF always keep the paper.

**Good to know**
- An SVG of a very big painting can be large: the 3,000-stroke 高级 sample is about 5 MB.
- Textures are repeated small pictures inside the SVG, so they soften a little when shrunk, like any picture.

### 6.3.0 (2026-10-29): samples by choice, a coloring book for each level, clearer icons

**New**
- **Samples (示例) beside the coloring book.** In 我的画作, tap 示例: it opens on your level's sample painting, with 初级 / 中级 / 高级 to look at the others, and says what that level's tools can do. Tap 放进我的画作 to add it, then 打开 in the message to open it.
- **Samples come only when you pick them.** A new kid starts with an empty 我的画作, and changing the level no longer adds a sample. Samples already in 我的画作 stay.
- **A coloring book for every level.** 涂色本 opens on your level, and you can pick another:
  - 初级 (ages 5–8): the 8 big, simple pictures, as before.
  - 中级 (about 12): 海边灯塔, 城堡, 海底世界, 热气球, 猫头鹰, 熊猫: whole scenes with more to color.
  - 高级 (about 18): 曼陀罗花纹, 锦鲤荷塘, 园林亭台, 孔雀, 茶具静物, 小镇街道: detailed pages, every area still big enough for the paint bucket.
- The pictures in the coloring book are sharper.

**Changed**
- **Clearer icons in the title bar**: 拖动画板 (move the paper) is now four arrows, and 选择移动 (select & move) is a finger.

### 6.2.0 (2026-10-28): a progress bar while a painting opens

**New**
- **Opening a big painting shows how far it has got.** When you open a painting with thousands of strokes from 我的画作 (or the app reopens one at start), a card at the top says 正在打开「…」 with a bar and the percentage. It fills up as the painting is read, then as it's put on the paper, and goes away when every stroke is there.
- **The screen no longer freezes while it opens.** The painting is read a piece at a time and painted onto the paper a slice per frame, so the bar keeps moving. A 16,869-stroke painting that froze for about a second and a half now goes on in 14 short frames.
- Small paintings open at once, as before, with no card.

### 6.1.1 (2026-10-28): stamps within reach, a tidier title bar

**Fixed**
- **The stamps (印章) only showed while the stamp brush was in use**, and since 6.1.0 that brush had to be added first, so new stamps couldn't be reached at all. The 印章 group is now always in the drawer (with 「＋ 添加」); tapping a stamp picks the stamp brush with it.

**Changed**
- The title bar reads, left to right: ✋ 拖动画板, 选择移动, 清空画布, ☰.
- 清空画布 has a broom icon (the crossed-out layers looked like something else).

### 6.1.0 (2026-10-28): my own brushes, helpers, and a simpler title bar

**New**
- **我的画笔 (my brushes)**: 「存为我的画笔」 under the brushes saves the one you're using, with its size, opacity, color, gradient, light & shadow and texture, under a name you give it (up to 12). It sits with the brushes, showing its color as a dot; one tap paints with it again, a long press deletes it.
- **小帮手 (helpers)**: tools that aren't brushes have their own group: 橡皮擦, 油漆桶 and 文字, and 吸管 can be added. More helpers can join it later.

**Changed**
- **Brushes** start with 钢笔, 铅笔, 马克笔 and 喷枪; 荧光笔, 柔边笔, 彩虹笔, 印章 and 晕染笔 are added with 「＋ 添加」, as the level allows.
- **The title bar** has 选择移动 (from the Intermediate level; tap it again to go back to your brush), 清空, ✋ and ☰. The 新建 and 保存 buttons are gone: paintings save themselves as you draw (Ctrl+S still saves at once), and 新建画作 is now in the ☰ menu under 画作.
- The pinned palette strip on phones shows the same brushes and helpers as the drawer.

### 6.0.0 (2026-10-28): add the tools you want

**New**
- **Add tools (添加工具)**: shapes, stamps, gradients, light & shadow and textures now show only their basic choices in the brushes & colors drawer. Tap 「＋ 添加」 at the end of a group, or 添加工具 at the bottom, to open a list of everything else, with a little picture of each; tick as many as you like (全选 picks a whole group) and press 完成, and each lands in its own group. Untick one to take it out again. The drawer remembers.
- **14 new shapes**: 圆角矩形, 菱形, 五边形, 六边形, 十字, 云朵, 月亮, 水滴, 闪电, 对话框, 双向箭头, 螺旋, 弧形 and 波浪形. The closed ones can be filled.
- **4 new stamps**: 太阳, 树叶, 爪印, 音符.
- **4 new gradients**: 左右, 斜光, 彩虹 and 撞色 (the color and its opposite).
- **4 new kinds of light & shadow**: 强光, 发光, 加深, and 上色 (gives what's under it your color, keeping its light and shade).
- **6 new textures**: 蜡笔, 水彩, 点彩, 排线, 木纹, 砂纸.

**Changed**
- What each group starts with:
  - 形状: 自由画, 直线, 矩形, 圆形 (and 填充)
  - 印章: 爱心, 星星, 小花
  - 渐变: 不用, 上亮
  - 光影: 普通, 阴影
  - 纹理: 不用, 纸纹
- What can be added follows the level: beginners can add the simpler shapes (arrow, triangle, star, heart, cloud, moon, drop, arc, wave) and the stamps; the intermediate level adds the rest of the shapes, free shapes and gradients; the advanced level adds light & shadow and textures.
- The option you're using always shows in its group, even if it was never added.

**Good to know**
- Paintings with the new shapes open in older versions as their outline drawn with the pen; new stamps show as hearts, and the new light & shadow and textures as plain paint.

### 5.4.3 (2026-10-28): shapes with light & shadow

**Fixed**
- **A shape with light & shadow (光影) stayed invisible while it was dragged**: with 阴影, 提亮, 叠加 or 柔光 on, a line, arrow, rectangle, circle, triangle, star or heart (filled or not) showed nothing until the finger lifted. This came with 5.4.2; freehand lines and free shapes were fine. Every brush, light & shadow and shape is now checked while drawing (560 combinations), also with mirror drawing, a texture, low opacity and a see-through layer.

### 5.4.2 (2026-10-28): light & shadow while drawing

**Fixed**
- **A stroke with light & shadow (光影) could be invisible while it was drawn**: with 柔光 (soft light), 叠加 (overlay) or 提亮 (highlight) on white paper, nothing showed until the finger lifted (found with 自由画 + 炭笔 + 柔光). While drawing, the stroke now mixes with the strokes of its layer, never the paper, exactly as it does once finished. The replay draws it the same way.

**Good to know**
- Finished strokes already mixed only with their own layer; only the stroke being drawn (and being replayed) mixed with the paper.

### 5.4.1 (2026-10-28): thin textured lines, quicker samples

**New**
- While a sample painting is being put into My Paintings (after picking a level), a card at the top says so, with a progress bar, and a message says when it's there.

**Changed**
- Sample paintings are named as samples: 快乐的一天（示例）, 海边的晚霞（示例）, 湖畔晨光（示例） (in English, "(sample)"). Ones already in My Paintings keep their names.

**Fixed**
- **A thin line with a texture (纹理) could barely show, or not at all** (the bristles texture with the thinnest pen): on thin lines the grain now gives way, so the line shows; from a size of about 8 the texture looks as before. Lines drawn earlier look as they did.
- **Picking the Intermediate or Advanced level stalled the app for seconds** while it painted the sample's little picture for My Paintings (4 s in Chrome for 湖畔晨光): the pictures now come ready-made with the app.
- Resetting the app no longer adds a sample painting before the first-start setup.

**Good to know**
- The texture fix is clearest on ordinary (not high-resolution) screens, where thin lines have the fewest pixels.

### 5.4.0 (2026-10-28): a tidier drawer

**New**
- **Groups that open and close** in the brushes & colors drawer: tap a heading (画笔, 更多画笔, 颜料, 形状, 渐变, 光影, 纹理) to open or close it. The everyday groups start open; the extras of the Intermediate and Advanced levels start closed. A closed group shows what's picked in it ("渐变 · 上亮"), and the drawer remembers what you opened.
- **The layers button (图层)** now floats next to the 画笔 · 颜色 button (Advanced level), showing the layer you draw on and how many there are. Drag it to another corner if it's in the way.

**Changed**
- Size and opacity sit right under the colors.
- The tip on how to use a tool (text, eraser, paint bucket…) sits right under the brushes.
- Music: each track ends with 3 quiet seconds before the next one (or, on repeat, the same one again).
- The keyboard shortcut list (?) is 500 points wide, so each line fits; on a small screen it fills the width.

**Fixed**
- Nothing new; see 5.3.1.

**Good to know**
- The layers row at the top of the drawer is gone; use the floating button.

### 5.3.1 (2026-10-28): pictures without the photo

**New**
- **Leave the photo out (照片也放进去)**: a painting with a photo to trace now asks, when you download or send it, whether the photo goes in too. Turn it off and the picture or PDF shows only your drawing. The painting file always keeps the photo.
- **Is the browser keeping the paintings?** In a browser, Settings (under 备份提醒) says whether the browser promised to keep them. If it hasn't, 请浏览器留着 asks it to; if it says no, bookmarking the page or installing it usually helps.

**Changed**
- The download and send choices scroll when they don't fit on a small screen.

**Fixed**
- Nothing new; see 5.3.0.

**Good to know**
- Printing still prints what you see; hide the photo layer (Advanced) to print without it.

### 5.3.0 (2026-10-28): a coloring book

**New**
- **Coloring book (涂色本)**, at every level: in My Paintings, tap 涂色本 and pick one of 8 pictures to color in: a cat, a house, a flower, a fish, a rocket, a butterfly, a car and a tree. It opens as a new painting named after it ("涂色：小猫"). The lines stay on top and can't be changed: color under them with any brush, or tap inside with the paint bucket, and the eraser only takes away your colors.

**Changed**
- My Paintings has a 涂色本 button next to import and export.
- A painting whose top layer is locked opens on the layer under it.

**Fixed**
- Nothing new; see 5.2.0.

**Good to know**
- In versions before 5.3.0 a coloring painting opens with its lines on top, but they aren't locked there, so the eraser can rub them out.

### 5.2.0 (2026-10-28): turn the paper

**New**
- **Turn the paper (转动画纸)**, from the Intermediate level: while pinching with two fingers, turn them and the paper turns too, so a curve can be drawn the way your hand likes. Near straight (and near a quarter turn) it snaps straight. On a computer, R turns it 15° and Shift+R turns it back. The chip at the top shows the angle; tap it to straighten the paper and fit it to the screen again.

**Changed**
- While the paper is turned, the grips on its edges for resizing it are hidden; straighten it to use them.
- The keyboard shortcut list (?) has R · Shift+R.

**Fixed**
- Nothing new; see 5.1.0.

**Good to know**
- Beginners only zoom with two fingers, so the paper doesn't turn by accident.
- Not yet tried with real fingers on a phone or tablet.

### 5.1.0 (2026-10-28): a photo to trace

**New**
- **Add a photo (导入照片（描着画）)**, from the Intermediate level: ☰ → 画纸 → 导入照片 picks a picture (JPG, PNG, GIF, WebP or BMP) and puts it under your drawing, half see-through, ready to trace. A phone photo is turned the right way up and made smaller so the painting stays light; it's fitted inside the paper.
  - Advanced: it goes on its own 照片 Photo layer at the very bottom, locked so you can't move it by accident. In Layers you can make it more or less see-through, hide it to see only your drawing, or unlock it to move it.
  - Intermediate: it sits at the bottom of the drawing; the move tool (选择移动) moves it, makes it bigger or smaller, turns it, and its color & opacity sheet fades it.

**Changed**
- The ☰ menu's 画纸 Paper section has 导入照片 from the Intermediate level.

**Fixed**
- Nothing new; see 5.0.0.

**Good to know**
- The photo is saved inside the painting, so it travels with exports and `.jypaint` files; older versions open the painting without the photo.
- Hide the photo layer before downloading or sending if you want only your drawing (hidden layers are left out).
- iPhone photos in HEIC format can't be read yet; the app says so. Pick a JPG or PNG instead.

### 5.0.0 (2026-10-28): layers

**New**
- **Layers (图层)**, at the Advanced level: the tools drawer now starts with a 图层 row showing the layer you're drawing on and how many there are. Tap it to see the layers, top first:
  - **新建图层 New layer** adds an empty layer above the current one (up to 10) and draws on it.
  - Tap a layer to draw on it. Drag its little preview up or down to change the order.
  - 👁 shows or hides a layer; 🔒 locks it so nothing can be drawn on it or picked from it by accident.
  - The ⋮ menu of a layer renames it, merges it down into the layer below, or deletes it (it asks first if something is drawn on it).
  - The slider at the bottom makes the current layer see-through.
  - Every change to the layers can be undone.
- **What layers are good for**: draw the outline on one layer and color under it on another; the eraser only erases the layer you're on, and the blender only mixes it. Hide a layer to see what's under it, or make a layer of shading see-through to soften it.

**Changed**
- At the Advanced level, the tools drawer has the 图层 row at the top; the brushes come below it.
- New strokes, text, fills and pasted pictures go onto the current layer. The move tool, box selection and Ctrl+A only pick up things on the current layer.
- On a hidden or locked layer, the brushes, text and the paint bucket don't draw; a message says why.
- The color picker and the paint bucket see all shown layers together (fill the space between lines drawn on another layer).

**Fixed**
- Nothing that was broken before; see 4.2.0.

**Good to know**
- Paintings with one layer save exactly as before. A painting with layers opens in older versions with everything shown, stacked in the right order, but hidden layers appear, layer opacity is ignored, and an eraser on an upper layer erases the layers under it too.
- Exports (PNG, JPG, PDF), printing, gallery thumbnails, the replay and the GIF all show the layers as you see them; hidden layers are left out.
- Each layer keeps its own picture on screen, so drawing on one layer doesn't repaint the others; big paintings stay as smooth as in 4.1.
- Not yet tried on a real tablet with many layers.

### 4.2.0 (2026-10-28): replay a painting, save it as a GIF, backup reminders

**New**
- **Replay (回放作画过程)**: watch a painting draw itself again, stroke by stroke, in the order it was made. Open it from the ☰ menu on the canvas (分享 → 回放作画过程) or from a painting's card menu in My Paintings. It starts by itself; ▶ / ⏸ plays and pauses, the slider jumps anywhere, and ½× 1× 2× 4× set the speed. Freehand lines appear as they were drawn, shapes, text and fills appear at once, and the eraser and the blender work as they did. A long painting is sped up so a replay never takes more than 40 seconds.
- **Save the replay as a GIF (存成 GIF 动图)**: on the replay page, one button makes a looping animation of the whole replay (about 10 seconds, the finished painting stays for 2 seconds at the end) and offers it like any export: the share menu in the apps, a download in a browser. A progress bar shows while it's made, and ✕ stops it.
- **Backup reminders (备份提醒)**: paintings live only on this device (or in this browser), so My Paintings now reminds you to keep a copy: when there are three paintings and the first is two weeks old and nothing has been backed up yet, or when something changed and the last backup is two weeks old (one week in a browser that may clear its storage). **一键备份 Back up now** exports every painting as one file; **以后再说 Later** asks again in a week. Exporting every painting yourself counts as a backup too. Each kid has their own reminder; Settings → 备份提醒 turns it off.

**Changed**
- My Paintings' card menu has 回放作画过程 Replay.

**Fixed**
- Nothing new; see 4.1.0.

**Good to know**
- A GIF is made on the device; in a browser it uses fewer, smaller frames so it stays quick.
- The 4.1.0 iOS check on GitHub failed once on the iPhone simulator (the app wasn't running 30 s after launch). This release, which contains all of 4.1.0, passed on both the iPhone and the iPad, so it was a one-off on GitHub's busy Mac machines. The check now also reports the app's log lines on the run page.
- Not yet tried on real devices: replaying very long paintings and making GIFs on an older phone.

### 4.1.0 (2026-10-28): paint bucket, color picker, smooth big paintings

**New**
- **Paint bucket (油漆桶)**: a new tool at every level, next to the stamps. Tap an area and it fills with the chosen color, right up to (and just under) the lines around it, so no white seam shows. Lines don't have to meet: gaps of a few points are closed for you, and from Intermediate a 补缝隙 Close gaps slider (0–6) sets how big a gap is closed. Whatever is inside the area (a dot, a smaller shape) stays as it is. From Intermediate the fill can use the opacity slider and a gradient, and from Advanced light & shadow. The fill is an ordinary filled shape on top: the move tool picks it up, recolors or deletes it, the eraser cuts into it, and one undo takes it away.
- **Color picker (吸管)**: a new tool from Intermediate, next to the move tool. Touch the paper and move: a loupe above your finger shows the paper magnified, ringed with the color under the middle. Let go and that color is the brush color (and joins the recent colors); the tools go back to the brush you were using. It picks the color you see, with shadows, light, textures and see-through paint mixed in. On a computer, Alt + click picks with any tool, and the I key chooses the picker.
- **Smooth big paintings**: what's already painted is kept as one picture, so a new stroke, the eraser and undo no longer paint every stroke again. On a 3,000-stroke painting in Chrome, each frame while drawing took about 190 ms before and about 7 ms now; erasing went from about 640 ms to 7 ms, undo from about 490 ms to 7 ms. The blender also takes the picture under it from there.

**Changed**
- The tools drawer has two more tools (油漆桶 for everyone, 吸管 from Intermediate). The picker and the bucket have no size slider; the keyboard shortcut list (?) includes the picker.
- Behind the scenes, the drawing screen's code was split into small parts (tools, the selection, the view, the menu, the paper), so new tools can be added without touching the rest. Nothing should look or work differently because of it.

**Fixed**
- With ✋ (move the paper) on, putting a second finger down to zoom could leave the paper "stuck" to the next finger: the next stroke moved the paper instead of drawing, and never finished. Now a pinch always ends what the first finger started.

**Good to know**
- A fill is saved as its exact outline (with holes) in a new `area` field. Older versions of the app ignore it and fill around the outside edge, slightly rounded, without the holes.
- In a browser, a fill is worked out on the screen's own thread (about 0.1 s on a 3,000-stroke painting); the apps do it in the background.
- Zoomed far in on a very big paper (past about 16 million pixels), the painting is drawn stroke by stroke as before, so it stays sharp.
- Measured in Chrome (`tool/bench/web_bench.ps1`) and on the Android emulator; not yet tried on a real phone or iPad.

### 4.0.0 (2026-10-27): drawing levels, realistic painting, samples for every level

**New**
- **Drawing levels (功能等级: 初级 / 中级 / 高级)**: the first-start page asks how much the drawing screen should show, and Settings → 功能等级 changes it any time. Beginner shows the everyday tools (pen, pencil, marker, spray, rainbow, stamps, text, eraser, colors, shapes, size). Intermediate adds the highlighter, soft brush, move tool, the opacity slider, free shapes and gradients. Advanced shows everything, including the new blender, light & shadow and textures. Options a level hides act as their plain defaults (full opacity, no gradient…) but are remembered, so they come back with a higher level. Paintings look the same at every level.
- **Blender (晕染笔)**: rub over colors already painted and they soften and mix, like a finger or a dry brush in wet paint. Opacity sets how strongly it mixes; it works as a line, a shape or a free shape. It has no color of its own and is never selected by the move tool.
- **Textures (纹理)**: any brush (and shapes and free shapes) can lay its paint with a grain: 画布 Canvas (woven), 纸纹 Paper (soft grain), 炭笔 Charcoal (rough and broken) or 笔刷痕 Bristles (streaks that follow the stroke, running dry at its end). What's underneath shows through the gaps, as with real paint. Saved in paintings and `.jypaint` files.
- **More light & shadow**: 叠加 Overlay and 柔光 Soft light join 普通, 阴影 and 提亮.
- **A sample painting for each level**: new kids find one in My Paintings that shows what their level can do: 快乐的一天 A Happy Day (beginner), 海边的晚霞 Sunset by the Sea (intermediate, painted only with intermediate tools) or 湖畔晨光 Dawn on the Lake (advanced, a realistic painting with every tool). Picking another level later brings that level's sample too, once. They are ordinary paintings: move, recolor, erase or keep painting on them.
- **Text size (文字大小)**: a slider in Settings, with − and + buttons beside it, makes all text in the app 80% to 150% of its usual size, on top of the phone's own text size.
- **A clearer menu button**: the three faint dots at the top right are now an outlined ☰ ▾ button, on the canvas and in My Paintings.

**Changed**
- The tools drawer is shorter for beginners. Existing users start at Beginner; pick Intermediate or Advanced in Settings → 功能等级 to see every tool again.
- The first-start page has a fourth question (drawing level) and scrolls as one page.

**Fixed**
- On a small phone with large text, the page title no longer runs out of room: it drops the logo first.

**Good to know**
- The blender keeps the blurred picture under each of its strokes until what's under it changes, so a painting full of blending stays quick to redraw.
- Paintings with textures or the blender open in older versions without them (the paint shows plain, blender strokes do nothing).
- Not yet tried on real devices: the blender's speed on an older phone, and textures on iPad.

### 3.0.0 (2026-10-27): painted looks, a resizable paper, download formats

**New**
- **Soft brush (柔边笔)**: a see-through line with blurred edges, for shading, glows and soft light; layers build up like paint.
- **Free shapes (自由形状)**: in the shapes row; draw around an area and it is filled (solid or gradient). Tap anywhere inside to select it.
- **Gradients (渐变)** made from the chosen color: 上亮 lit top, 下暗 dark bottom, 渐淡 fade, 光晕 glow, 立体 rounded. A gradient moves, turns and resizes with its stroke.
- **Light & shadow (光影)**: 阴影 darkens what's underneath, 提亮 lightens it.
- **Resizable paper**: drag the grips on the paper's right and bottom edges to make it wider, taller, narrower or shorter (100 to 8000 points). Drawings keep their size, one undo puts the paper back, and 画纸恢复默认大小 in the menu makes it fill the screen again. Screen readers move the grips in steps.
- **Download image (下载图片)** asks PNG, JPG or PDF. In a browser it downloads; in the apps pictures go to the photo gallery and a PDF to the share menu.

**Changed**
- The View menu has no zoom in / zoom out / fit items; pinch, the mouse wheel, Ctrl +/−/0/1 and the "% · 适应屏幕" chip remain.
- The old 画纸大小 1×–4× choice is replaced by the grips; paintings made with it keep their size.

**Fixed**
- Big paintings no longer repaint every finished stroke for each point of a new one, so drawing on them is smoother.
- Three-color gradients, see-through gradients and the grips under the floating buttons (found while building it).

### 2.2.0 (2026-10-25): keyboard shortcuts, real-size bigger paper, steadier music

**New**
- **Keyboard shortcuts**: Ctrl/⌘+Z undo, Ctrl+Y redo, Ctrl+S save, Ctrl+P print, Ctrl+C/X/V/D copy, cut, paste, duplicate, Ctrl+A select all, Delete, Ctrl +/−/0/1 zoom, Space to move the paper, H for ✋, P/E/T/V tools, [ ] size, Esc. Press ? for the list.
- **Five calm built-in tracks** (阳光散步, 小星星摇篮曲, 欢乐颂, 两只老虎, 云朵飘飘), shuffled by default.
- **Sample painting 快乐的一天 / A Happy Day** for each kid, once.
- **Copy a painting (复制一份)** from its card's menu in My Paintings.
- The first-start page suggests 靖瑶 in Chinese and Athena in English.

**Fixed**
- A bigger paper now shows at real size (before, 4× looked like 1×).
- Music in browsers waits for the first touch and no longer hangs with old settings; a missing track falls back to a built-in one.
- Web releases never run older cached code.

### 2.1.1 (2026-10-25): import/export, bigger paper, pinned palette

**New**
- 导入 / 导出 buttons in My Paintings; export one painting as `.jypaint` or several as a `.zip`, chosen with checkmarks.
- Paper size up to 4× the screen.
- Pin the palette beside the paper (a two-row strip on an upright phone).
- ✋ to move the paper with one finger or the mouse; Space does it on a computer.
- The web loading screen speaks the app's language.

### 2.1.0 (2026-10-25): JoyPainting, first-start setup, kids, painting names

**New**
- Renamed JoyPainting (快乐涂鸦).
- First-start setup: language, theme and the little artist's name.
- Several kids, each with their own paintings and board title; adding or deleting a kid and resetting the app ask a grown-up a multiplication first.
- Every painting has a name; rename it from the title or its card.
- Music play order (repeat one, in order, shuffle); sending by email from the web; texts that fit each device.

### 2.0.0 (2026-10-25): edit what's drawn, background music, print preview

**New**
- Select several strokes with a box; copy, resize, turn, recolor and fade the selection, each in one undo step.
- Looping background music, built-in or your own files, with volume.
- An in-app print preview with a big close button.
- The first iOS (iPhone and iPad) version, and the web version.

### 1.6.0 (2026-10-25): corner controls, move tool, round eraser
- The undo bar and the "画笔 · 颜色" button can be dragged to any corner of the paper.
- The move tool (选择移动) picks up and moves any stroke.
- The eraser is always round, and long-pressing shows its size.

### 1.5.0 (2026-10-25): tablets, zoom, tools drawer
- Tablet and landscape layouts with a side rail; the paper fits any screen.
- Pinch to zoom and pan.
- Brushes and colors moved into a drawer; save, new and clear moved to the top bar.
- Smaller APKs, one per CPU type.

### 1.4.0 (2026-10-24): send, print, text, undo for everything
- Send as PNG, JPG, PDF or an editable `.jypaint`; open `.jypaint` files from other apps.
- Print.
- The text tool with bold, italic, underline, bubble, alignment, size, font and color.
- Every edit can be undone (last 100 steps). Renamed JingyaoPaint.

### 1.3.0 (2026-10-24): shapes, eraser circle, cute fonts
- Shapes (line, arrow, rectangle, circle, triangle, star, heart), filled or not.
- Long-press with the eraser to see its range.
- Four cute fonts to pick in Settings.

### 1.2.0 (2026-10-24): more brushes, opacity, mirror, themes
- Spray, rainbow and stamp brushes; an opacity slider per brush; mirror drawing; six paper colors.
- Five themes with contrast-checked text, screen-reader labels and large tap targets.

### 1.1.0 (2026-10-24): gallery and languages
- New name and icon, My Paintings with autosave, Chinese and English.

### 1.0.0 (2026-10-23): first version
- Freehand drawing with pressure, undo and redo, colors, and saving to the photo album.

## Prerequisites

The project is developed on Windows 10/11 with VS Code. These are the versions it's known to work with:

| Tool | Version used | Needed for |
|---|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (includes Dart) | Flutter 3.47.8, Dart 3.13 | Everything. `pubspec.yaml` requires Dart `^3.13.7`. |
| [Git for Windows](https://git-scm.com/download/win) | any recent | Flutter itself; Git Bash is handy for scripts |
| [VS Code](https://code.visualstudio.com/) + extensions **Dart** and **Flutter** (`Dart-Code.dart-code`, `Dart-Code.flutter`) | latest | Editing, F5 debugging, hot reload |
| [Android Studio](https://developer.android.com/studio) | latest | Ships the JDK (JBR) that Gradle uses, plus the SDK and emulator manager |
| Android SDK packages | see below | Building and running on Android |
| Google Chrome | latest | Fastest debug target (no emulator needed) |
| A Mac with the newest Xcode *(optional)* | latest | Running iOS locally. Without one, GitHub Actions builds iOS (see below). |
| Visual Studio 2022 with "Desktop development with C++" *(optional)* | 2022 | Windows desktop build only |

### Android SDK packages

Install these into `%LOCALAPPDATA%\Android\Sdk` (Android Studio → SDK Manager, or the command line):

- Android SDK Platform 34, 35 and 36
- Android SDK Build-Tools 36.0.0
- NDK (Side by side) 28.2.13676358
- Android SDK Platform-Tools (`adb`)
- Android SDK Command-line Tools (latest)
- Android Emulator, plus an x86_64 Google APIs system image (Android 15 or 16) for testing

Gradle 9.3.1 is downloaded automatically by the wrapper. The Android build targets Java 17.

> **Gotcha:** don't install packages with `sdkmanager.bat "platforms;android-36"` from cmd/PowerShell.
> The batch file splits arguments at `;`. Use the Android Studio SDK Manager, or:
> ```powershell
> & "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\android.exe" --sdk="$env:LOCALAPPDATA\Android\Sdk" sdk install "build-tools;36.0.0"
> ```

### One-time setup

1. Add Flutter to `PATH` (this project uses `C:\dev\flutter\bin`).
2. Point Gradle at Android Studio's JDK: `setx JAVA_HOME "C:\Program Files\Android\Android Studio\jbr"`.
3. Accept the Android licenses: `flutter doctor --android-licenses`.
4. To use emulators, turn on CPU virtualization in the BIOS. Then enable **Windows Hypervisor Platform**:
   - Open "Turn Windows features on or off".
   - Check Windows Hypervisor Platform.
   - Reboot.
5. Optional (Windows desktop builds): turn on **Developer Mode** in Windows Settings so Flutter can create symlinks.
6. Check everything:
   ```powershell
   flutter doctor -v
   ```
   You need green checks for Flutter, Android toolchain, Chrome and VS Code. Visual Studio is only needed for Windows builds.

## Testing environments

| Environment | How to get it | Use it for |
|---|---|---|
| Chrome | Installed with Chrome | Quick UI work and hot reload. "Save to album" downloads a file instead, and phone-only features ("open with", the photo album) don't apply. |
| Phone emulator | AVD `medium_phone` (1080×2400) | Default phone layout |
| Tablet emulator | AVD `medium_tablet` (2560×1600) | Side rail, landscape/portrait, paper scaling |
| Chrome benchmark | `tool\bench\web_bench.ps1` | How smooth a 3,000-stroke painting is. The emulators on this PC often crash on paintings that big, so heavy measurements run in Chrome. |
| Real Android device | USB debugging on, then `adb devices` | Stylus pressure, real pinch, sharing to chat apps, printing |
| iPhone and iPad simulators | GitHub Actions (`.github/workflows/ios.yml`) or a Mac | The real iOS build: starts on the newest iPhone and iPad and leaves screenshots |

Create and start the emulators with Android Studio's Device Manager, or:

```powershell
$android = "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\android.exe"
& $android emulator create medium_tablet
& $android emulator start medium_tablet
```

If an emulator shows a black screen, cold-boot it:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd medium_tablet -no-snapshot-load -gpu host
```

## Run and debug

Get the code and open the repository folder itself in VS Code:

```powershell
git clone https://github.com/leonfighter1/JoyPainting.git
code JoyPainting
```

Press **F5**. `.vscode/launch.json` offers three configurations:

- **JingyaoPaint (debug)**: a running emulator or connected phone.
- **JingyaoPaint (Chrome)**
- **JingyaoPaint (Windows)**

From a terminal in this folder:

```powershell
flutter pub get
flutter run -d chrome          # browser
flutter devices                # list emulators/phones
flutter run -d emulator-5554   # a running emulator
```

## Tests

```powershell
flutter analyze   # must report "No issues found!"
flutter test      # unit, rendering and widget tests
```

What the tests cover:

- **`test/brush_test.dart`**: pixel tests for brushes and shapes, the text tool, moving strokes and save/reload.
- **`test/selection_test.dart`**: turning and resizing strokes (pixels, hits, saving), box selection, and the move tool's knobs, bar and color sheet.
- **`test/music_test.dart`**: the music library, the looping player (on/off, volume, background pause, fallback) and the music settings.
- **`test/print_test.dart`**: the print preview's close buttons, Back, printing and page orientation.
- **`test/ios_test.dart`**: the app running as iOS (scrolling, transitions and text editing differ per platform), Apple's music formats and the iPad share-sheet anchor.
- **`test/v21_test.dart`**: first-start setup, painting names, kids and the grown-up check, reset, music play order, texts per device.
- **`test/v211_test.dart`**: zip export/import, choosing paintings to export, paper size, the pinned palette and strip, moving the paper.
- **`test/v22_test.dart`**: the bigger paper at real size, keyboard shortcuts, copying paintings, the sample painting, the default kid name.
- **`test/v3_test.dart`**: the soft brush, gradients, light & shadow, free shapes, the paper grips, the menu's download formats, and accessibility of the new options in every theme.
- **`test/v4_test.dart`**: textures (pixels, saving), the blender (mixing, opacity, following what's under it, while drawing), drawing levels (what each shows, hidden options, first start, Settings), the menu button, text size (buttons, slider, largest text on a small phone), the sample painting for each level, and accessibility in every theme.
- **`test/canvas_logic_test.dart`**: the drawing screen's parts on their own: the selection (move, box select, copy, cut, paste), the view (zoom limits, pinch, dragging the paper), the keyboard shortcut map, new strokes from the tools drawer, and a pinch during ✋.
- **`test/layer_cache_test.dart`**: the kept picture of a painting looks the same as painting every stroke (paint, shadows, see-through paint, the eraser, the blender), and is painted again only when it must (not for new strokes, erasing, undo or redo).
- **`test/picker_test.dart`**: the color seen at a point (paint, paper, shadows, see-through paint), the picker's loupe and its return to the last brush, and picking a color off the canvas.
- **`test/fill_test.dart`**: filling inside and outside lines, closing gaps, holes, blank paper, the fill as a stroke (saving, moving, exact corners), and filling a drawn ring on the canvas.
- **`test/rotation_test.dart`**: the paper staying upright (since 6.6.0): two fingers that turn only zoom and move it, R is no shortcut, and the grips stay.
- **`test/add_tools_test.dart`**: the drawer's basic choices (brushes and helpers too), adding several at once and taking them out, 取消, what each level can add, the chosen option staying in sight; 我的画笔 (saving, picking again, deleting, kept in settings); every shape (in its box, closed ones closed, the outline saved for older versions, arc and wave), every stamp, the new gradients, and the new light & shadow and textures being saved.
- **`test/live_stroke_test.dart`**: every brush, light & shadow and shape (each combination, then mirror drawing, a texture, low opacity and a see-through layer) shows while it is drawn as it will once finished, with the layers repainted only on their signal, as the screen does.
- **`test/drawer_test.dart`**: the tools drawer's groups (which start open, opening and closing them, what a closed one shows, its screen reader state), size and opacity under the colors, and the layers button (next to the tools button, following it until dragged, never onto undo's corner, opening the layers).
- **`test/ui_motion_test.dart`**: the control motions: buttons shrinking to 96 % and springing past their size (not when disabled), the switch's knob stretching, squashing and rounding up, ripples staying under the finger (and a long press cancelling one), the check drawing itself, the slider's thumb, fill and number moving together (and stepping by screen reader), numbers rolling slower near the end, My Paintings' placeholders replaced in place, ☰ becoming ✕ and back, and sheets resting at half and whole and closing when pulled down.
- **`test/coloring_test.dart`**: every coloring page (lines on a locked top layer, the layer under them active, the lines never picked up, closed areas the paint bucket fills without leaking) and opening one from My Paintings.
- **`test/photo_test.dart`**: a photo on the paper (saved with its picture, moved, hit inside its box), painted at its opacity, made smaller and fitted, refused when unreadable, put under the drawing or on a locked layer at the bottom, the menu item by level, and leaving the photo out of pictures (the switch in the format sheet).
- **`test/layers_test.dart`**: layers in the drawing (adding above the active one, keeping strokes in layer order, moving, merging, deleting, undo), picking only from the active shown and unlocked layer, saving layers, painting them (the eraser on its own layer, hidden and see-through layers, one kept picture per layer), the layers panel, and refusing to draw on a hidden layer.
- **`test/replay_test.dart`**: the replay's timeline (order, point by point, the 40-second limit), its last frame matching the painting, the eraser while replayed, the GIF (header, frames, cancelling) and the replay page (play, pause, playing to the end).
- **`test/backup_test.dart`**: when the backup reminder shows (never backed up, changed since, a browser that may clear its storage, "later"), per kid, the one-tap backup exporting every painting, the Settings switch, and the browser's promise to keep the paintings (asking for it).
- **`test/web_store_test.dart`**: saving paintings in the browser (IndexedDB), moving old localStorage data over. Browser only: `flutter test --platform chrome test/web_store_test.dart` (the Web workflow runs it).
- **`test/model_test.dart`**: the painting store, autosave and import.
- **`test/export_test.dart`**: real PNG, JPEG and PDF output, and `.jypaint` round trips.
- **`test/svg_export_test.dart`**: SVG export: valid XML with the paper and named layers, every reference defined, gradients, textures, blend modes, blur, the eraser, pictures and text outlines kept; corners exact and curves close; letters read from the font file; the see-through background; the download sheet.
- **`test/svg_web_test.dart`**: the SVG export with the web engine measuring paths and text. Browser only: `flutter test --platform chrome test/svg_web_test.dart` (the Web workflow runs it).
- **`test/theme_test.dart`**: theme JSON and WCAG contrast.
- **`test/widget_test.dart`**: the whole UI, including:
  - phone, tablet and landscape sizes;
  - both languages;
  - large text;
  - Flutter's accessibility guidelines: text contrast, 48 dp tap targets and labels.

Before calling a change done, run analyze and test, then try it on the tablet emulator.

How smooth big paintings are (frame times with and without the kept picture, and how long a fill takes):

```powershell
# Chrome, on the 3,000-stroke sample; opens a separate Chrome window for a few minutes
powershell -ExecutionPolicy Bypass -File tool\bench\web_bench.ps1
# The same with the view turned against upright (why 6.6.0 took turning out)
powershell -ExecutionPolicy Bypass -File tool\bench\web_bench.ps1 -Bench turn
# A phone or emulator, in profile mode
flutter drive --profile --driver=test_driver/integration_test.dart --target=integration_test/draw_perf_test.dart -d <device>
```

A quick check of a release APK on an emulator (installs, starts, draws, checks the log): `powershell -ExecutionPolicy Bypass -File tool\android_smoke.ps1`.

## Build a release APK

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_apk.ps1             # one small APK per CPU type
powershell -ExecutionPolicy Bypass -File tool\build_apk.ps1 -Universal  # one big APK for every device
```

APKs land in `dist\` as `JoyPainting-v<version>-<abi>.apk`:

- **arm64**: almost every phone and tablet.
- **armv7**: old 32-bit phones.
- **x86_64**: emulators.

Builds are obfuscated. Crash symbols go to `build\symbols\<version>`; keep them to read stack traces. The APK is signed with the debug key, which is fine for sideloading but not for the Play Store.

Install on a running emulator or a connected phone:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r dist\JoyPainting-v2.0.0-x86_64.apk
```

To release a new version:

1. Bump `version:` in `pubspec.yaml` (the build number after `+` too: Android needs it to go up).
2. Bump `appVersion` in `lib/settings_page.dart`.
3. Add a row to the Versions table above and a section to `docs/appdev/FEATURES.md`.

## Web version

Published to GitHub Pages by `.github/workflows/web.yml` on every push to `main`: https://leonfighter1.github.io/JoyPainting/

- **iPhone/iPad**: open the link in Safari, tap Share → **Add to Home Screen**. It then opens full screen from its own icon, with no signing and no expiry.
- **Paintings** are saved in the browser (IndexedDB, hundreds of MB) on that device only. Deleting Safari's website data deletes them. Send a painting as a `.jypaint` file to keep a copy.
- **Differences from the apps**: 下载图片 downloads the PNG, JPG or PDF; background music starts at the first tap (browsers block sound before that), and added music lasts until the page reloads.
- The rendering engine is served from the site itself, not Google's CDN.
- **One-time setup** (already needed once per repository): Settings → Pages → Build and deployment → Source: **GitHub Actions**.
- **Any capitals**: GitHub Pages matches paths letter for letter, so the account's root site, https://github.com/leonfighter1/leonfighter1.github.io, catches every other spelling in its `404.html` and forwards `/joypainting` or `/jingyaopaint` (any capitals) here; its front page opens the app too.
- **Custom domain later**: build with `--base-href /` and set the domain under Settings → Pages.

## iOS

iOS builds need macOS and Xcode, so they run on GitHub's Macs (free for this public repository). Every push to `main` (or a manual run under Actions → iOS → Run workflow) does:

1. Analyze and test.
2. Build an unsigned release build for iPhone and iPad with the newest stable Xcode, which targets the newest iOS.
3. Start the app on the newest iPhone and iPad Pro simulators. A crash on launch fails the run.

The screenshots and app logs are under the run's **Artifacts → ios-screenshots**. The builds are under **Artifacts → ios-builds**:

- `JoyPainting-v<version>-ios-unsigned.ipa`: for iPhone and iPad. It is unsigned, so it has to be signed before it installs: with an Apple Developer account, or for personal use with a free Apple ID through a sideloading tool (the app then expires after 7 days).
- `JoyPainting-v<version>-ios-simulator.zip`: for a Mac's Simulator, or a browser simulator such as Appetize, where you can try it from Windows.

Artifacts are kept for 90 days and need a GitHub login to download.

The iOS app needs iOS 15 or later. Its bundle ID `com.personal.jingyaopaint` matches the Android package. iOS-specific parts:

- `ios/Runner/Info.plist`: Chinese and English localizations, Photos permission texts and the `.jypaint` document type.
- `ios/Runner/AppDelegate.swift`: "Open in JoyPainting" for `.jypaint` files, on the same channel as Android's `MainActivity.kt`.
- Background music uses the "ambient" audio session: the silent switch mutes it, and it plays along with other apps' audio.
- The app icon comes from `tool/make_icons.ps1`.

To install on a real iPhone or iPad, or to share through TestFlight, you need an Apple Developer account and signing set up. The workflow doesn't do that yet. On a Mac, you can run the app directly: `flutter run -d <simulator or device>`.

## Project layout

```
lib/
  main.dart            app shell: tabs or side rail, theme, incoming files
  drawing/             the drawing screen, strokes, layers, drawing controller, text editor
    canvas/            its parts: tools (draw, text, move, pan, picker, fill), selection, view, menu, paper, drawer
    render/            strokes into pictures: the kept picture, reading pixels, filling areas
    replay/            playing a painting back, and making the GIF
  gallery/             My Paintings page and storage (file / browser / memory), backup reminders, the coloring book
  music/               background music: track library, saved uploads, looping player
  share/               send, print preview, import, .jypaint format
  theme/               portable JSON themes, contrast math, fonts (see theme/README.md)
  widgets/             drop-down menu and its button, draggable corner controls, the control motions (press bounce, elastic switch, liquid slider, drawn check, rolling numbers, skeletons, half/full sheets)
  l10n.dart            all UI text, zh and en
  settings.dart        remembered choices (brush, colors, corners, theme, level, text size…)
  skill_level.dart     what each drawing level shows
assets/                logo, theme JSON files, fonts and their OFL licenses, built-in music, the level sample paintings, the coloring pages
android/               Android host app (MainActivity handles "open with")
ios/                   iOS host app (AppDelegate handles "Open in", Info.plist)
.github/workflows/     ios.yml (iOS build on GitHub's Macs), web.yml (publishes the web version)
tool/                  build_apk.ps1, watch_build.ps1, make_icons.ps1, make_music.dart, ios_sim_smoke.sh, android_smoke.ps1; samples/ (makes the level sample paintings in assets/samples/); coloring/ (makes the coloring pages in assets/coloring/); bench/ (how smooth big paintings are, in Chrome)
integration_test/      the same measurement on a device (driven by test_driver/)
local_art/             not in git: pictures made locally with the app's brushes
docs/appdev/           FEATURES.md, MISTAKES.md, DEVLOG.md, TECH_PLAN.md (the improvement plan), DEVICE_CHECKLIST.md (what to try on a real device)
test/                  see Tests above
```

Read `docs/appdev/MISTAKES.md` before making changes. Its rules come from problems this project has already hit.
