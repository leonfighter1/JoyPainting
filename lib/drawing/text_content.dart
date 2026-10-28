import 'package:flutter/material.dart';

/// The words and formatting of a text item.
class TextContent {
  const TextContent({
    this.text = '',
    this.fontFamily,
    this.fontSize = 32,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.align = TextAlign.left,
    this.bubble = false,
  });

  final String text;

  /// A pubspec font family, or null for the app's current font.
  final String? fontFamily;
  final double fontSize;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;

  /// left, center or right: the anchor point is that edge of the text.
  final TextAlign align;

  /// Draws a soft rounded bubble behind the text.
  final bool bubble;

  /// Padding between the text and its bubble.
  static const bubblePadding = 10.0;

  TextStyle style(Color color) => TextStyle(
        color: color,
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: 1.25,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        decoration: TextDecoration.combine([
          if (underline) TextDecoration.underline,
          if (strikethrough) TextDecoration.lineThrough,
        ]),
        decorationColor: color,
        decorationThickness: 2,
      );

  TextContent copyWith({
    String? text,
    String? Function()? fontFamily,
    double? fontSize,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    TextAlign? align,
    bool? bubble,
  }) =>
      TextContent(
        text: text ?? this.text,
        fontFamily: fontFamily == null ? this.fontFamily : fontFamily(),
        fontSize: fontSize ?? this.fontSize,
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        strikethrough: strikethrough ?? this.strikethrough,
        align: align ?? this.align,
        bubble: bubble ?? this.bubble,
      );

  Map<String, Object?> toJson() => {
        'text': text,
        if (fontFamily != null) 'fontFamily': fontFamily,
        'fontSize': fontSize,
        'bold': bold,
        'italic': italic,
        'underline': underline,
        'strikethrough': strikethrough,
        'align': align.name,
        'bubble': bubble,
      };

  factory TextContent.fromJson(Map<String, Object?> json) => TextContent(
        text: json['text'] as String? ?? '',
        fontFamily: json['fontFamily'] as String?,
        fontSize: (json['fontSize'] as num? ?? 32).toDouble(),
        bold: json['bold'] as bool? ?? false,
        italic: json['italic'] as bool? ?? false,
        underline: json['underline'] as bool? ?? false,
        strikethrough: json['strikethrough'] as bool? ?? false,
        align: TextAlign.values.firstWhere((a) => a.name == json['align'],
            orElse: () => TextAlign.left),
        bubble: json['bubble'] as bool? ?? false,
      );
}
