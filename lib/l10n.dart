import 'package:flutter/widgets.dart';

import 'device.dart';
import 'drawing/stroke.dart';
import 'gallery/coloring_pages.dart' show ColoringPage;
import 'skill_level.dart';
import 'settings.dart' show MusicMode;

/// All user-facing text, in Simplified Chinese (default) and English.
class S {
  const S(this.languageCode);

  final String languageCode;

  static S of(BuildContext context) =>
      S(Localizations.localeOf(context).languageCode);

  bool get _zh => languageCode != 'en';
  String _t(String zh, String en) => _zh ? zh : en;

  /// What the system knows the app as (share sheets, file pickers, the
  /// browser tab).
  String get appName => _t('快乐涂鸦', 'JoyPainting');

  /// The title over the canvas: the kid's own board.
  String boardTitle(String kidName) => kidName.isEmpty
      ? _t('我的画板', 'My Drawing Board')
      : _t('$kidName的画板', "$kidName's Drawing Board");

  /// Texts that differ by device ask this.
  Device get _device => Device.current;

  // First start
  String get welcomeTitle => _t('欢迎来画画！', 'Welcome!');
  String get welcomeBody => _t('选一种语言和喜欢的主题，再写下小画家的名字。',
      "Pick a language and a theme you like, then tell us the little artist's name.");
  String get kidNameLabel => _t('小画家的名字', "Little artist's name");
  String get kidNameHint => _t('例如：靖瑶', 'For example: Athena');

  /// The name the first-start setup suggests, in each language.
  String get defaultKidName => _t('靖瑶', 'Athena');
  String get startDrawing => _t('开始画画', 'Start drawing');

  // Painting names
  String defaultPaintingName(int n) => _t('我的画作 $n', 'My painting $n');
  String get rename => _t('重命名', 'Rename');
  String get duplicatePainting => _t('复制一份', 'Make a copy');
  String copyName(String name) =>
      _t('$name 副本', '$name (copy)');
  String paintingCopied(String name) =>
      _t('已复制为“$name”', 'Copied as "$name"');
  String get copyFailed => _t('没能复制，再试一次', "Couldn't copy it. Try again");
  String get samplePaintingName => _t('快乐的一天', 'A Happy Day');
  String get sampleGreeting => _t('你好呀！', 'Hello!');
  String get sampleSunsetName => _t('海边的晚霞', 'Sunset by the Sea');
  String get sampleLakeName => _t('湖畔晨光', 'Dawn on the Lake');
  String get renameTitle => _t('给画作起个名字', 'Name this painting');
  String get nameLabel => _t('名字', 'Name');
  String get save => _t('保存', 'Save');
  String renamed(String name) => _t('已改名为“$name”', 'Renamed to "$name"');

  // Kids
  String get kids => _t('小画家', 'Kids');
  String get addKid => _t('添加小画家', 'Add a kid');
  String get changeKidName => _t('改名字', 'Change name');
  String get noKidName => _t('（还没有名字）', '(no name yet)');
  String get usingNow => _t('正在画', 'Drawing now');
  String deleteKidTitle(String name) =>
      _t('删除“$name”和TA的所有画作？', 'Delete $name and all of their paintings?');
  String get deleteKidBody =>
      _t('删除后无法恢复。', "This can't be undone.");
  String switchedTo(String name) =>
      _t('现在是 $name 在画画', 'Now drawing: $name');
  String get resetApp => _t('重置整个应用', 'Reset the whole app');
  String get resetAppBody => _t(
      '会删除所有小画家、画作、上传的音乐和设置，回到第一次打开的样子。无法恢复。',
      "Deletes every kid, painting, added music and setting, back to a fresh start. This can't be undone.");
  String get reset => _t('重置', 'Reset');

  // Grown-up check
  String get parentCheck => _t('请家长来回答', 'Grown-ups only');
  String get parentCheckHint =>
      _t('答对这道题才能继续：', 'Answer this to continue:');
  String get answer => _t('答案', 'Answer');
  String get wrongAnswer =>
      _t('不对哦，换一道题再试试', 'Not quite. Try this one.');

  // Music play order
  String get musicPlayOrder => _t('播放方式', 'Play order');
  String musicModeName(MusicMode mode) => switch (mode) {
        MusicMode.repeatOne => _t('单曲循环', 'Repeat one'),
        MusicMode.sequence => _t('顺序播放', 'In order'),
        MusicMode.shuffle => _t('随机播放', 'Shuffle'),
      };

  // Sending on the web
  String get sendHintWeb => _t(
      '会打开分享菜单，选“邮件”就能把画作当附件发出去。',
      'Opens the share menu. Choose Mail to send the painting as an attachment.');
  String mailSubject(String name) =>
      _t('我的画作：$name', 'My painting: $name');
  String mailBody(String file) => _t(
      '给你看我画的画！附件是“$file”。',
      'Here is my painting! "$file" is attached.');
  String mailFallback(String file) => _t(
      '已下载“$file”，并打开了一封新邮件。把这个文件添加到邮件附件里就可以发送了。',
      'Downloaded "$file" and opened a new email. Attach that file to it and send.');

  /// Which version this is, for About.
  String get runsOn => switch (_device.kind) {
        DeviceKind.android => _t('Android 版', 'for Android'),
        DeviceKind.apple => _t('iPhone 和 iPad 版', 'for iPhone and iPad'),
        DeviceKind.web => _device.browser == null
            ? _t('网页版', 'web version')
            : _t('网页版 · ${_device.browser}', 'web version · ${_device.browser}'),
        DeviceKind.desktop => _t('电脑版', 'for computers'),
      };

  // Navigation
  String get navCanvas => _t('画板', 'Canvas');
  String get navGallery => _t('我的画作', 'My Paintings');
  String get navSettings => _t('设置', 'Settings');

  // Canvas actions
  String get undo => _t('撤销', 'Undo');
  String get redo => _t('重做', 'Redo');
  String get newPainting => _t('新建画作', 'New painting');
  String get more => _t('更多', 'More');
  String get clear => _t('清空画布', 'Clear canvas');
  String get replay => _t('回放作画过程', 'Replay the painting');
  String replayLabel(String name) =>
      _t('「$name」的作画过程', 'How "$name" was painted');
  String get play => _t('播放', 'Play');
  String get pause => _t('暂停', 'Pause');
  String get saveGif => _t('存成 GIF 动图', 'Save as GIF');
  String get makingGif => _t('正在制作 GIF…', 'Making the GIF…');
  String replayFileName(String name) => '${name}_${_t('回放', 'replay')}.gif';
  String get coloringBook => _t('涂色本', 'Coloring book');
  String get coloringBookHint => _t(
      '选一张线稿开始涂色。线稿锁在最上面，涂色、填色都在线下面，橡皮擦不会擦掉线。',
      'Pick a page to color. Its lines stay on top: coloring and filling go under them, and the eraser leaves them alone.');
  String coloringPainting(String name) => _t('涂色：$name', 'Coloring: $name');
  String coloringName(ColoringPage page) => switch (page) {
        ColoringPage.cat => _t('小猫', 'Cat'),
        ColoringPage.house => _t('小房子', 'House'),
        ColoringPage.flower => _t('花朵', 'Flower'),
        ColoringPage.fish => _t('小鱼', 'Fish'),
        ColoringPage.rocket => _t('火箭', 'Rocket'),
        ColoringPage.butterfly => _t('蝴蝶', 'Butterfly'),
        ColoringPage.car => _t('小汽车', 'Car'),
        ColoringPage.tree => _t('大树', 'Tree'),
      };
  String get importPhoto => _t('导入照片（描着画）', 'Add a photo (to trace)');
  String get photoLayer => _t('照片', 'Photo');
  String get photoAddedOnLayer => _t(
      '照片放在最底下单独的「照片」图层里，半透明并锁住了，可以放心描着画。在图层里可以调它的透明度。',
      'The photo is on its own "Photo" layer at the bottom, see-through and locked, so you can trace it. Change its opacity in Layers.');
  String get photoAdded => _t(
      '照片放在最底下，半透明，可以描着画。用「选择移动」可以挪动、放大缩小或调透明度。',
      'The photo is at the bottom, see-through, ready to trace. The move tool moves, resizes or fades it.');
  String get photoUnreadable =>
      _t('这张图片读不出来，换一张试试（JPG、PNG 都可以）。', "This picture can't be read: try another (JPG or PNG).");
  String get layers => _t('图层', 'Layers');
  String layerName(int n) => _t('图层 $n', 'Layer $n');
  String layersButton(String name, int count) =>
      _t('$name（共 $count 层）', '$name ($count in all)');
  String get addLayer => _t('新建图层', 'New layer');
  String get deleteLayer => _t('删除图层', 'Delete layer');
  String deleteLayerBody(String name) =>
      _t('「$name」上画的东西会一起删除。可以撤销。', 'What is drawn on "$name" goes too. You can undo it.');
  String get mergeDown => _t('向下合并', 'Merge down');
  String get renameLayer => _t('重命名图层', 'Rename layer');
  String get showLayer => _t('显示图层', 'Show layer');
  String get hideLayer => _t('隐藏图层', 'Hide layer');
  String get lockLayer => _t('锁定图层', 'Lock layer');
  String get unlockLayer => _t('解锁图层', 'Unlock layer');
  String get layerOpacity => _t('图层不透明度', 'Layer opacity');
  String get layerHidden =>
      _t('这个图层隐藏了，先让它显示出来再画。', 'This layer is hidden: show it to draw on it.');
  String get layerLocked =>
      _t('这个图层锁住了，先解锁再画。', 'This layer is locked: unlock it to draw on it.');
  String get tooManyLayers => _t('最多 10 个图层', '10 layers at most');
  String get neverBackedUp => _t('这些画还没有备份过', "These paintings haven't been backed up");
  String lastBackedUp(int days) => days <= 0
      ? _t('今天备份过', 'Backed up today')
      : _t('上次备份是 $days 天前', 'Last backed up $days ${days == 1 ? 'day' : 'days'} ago');
  String get backupWhyBrowser => _t(
      '画存在这个浏览器里：清理浏览器数据或换设备时会一起消失。导出一份存到电脑或网盘更安心。',
      'The paintings live in this browser: clearing its data or changing devices loses them. Export a copy to keep somewhere safe.');
  String get backupWhyDevice => _t(
      '画只存在这台设备上：换手机或设备坏了就找不回来了。导出一份存起来更安心。',
      'The paintings live only on this device: a new or broken device loses them. Export a copy to keep somewhere safe.');
  String get backupNow => _t('一键备份', 'Back up now');
  String get later => _t('以后再说', 'Later');
  String get backupReminders => _t('备份提醒', 'Backup reminders');
  String get backupRemindersHint => _t(
      '画有一阵子没备份时，在「我的画作」上方提醒，一键把全部画作导出成一个文件。',
      'When the paintings have not been backed up for a while, My Paintings reminds you and exports them all as one file in one tap.');
  String get storageKept => _t('这个浏览器会一直留着这些画', 'This browser keeps the paintings');
  String get storageKeptHint => _t(
      '浏览器答应了不会自己清除。清除浏览数据或换电脑前，还是要先备份。',
      'It promised not to clear them by itself. Back them up before clearing browsing data or changing computers.');
  String get storageAtRisk => _t('浏览器空间不够时，可能会清除这些画', 'The browser may clear the paintings when space runs low');
  String get storageAtRiskHint => _t(
      '记得经常备份。也可以请浏览器把它们留着。',
      'Back them up often. You can also ask the browser to keep them.');
  String get askToKeep => _t('请浏览器留着', 'Ask to keep them');
  String get keepGranted => _t('浏览器答应留着这些画了', 'The browser will keep the paintings');
  String get keepRefused => _t(
      '浏览器没有答应。把这个网页加入书签或安装到桌面后，再试一次。',
      'The browser said no. Bookmark this page or install it, then try again.');
  String get downloadImage => _t('下载图片', 'Download image');
  String get downloadAs => _t('选择下载格式', 'Download as');
  String get exportPhotos => _t('照片也放进去', 'Include the photo');
  String get exportPhotosHint => _t('关掉后，图片和 PDF 里只有画的部分',
      'When off, pictures and PDFs show only what was drawn');
  String get downloadHintApps => _t('PNG 和 JPG 存进相册；PDF 在分享菜单里存到文件。',
      'PNG and JPG go to your photos; save a PDF to Files from the share menu.');
  String get clearTitle => _t('清空画布？', 'Clear canvas?');
  String get clearBody =>
      _t('清空后可以用“撤销”找回。', 'You can bring it back with Undo.');
  String get cancel => _t('取消', 'Cancel');
  String get confirm => _t('确定', 'OK');
  String get delete => _t('删除', 'Delete');
  String get savedToGallery => switch (_device.kind) {
        DeviceKind.apple => _t('已保存到“照片”的“快乐涂鸦”相簿',
            'Saved to Photos (album: JoyPainting)'),
        DeviceKind.desktop => _t('已保存到“图片”文件夹（JoyPainting）',
            'Saved to Pictures (folder: JoyPainting)'),
        _ => _t('已保存到相册（快乐涂鸦）',
            'Saved to gallery (album: JoyPainting)'),
      };
  String downloaded(String file) => _t('已下载 $file', 'Downloaded $file');
  String saveFailed(Object e) => _t('保存失败：$e', 'Save failed: $e');
  String autosaveFailed(Object e) =>
      _t('自动保存失败：$e', 'Autosave failed: $e');
  String get newPaintingStarted => _t('已新建画作', 'Started a new painting');
  String get openFailed => _t('无法打开这幅画', "Couldn't open this painting");

  // Tools
  String get tools => _t('画笔', 'Brushes');
  String get colors => _t('颜料', 'Colors');
  String get brushSize => _t('笔刷大小', 'Brush size');
  String get pickColor => _t('选择颜色', 'Pick a color');
  String get moreColors => _t('更多颜色', 'More colors');
  String get useColor => _t('使用', 'Use');
  String brushName(BrushType b) => switch (b) {
        BrushType.pen => _t('钢笔', 'Pen'),
        BrushType.pencil => _t('铅笔', 'Pencil'),
        BrushType.marker => _t('马克笔', 'Marker'),
        BrushType.highlighter => _t('荧光笔', 'Highlighter'),
        BrushType.soft => _t('柔边笔', 'Soft brush'),
        BrushType.smudge => _t('晕染笔', 'Blender'),
        BrushType.spray => _t('喷枪', 'Spray'),
        BrushType.rainbow => _t('彩虹笔', 'Rainbow'),
        BrushType.stamp => _t('印章', 'Stamps'),
        BrushType.bucket => _t('油漆桶', 'Paint bucket'),
        BrushType.text => _t('文字', 'Text'),
        BrushType.move => _t('选择移动', 'Move'),
        BrushType.picker => _t('吸管', 'Color picker'),
        BrushType.eraser => _t('橡皮擦', 'Eraser'),
      };
  String stampName(StampShape s) => switch (s) {
        StampShape.heart => _t('爱心', 'Heart'),
        StampShape.star => _t('星星', 'Star'),
        StampShape.flower => _t('小花', 'Flower'),
      };
  // Move tool and eraser hints
  String get moveHint => _t(
      '点一下某一笔选中它；在空白处拖出方框，可以一次选中好几笔。拖动移动，'
          '拖右下角的圆钮放大缩小，拖上方的圆钮旋转。上方的按钮还能复制、改颜色和透明度。',
      'Tap a stroke to select it, or drag a box over empty paper to select '
          'several. Drag to move, drag the bottom-right knob to resize and the '
          'top knob to turn. The bar at the top copies, recolors and fades them.');

  // Move tool selection
  String selectedCount(int n) => _t('已选 $n 个', '$n selected');
  String get duplicate => _t('复制', 'Copy');
  String get makeBigger => _t('放大', 'Bigger');
  String get makeSmaller => _t('缩小', 'Smaller');
  String get turnLeft => _t('向左转', 'Turn left');
  String get turnRight => _t('向右转', 'Turn right');
  String get colorAndOpacity => _t('颜色和透明度', 'Color and opacity');
  String get deleteSelection => _t('删除选中的', 'Delete selected');
  String get rainbowKeepsColors =>
      _t('彩虹笔画的线会保留彩虹色，只改透明度。', 'Rainbow strokes keep their colors; only their opacity changes.');
  String get bucketHint => _t(
      '点一下要填色的地方，就用这个颜色填满。线没连上也没关系，小缝隙会自动补上。',
      "Tap an area to fill it with the color. Lines don't have to meet: small gaps are closed for you.");
  String get filling => _t('正在填色…', 'Filling…');
  String get fillGap => _t('补缝隙', 'Close gaps');
  String get pickerHint => _t(
      '按住画纸并移动，放大镜里是手指下的颜色；松开就用这个颜色画画。',
      'Touch the paper and move: the loupe shows the color under your finger. Let go to paint with it.');
  String pickedColor(String hex) => _t('吸取的颜色 $hex', 'Picked color $hex');
  String get smudgeHint => _t('在画好的颜色上来回涂，颜色会晕开、柔和地混在一起。不透明度越高，混得越多。',
      'Rub over colors already painted to soften and blend them together. '
          'Higher opacity blends more.');
  String get eraserHint => _t('橡皮擦是圆头的，长按画布可以看到擦除范围。',
      'The eraser has a round tip. Long-press the paper to see its size.');

  // Text tool
  String get textHint => _t('点画布添加文字 · 拖动文字移动 · 点文字修改',
      'Tap to add text · drag text to move · tap text to edit');
  String get addText => _t('添加文字', 'Add text');
  String get editText => _t('编辑文字', 'Edit text');
  String get textPlaceholder => _t('写点什么吧…', 'Type something…');
  String get bold => _t('加粗', 'Bold');
  String get italic => _t('斜体', 'Italic');
  String get underline => _t('下划线', 'Underline');
  String get strikethrough => _t('删除线', 'Strikethrough');
  String get alignLeft => _t('左对齐', 'Align left');
  String get alignCenter => _t('居中', 'Center');
  String get alignRight => _t('右对齐', 'Align right');
  String get bubble => _t('背景气泡', 'Bubble');
  String get fontSize => _t('字号', 'Size');
  String get done => _t('完成', 'Done');
  String get deleteText => _t('删除文字', 'Delete text');

  // Send, print and import
  String get send => _t('发送给别人', 'Send');
  String get print => _t('打印', 'Print');
  String get sendAs => _t('选择发送格式', 'Send as');
  String formatName(String format) => switch (format) {
        'png' => _t('图片（PNG）', 'Image (PNG)'),
        'jpg' => _t('图片（JPG）', 'Image (JPG)'),
        'pdf' => _t('PDF 文档', 'PDF document'),
        _ => _t('画作文件（可继续画）', 'Painting file (editable)'),
      };
  String formatHint(String format) => switch (format) {
        'png' => _t('清晰无损，适合收藏', 'Sharpest quality'),
        'jpg' => _t('文件更小，适合聊天发送', 'Smaller, good for chat apps'),
        'pdf' => _t('适合打印或发邮件', 'Good for printing or email'),
        _ => _t('对方装了快乐涂鸦，打开就能继续画',
            'Opens in JoyPainting to keep drawing'),
      };
  String get importPainting => _t('导入画作文件', 'Import painting file');
  String get imported => _t('已导入画作，可以继续画啦', 'Painting imported. Keep drawing!');
  // Import and export in My Paintings
  String get importButton => _t('导入', 'Import');
  String get exportButton => _t('导出', 'Export');
  String get importHint => _t('可以选一幅画（.jypaint）或一个压缩包（.zip）',
      'Choose one painting (.jypaint) or a zip with several');
  String get exportPickHint =>
      _t('点画作来选择，可以多选', 'Tap the paintings to export');
  String paintingsSelected(int n) => _t('已选 $n 幅', '$n selected');
  String get selectAll => _t('全选', 'Select all');
  String get selectNone => _t('全不选', 'Select none');
  String exportSelected(int n) => _t('导出 $n 幅', 'Export $n');
  String exportedCount(int n) => _t('已导出 $n 幅画作',
      n == 1 ? 'Exported 1 painting' : 'Exported $n paintings');
  String importedMany(int n) => _t('已导入 $n 幅画作，在“我的画作”里',
      n == 1 ? 'Imported 1 painting into My Paintings' : 'Imported $n paintings into My Paintings');
  String exportFailed(Object e) => _t('导出失败：$e', 'Export failed: $e');

  /// The name of a zip with several paintings.
  String archiveName(int count, DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${d.year}${two(d.month)}${two(d.day)}';
    return _t('快乐涂鸦_${date}_$count幅.zip', 'JoyPainting_${date}_$count paintings.zip');
  }
  String get notAPainting =>
      _t('这个文件不是快乐涂鸦的画作', "This file isn't a JoyPainting painting");
  String sendFailed(Object e) => _t('发送失败：$e', 'Sending failed: $e');
  String printFailed(Object e) => _t('打印失败：$e', 'Printing failed: $e');

  String get shapes => _t('形状', 'Shapes');
  String shapeName(ShapeKind? s) => switch (s) {
        null => _t('自由画', 'Freehand'),
        ShapeKind.line => _t('直线', 'Line'),
        ShapeKind.arrow => _t('箭头', 'Arrow'),
        ShapeKind.rectangle => _t('矩形', 'Rectangle'),
        ShapeKind.ellipse => _t('圆形', 'Circle'),
        ShapeKind.triangle => _t('三角形', 'Triangle'),
        ShapeKind.star => _t('星形', 'Star shape'),
        ShapeKind.heart => _t('心形', 'Heart shape'),
      };
  String get fillShape => _t('填充', 'Fill');
  String get freeShape => _t('自由形状', 'Free shape');
  String get gradient => _t('渐变', 'Gradient');
  String gradientName(GradientStyle g) => switch (g) {
        GradientStyle.none => _t('不用', 'None'),
        GradientStyle.lighter => _t('上亮', 'Lit top'),
        GradientStyle.darker => _t('下暗', 'Dark bottom'),
        GradientStyle.fade => _t('渐淡', 'Fade'),
        GradientStyle.glow => _t('光晕', 'Glow'),
        GradientStyle.rounded => _t('立体', 'Rounded'),
      };
  String get lightAndShadow => _t('光影', 'Light & shadow');
  String blendName(StrokeBlend b) => switch (b) {
        StrokeBlend.normal => _t('普通', 'Normal'),
        StrokeBlend.multiply => _t('阴影', 'Shadow'),
        StrokeBlend.screen => _t('提亮', 'Light'),
        StrokeBlend.overlay => _t('叠加', 'Overlay'),
        StrokeBlend.softLight => _t('柔光', 'Soft light'),
      };
  String get texture => _t('纹理', 'Texture');
  String textureName(StrokeTexture t) => switch (t) {
        StrokeTexture.none => _t('不用', 'None'),
        StrokeTexture.canvas => _t('画布', 'Canvas'),
        StrokeTexture.paper => _t('纸纹', 'Paper'),
        StrokeTexture.charcoal => _t('炭笔', 'Charcoal'),
        StrokeTexture.bristle => _t('笔刷痕', 'Bristles'),
      };
  String get eraserRange => _t('橡皮擦范围', 'Eraser area');
  String get opacity => _t('不透明度', 'Opacity');
  // Painting actions (top right)
  String get savePainting => _t('保存画作', 'Save painting');
  String get paintingSaved => _t('已保存到“我的画作”', 'Saved to My Paintings');
  String get deletePainting => _t('删除这幅画', 'Delete this painting');
  String get paintingDeleted =>
      _t('已删除，给你一张新画纸', 'Deleted. Here is a fresh page');

  // ⋮ menu sections
  String get menuShare => _t('分享', 'Share');
  String get menuView => _t('视图', 'View');
  String get menuPaper => _t('画纸', 'Paper');
  String get menuPainting => _t('画作', 'Painting');
  String get menuSound => _t('声音', 'Sound');

  // Background music
  String get backgroundMusic => _t('背景音乐', 'Background music');
  String get playMusic => _t('播放背景音乐', 'Play background music');
  String get playMusicHint => _device.isWeb
      ? _t('画画时播放；切到别的网页时暂停。浏览器要先点一下屏幕才会出声。',
          'Plays while you draw and pauses in another tab. Browsers need one tap on the page before sound plays.')
      : _t('画画时播放，切到后台会自动暂停',
          'Plays while you draw; pauses when the app is in the background');
  String get musicVolume => _t('音量', 'Volume');
  String get musicTrack => _t('选择音乐', 'Music');
  String get uploadMusic => _t('上传本地音乐', 'Add music from this device');
  String musicFormats({required bool apple}) => apple
      ? _t('支持 MP3、M4A/AAC、WAV、AIFF、FLAC 等常见格式',
          'MP3, M4A/AAC, WAV, AIFF, FLAC and other common formats')
      : _t('支持 MP3、M4A/AAC、WAV、OGG/Opus、FLAC、MIDI 等常见格式',
          'MP3, M4A/AAC, WAV, OGG/Opus, FLAC, MIDI and other common formats');
  String get builtInMusic => _t('自带', 'Built-in');
  String get myMusic => _t('我上传的', 'Added by me');
  String trackName(String id) => switch (id) {
        'sunny' => _t('阳光散步', 'Sunny Walk'),
        'twinkle' => _t('小星星摇篮曲', 'Twinkle Lullaby'),
        'joy' => _t('欢乐颂', 'Ode to Joy'),
        'tigers' => _t('两只老虎', 'Frère Jacques'),
        'clouds' => _t('云朵飘飘', 'Floating Clouds'),
        _ => id,
      };
  String musicAdded(String name) => _t('已添加“$name”', 'Added "$name"');
  String get musicAddFailed =>
      _t('这个文件放不了，换一首试试', "That file can't be played. Try another one");
  String deleteMusicTitle(String name) => _t('删除“$name”？', 'Delete "$name"?');
  String get musicPlayFailed => _t('背景音乐播放失败，已换回自带音乐',
      "Couldn't play the music. Switched back to a built-in track");

  // Print preview
  String get printPreview => _t('打印预览', 'Print preview');
  String get closePrint => _t('关闭', 'Close');
  String get printNow => _t('打印', 'Print');
  String get printHint => switch (_device.kind) {
        DeviceKind.android => _t(
            '点“打印”会打开手机的打印界面。想回来时，按返回键，或从屏幕左边缘向右滑一下。',
            "Print opens the phone's print screen. To come back, press Back or swipe in from the left edge of the screen."),
        DeviceKind.apple => _t(
            '点“打印”会打开打印界面。不想打印了，点左上角的“取消”就能回来。',
            'Print opens the print options. To come back without printing, tap Cancel at the top left.'),
        DeviceKind.web => _t(
            '点“打印”会打开浏览器的打印窗口。不想打印了，点“取消”就能回来。',
            "Print opens the browser's print window. To come back without printing, click Cancel."),
        DeviceKind.desktop => _t(
            '点“打印”会打开电脑的打印窗口。不想打印了，点“取消”就能回来。',
            "Print opens the computer's print window. To come back without printing, click Cancel."),
      };
  String get printSent => _t('已交给打印机', 'Sent to the printer');

  // Tools drawer
  String get toolsButton => _t('画笔 · 颜色', 'Brushes · Colors');
  String get toolsTitle => _t('画笔与颜色', 'Brushes & colors');
  String get openTools => _t('打开画笔和颜色', 'Open brushes and colors');
  String get closeTools => _t('收起画笔和颜色', 'Close brushes and colors');
  String get pinPalette => _t('固定在屏幕上，边画边选', 'Pin it here while drawing');
  String get unpinPalette => _t('取消固定', 'Unpin');
  String get moreTools => _t('更多：大小、形状、透明度', 'More: size, shapes, opacity');

  // Zoom
  String get fitScreen => _t('适应屏幕', 'Fit to screen');
  String get panCanvas => _t('拖动画板', 'Move the paper');
  String get keyboardShortcuts => _t('键盘快捷键', 'Keyboard shortcuts');

  /// The keyboard shortcuts: keys, and what they do. [command] is Ctrl or ⌘.
  List<(String, String)> shortcuts(String command) => [
        ('$command+Z', _t('撤销', 'Undo')),
        ('$command+Shift+Z · $command+Y', _t('重做', 'Redo')),
        ('$command+S', _t('保存', 'Save')),
        ('$command+P', _t('打印', 'Print')),
        ('$command+C · $command+X',
            _t('复制、剪切选中的部分', 'Copy or cut what is selected')),
        ('$command+V',
            _t('粘贴（也能贴到别的画里）', 'Paste (into another painting too)')),
        ('$command+D', _t('把选中的部分复制一份', 'Duplicate what is selected')),
        ('$command+A', _t('全部选中', 'Select everything')),
        ('Delete', _t('删除选中的部分', 'Delete what is selected')),
        ('$command + / $command −', _t('放大 / 缩小', 'Zoom in / out')),
        ('$command+0', _t('适应屏幕', 'Fit to screen')),
        ('$command+1', _t('实际大小', 'Real size')),
        (_t('按住空格', 'Hold Space'), _t('拖动画板', 'Move the paper')),
        ('H', _t('✋ 拖动画板 开 / 关', '✋ Move the paper on / off')),
        ('P · E · T · V',
            _t('画笔 · 橡皮 · 文字 · 移动', 'Pen · Eraser · Text · Move')),
        ('I · Alt + ${_t('点按', 'click')}',
            _t('吸管：吸取画上的颜色', 'Color picker: pick a color off the paper')),
        ('R · Shift+R',
            _t('转动画纸（双指也能转）', 'Turn the paper (two fingers do too)')),
        ('[  ]', _t('笔变细 / 变粗', 'Thinner / thicker brush')),
        ('Esc', _t('取消选中，关上工具栏', 'Deselect, close the tools')),
        ('?', _t('显示这张表', 'Show this list')),
      ];
  String get pinchHint => _device.desktopOs
      ? _t('双指捏合可以放大缩小画布，双指拖动可以移动画布；用鼠标时，滚动滚轮缩放，按住空格键或点 ✋ 拖动画板',
          'Pinch with two fingers to zoom, drag with two fingers to move; with a mouse, scroll the wheel to zoom, and hold Space or tap ✋ to move the paper')
      : _t('双指捏合可以放大缩小画布，双指拖动可以移动画布；点 ✋ 后一根手指也能拖动画板',
          'Pinch with two fingers to zoom, drag with two fingers to move; tap ✋ to move the paper with one finger');
  String percent(double v) => '${(v * 100).round()}%';
  String get mirror => _t('对称绘画', 'Mirror drawing');
  String get paperColor => _t('画纸颜色', 'Paper color');
  String get paperDefaultSize => _t('画纸恢复默认大小', 'Default paper size');
  String get paperWidthGrip =>
      _t('拖动改变画纸宽度', 'Drag to change the paper width');
  String get paperHeightGrip =>
      _t('拖动改变画纸高度', 'Drag to change the paper height');
  List<String> get paperNames => _zh
      ? const ['纯白', '奶油', '樱花', '天空', '薄荷', '薰衣草']
      : const ['White', 'Cream', 'Blossom', 'Sky', 'Mint', 'Lavender'];
  String colorLabel(Color c) {
    final hex = (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '${_t('颜色', 'Color')} #${hex.toUpperCase()}';
  }
  String get canvasLabel => _t('画布，用手指或手写笔画画', 'Canvas. Draw with a finger or stylus.');

  // Gallery
  String get allYears => _t('全部', 'All');
  String year(int y) => _t('$y年', '$y');
  String get emptyGallery =>
      _t('还没有画作，去画一幅吧！', 'No paintings yet. Go draw one!');
  String get emptyYear => _t('这一年没有画作', 'No paintings this year');
  String created(String date) => _t('创建于 $date', 'Created $date');
  String updated(String date) => _t('修改于 $date', 'Edited $date');
  String get editing => _t('正在画', 'Editing');
  String get continuePainting => _t('继续画', 'Continue');
  String get deleteTitle => _t('删除这幅画？', 'Delete this painting?');
  String get deleteBody =>
      _t('删除后无法恢复。', "Deleted paintings can't be recovered.");
  String strokeCount(int n) => _t('$n 笔', n == 1 ? '1 stroke' : '$n strokes');

  // Settings
  String get theme => _t('主题', 'Theme');
  String get font => _t('字体', 'Font');
  String get textSize => _t('文字大小', 'Text size');
  String get textSizeHint => _t('拖动滑块，或点两边的按钮，放大或缩小整个应用的文字。',
      'Drag the slider, or tap the buttons beside it, to make all text in '
          'the app bigger or smaller.');
  String get textSmaller => _t('文字小一点', 'Smaller text');
  String get textLarger => _t('文字大一点', 'Larger text');
  String get fontSample => _t('快乐涂鸦 Aa', 'JoyPainting Aa');
  String get licenses => _t('开源许可', 'Open-source licenses');
  String get language => _t('语言', 'Language');

  // Skill levels
  String get skillLevel => _t('功能等级', 'Drawing level');
  String get skillLevelHint => _t(
      '等级只决定画画时显示哪些工具，随时可以在设置里改，画好的画不受影响。',
      'A level only decides which tools are shown while drawing. Change it '
          'any time in Settings; your paintings stay the same.');
  String levelName(SkillLevel l) => switch (l) {
        SkillLevel.beginner => _t('初级', 'Beginner'),
        SkillLevel.intermediate => _t('中级', 'Intermediate'),
        SkillLevel.advanced => _t('高级', 'Advanced'),
      };
  String levelDescription(SkillLevel l) => switch (l) {
        SkillLevel.beginner => _t('简单好用：常用的画笔、颜色、形状、印章和文字。',
            'Simple: the everyday brushes, colors, shapes, stamps and text.'),
        SkillLevel.intermediate => _t(
            '再加上荧光笔、柔边笔、选择移动、不透明度、自由形状和渐变。',
            'Adds the highlighter, soft brush, move tool, opacity, free '
                'shapes and gradients.'),
        SkillLevel.advanced => _t('全部功能：再加上晕染笔、光影和纹理，适合画写实的画。',
            'Everything: adds the blender, light and shadow, and textures, '
                'for realistic paintings.'),
      };
  String get about => _t('关于', 'About');
  String get aboutBody => _device.isWeb
      ? _t(
          '画作会自动保存在这个浏览器里，只有这台设备能看到。清除浏览器的网站数据会把它们删掉，可以用“发送给别人 → 画作文件”备份。',
          "Paintings save automatically in this browser, on this device only. Clearing the browser's website data deletes them; back them up with Send → Painting file.")
      : _t(
          '画作会自动保存在这台设备上，可以在“我的画作”中继续编辑。',
          'Paintings save automatically on this device. Continue any of them from My Paintings.');
  String version(String v) => _t('版本 $v', 'Version $v');
}

/// Formats a date as `2026-10-24 14:30` in both languages.
String formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
