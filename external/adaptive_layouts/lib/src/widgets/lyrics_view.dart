/// Auto-scrolling lyrics view with translations.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Karaoke-style lyrics view.
class LyricsView extends StatefulWidget {
  const LyricsView({
    super.key,
    this.selectionModeNotifier,
    required this.index,
    required this.lyrics,
    required this.subscripts,
    this.onLyricTap,
    this.padding = EdgeInsets.zero,
    this.focusedTextStyle,
    this.unfocusedTextStyle,
    this.textAlign = TextAlign.center,
    this.alignment = Alignment.center,
    this.viewportWidth = double.infinity,
    this.viewportHeight = double.infinity,
  });

  /// Enables text selection mode when true.
  final ValueNotifier<bool>? selectionModeNotifier;

  /// Index of the currently focused lyric line.
  final int index;

  /// Lyric lines.
  final List<String> lyrics;

  /// Translation lines (same length as [lyrics] or empty).
  final List<String> subscripts;

  /// Invoked when a lyric line is tapped.
  final void Function(int index)? onLyricTap;

  final EdgeInsets padding;
  final TextStyle? focusedTextStyle;
  final TextStyle? unfocusedTextStyle;
  final TextAlign textAlign;
  final Alignment alignment;

  final double viewportWidth;
  final double viewportHeight;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  static const double _kLineExtent = 64.0;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToIndex());
  }

  @override
  void didUpdateWidget(covariant LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _animateToIndex();
    }
  }

  void _jumpToIndex() {
    if (!_controller.hasClients) return;
    final viewport = _controller.position.viewportDimension;
    final target = _targetFor(widget.index, viewport);
    _controller.jumpTo(target);
  }

  void _animateToIndex() {
    if (!_controller.hasClients) return;
    final viewport = _controller.position.viewportDimension;
    final target = _targetFor(widget.index, viewport);
    final duration =
        Theme.of(context).extension<AnimationDuration>()?.medium ??
            const Duration(milliseconds: 300);
    _controller.animateTo(
      target,
      duration: duration,
      curve: Curves.easeOut,
    );
  }

  double _targetFor(int index, double viewport) {
    final maxExtent = _controller.position.maxScrollExtent;
    return (index * _kLineExtent - viewport / 2 + _kLineExtent / 2)
        .clamp(0.0, maxExtent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focused = widget.focusedTextStyle ??
        theme.textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.w700,
        );
    final unfocused = widget.unfocusedTextStyle ??
        theme.textTheme.titleMedium!.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          fontWeight: FontWeight.w500,
        );
    final subscriptStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );

    Widget view = ListView.builder(
      controller: _controller,
      padding: widget.padding,
      itemExtent: _kLineExtent,
      itemCount: widget.lyrics.length,
      itemBuilder: (context, index) {
        final isFocused = index == widget.index;
        final subscript = widget.subscripts.length > index
            ? widget.subscripts[index]
            : null;
        return InkWell(
          onTap: widget.onLyricTap == null ? null : () => widget.onLyricTap!(index),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.lyrics[index],
                  textAlign: widget.textAlign,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isFocused ? focused : unfocused,
                ),
                if (subscript != null && subscript.isNotEmpty)
                  Text(
                    subscript,
                    textAlign: widget.textAlign,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subscriptStyle,
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (widget.selectionModeNotifier != null) {
      view = ValueListenableBuilder<bool>(
        valueListenable: widget.selectionModeNotifier!,
        builder: (context, selectionMode, _) {
          return SelectionArea(
            selectionControls: materialTextSelectionControls,
            child: view,
          );
        },
      );
    }

    return Align(
      alignment: widget.alignment,
      child: view,
    );
  }
}
