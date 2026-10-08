/// Rich text with individually tappable segments.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A segment of [TappableText].
class TappableTextData {
  const TappableTextData({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;
}

/// Text built from tappable segments joined by [separator].
class TappableText extends StatelessWidget {
  const TappableText({
    super.key,
    required this.text,
    this.separator,
    this.style,
    this.ignoring = false,
  });

  /// Segments to render.
  final Iterable<TappableTextData> text;

  /// Separator between segments; defaults to ` • `.
  final String? separator;

  final TextStyle? style;

  /// Whether taps are ignored.
  final bool ignoring;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = style ?? defaultStyle;
    final separator = this.separator ?? ' • ';

    final spans = <TextSpan>[];
    var first = true;
    for (final segment in text) {
      if (!first && separator.isNotEmpty) {
        spans.add(TextSpan(text: separator, style: effectiveStyle));
      }
      first = false;
      if (segment.onTap != null && !ignoring) {
        spans.add(
          TextSpan(
            text: segment.text,
            style: effectiveStyle.copyWith(color: effectiveStyle.color),
            recognizer: TapGestureRecognizer()
              ..onTap = segment.onTap,
          ),
        );
      } else {
        spans.add(TextSpan(text: segment.text, style: effectiveStyle));
      }
    }

    return IgnorePointer(
      ignoring: ignoring,
      child: Text.rich(
        TextSpan(children: spans),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
