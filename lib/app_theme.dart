import 'package:flutter/material.dart';

import 'drawing/stroke.dart';
import 'theme/cute_font.dart';
import 'theme/cute_theme.dart';

/// The bundled theme templates, in the order shown in Settings.
/// Each id is a file in `assets/themes/`.
const kThemeIds = ['sakura', 'lavender', 'peach', 'mint', 'cloud'];

/// The bundled fonts, in the order shown in Settings. The first is the
/// default: a cute rounded Chinese font.
const kFonts = [
  CuteFont(
    id: 'kuaile',
    family: 'ZCOOLKuaiLe',
    names: {'zh': '快乐体', 'en': 'KuaiLe (happy)'},
    licenseAsset: 'assets/fonts/zcoolkuaile/OFL.txt',
  ),
  CuteFont(
    id: 'huangyou',
    family: 'ZCOOLQingKeHuangYou',
    names: {'zh': '黄油体', 'en': 'HuangYou (chubby)'},
    licenseAsset: 'assets/fonts/zcoolqingkehuangyou/OFL.txt',
  ),
  CuteFont(
    id: 'longcang',
    family: 'LongCang',
    names: {'zh': '手写体', 'en': 'LongCang (handwritten)'},
    licenseAsset: 'assets/fonts/longcang/OFL.txt',
  ),
  CuteFont.system,
];

CuteFont fontById(String id) =>
    kFonts.firstWhere((f) => f.id == id, orElse: () => kFonts.first);

/// App-specific look that isn't part of the portable theme module.
abstract final class AppTheme {
  /// Strength of the tint behind an unselected brush button.
  static const brushTintAlpha = 0.14;

  /// Brush accent colors. Dark enough to read as icons (3:1) on their pale
  /// tile and on every theme's surface; tests check this.
  static Color brushColor(BrushType b) => switch (b) {
        BrushType.pen => const Color(0xFF7B4FD6),
        BrushType.pencil => const Color(0xFFB5521A),
        BrushType.marker => const Color(0xFFC2185B),
        BrushType.highlighter => const Color(0xFF8A6D00),
        BrushType.soft => const Color(0xFF2E7D32),
        BrushType.smudge => const Color(0xFF5D6B2F),
        BrushType.spray => const Color(0xFF1C7A96),
        BrushType.rainbow => const Color(0xFFA63A9E),
        BrushType.stamp => const Color(0xFFD1376F),
        BrushType.bucket => const Color(0xFFA34700),
        BrushType.text => const Color(0xFF3B5BDB),
        BrushType.move => const Color(0xFF00796B),
        BrushType.picker => const Color(0xFF3D5A98),
        BrushType.eraser => const Color(0xFF5F6C7B),
      };

  static IconData brushIcon(BrushType b) => switch (b) {
        BrushType.pen => Icons.draw_rounded,
        BrushType.pencil => Icons.edit_rounded,
        BrushType.marker => Icons.brush_rounded,
        BrushType.highlighter => Icons.border_color_rounded,
        BrushType.soft => Icons.water_drop_rounded,
        BrushType.smudge => Icons.blur_circular_rounded,
        BrushType.spray => Icons.blur_on_rounded,
        BrushType.rainbow => Icons.looks_rounded,
        BrushType.stamp => Icons.favorite_rounded,
        BrushType.bucket => Icons.format_color_fill_rounded,
        BrushType.text => Icons.text_fields_rounded,
        BrushType.move => Icons.open_with_rounded,
        BrushType.picker => Icons.colorize_rounded,
        BrushType.eraser => Icons.auto_fix_normal_rounded,
      };

  static IconData shapeIcon(ShapeKind? s) => switch (s) {
        null => Icons.gesture_rounded,
        ShapeKind.line => Icons.horizontal_rule_rounded,
        ShapeKind.arrow => Icons.north_east_rounded,
        ShapeKind.rectangle => Icons.crop_square_rounded,
        ShapeKind.ellipse => Icons.circle_outlined,
        ShapeKind.triangle => Icons.change_history_rounded,
        ShapeKind.star => Icons.star_border_rounded,
        ShapeKind.heart => Icons.favorite_border_rounded,
        ShapeKind.roundedRect => Icons.rounded_corner_rounded,
        ShapeKind.diamond => Icons.diamond_outlined,
        ShapeKind.pentagon => Icons.pentagon_outlined,
        ShapeKind.hexagon => Icons.hexagon_outlined,
        ShapeKind.cross => Icons.add_rounded,
        ShapeKind.cloud => Icons.cloud_outlined,
        ShapeKind.moon => Icons.nightlight_outlined,
        ShapeKind.drop => Icons.water_drop_outlined,
        ShapeKind.lightning => Icons.bolt_rounded,
        ShapeKind.bubble => Icons.chat_bubble_outline_rounded,
        ShapeKind.doubleArrow => Icons.sync_alt_rounded,
        ShapeKind.spiral => Icons.cyclone_rounded,
        ShapeKind.arc => Icons.architecture_rounded,
        ShapeKind.wave => Icons.waves_rounded,
      };

  static IconData gradientIcon(GradientStyle g) => switch (g) {
        GradientStyle.none => Icons.square_rounded,
        GradientStyle.lighter => Icons.wb_sunny_rounded,
        GradientStyle.darker => Icons.nights_stay_rounded,
        GradientStyle.fade => Icons.gradient_rounded,
        GradientStyle.glow => Icons.flare_rounded,
        GradientStyle.rounded => Icons.circle_rounded,
        GradientStyle.across => Icons.view_week_rounded,
        GradientStyle.diagonal => Icons.north_west_rounded,
        GradientStyle.rainbow => Icons.looks_rounded,
        GradientStyle.contrast => Icons.compare_rounded,
      };

  /// The blend modes offered in the tools drawer, in order.
  static const blends = StrokeBlend.values;

  static IconData blendIcon(StrokeBlend b) => switch (b) {
        StrokeBlend.normal => Icons.brush_rounded,
        StrokeBlend.multiply => Icons.contrast_rounded,
        StrokeBlend.screen => Icons.light_mode_rounded,
        StrokeBlend.overlay => Icons.layers_rounded,
        StrokeBlend.softLight => Icons.tonality_rounded,
        StrokeBlend.hardLight => Icons.wb_iridescent_rounded,
        StrokeBlend.colorDodge => Icons.auto_awesome_rounded,
        StrokeBlend.colorBurn => Icons.local_fire_department_rounded,
        StrokeBlend.color => Icons.palette_rounded,
      };

  static IconData textureIcon(StrokeTexture t) => switch (t) {
        StrokeTexture.none => Icons.square_rounded,
        StrokeTexture.canvas => Icons.grid_on_rounded,
        StrokeTexture.paper => Icons.description_rounded,
        StrokeTexture.charcoal => Icons.grain_rounded,
        StrokeTexture.bristle => Icons.texture_rounded,
        StrokeTexture.crayon => Icons.draw_rounded,
        StrokeTexture.watercolor => Icons.water_drop_rounded,
        StrokeTexture.stipple => Icons.blur_on_rounded,
        StrokeTexture.hatch => Icons.tag_rounded,
        StrokeTexture.wood => Icons.view_stream_rounded,
        StrokeTexture.sand => Icons.scatter_plot_rounded,
      };

  static IconData stampIcon(StampShape s) => switch (s) {
        StampShape.heart => Icons.favorite_rounded,
        StampShape.star => Icons.star_rounded,
        StampShape.flower => Icons.local_florist_rounded,
        StampShape.sun => Icons.wb_sunny_rounded,
        StampShape.leaf => Icons.eco_rounded,
        StampShape.paw => Icons.pets_rounded,
        StampShape.note => Icons.music_note_rounded,
      };

  /// Soft paper colors to draw on.
  static const papers = [
    Color(0xFFFFFFFF),
    Color(0xFFFFF8E7),
    Color(0xFFFFF0F5),
    Color(0xFFEEF6FF),
    Color(0xFFEEFBF4),
    Color(0xFFF5F0FF),
  ];
}

/// An AppBar on the theme's header gradient, with rounded bottom corners.
/// Its text and icons use the theme's contrast-checked header color.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  final Widget title;
  final List<Widget>? actions;

  /// Replaces the automatic back button.
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cute = CuteTheme.of(context);
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
    );
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      shape: shape,
      flexibleSpace: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          gradient: cute.headerGradient,
          shadows: [
            BoxShadow(
              color: cute.spec.primary.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app logo and theme emoji next to the title.
class AppLogoTitle extends StatelessWidget {
  const AppLogoTitle({
    super.key,
    required this.text,
    this.subtitle,
    this.onTap,
    this.tapLabel,
  });

  final String text;

  /// A smaller second line (the open painting's name).
  final String? subtitle;

  /// Makes the title a button (renaming the painting); [tapLabel] is what
  /// screen readers say it does.
  final VoidCallback? onTap;
  final String? tapLabel;

  @override
  Widget build(BuildContext context) {
    final emoji = CuteTheme.of(context).spec.emoji;
    final sub = subtitle;
    // On a narrow bar with big text, the words matter more than the logo
    // and the emoji.
    final title = LayoutBuilder(builder: (context, box) {
    final roomy = box.maxWidth >= 120;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (roomy) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/icon/logo.png',
                width: 32, height: 32, excludeFromSemantics: true),
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: sub == null
              ? Text(text, overflow: TextOverflow.ellipsis)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                    // One text with the pencil inside, so on a narrow
                    // phone it shortens with "…" instead of overflowing.
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: sub),
                        if (onTap != null)
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.edit_rounded, size: 14),
                            ),
                          ),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DefaultTextStyle.of(context)
                          .style
                          .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
        if (roomy && emoji.isNotEmpty) ...[
          const SizedBox(width: 6),
          ExcludeSemantics(child: Text(emoji)),
        ],
      ],
    );
    });
    if (onTap == null) return title;
    return Semantics(
      button: true,
      hint: tapLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        // At least 48 tall, like every other button.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(alignment: Alignment.centerLeft, widthFactor: 1, child: title),
        ),
      ),
    );
  }
}
