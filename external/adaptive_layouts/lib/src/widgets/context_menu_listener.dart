/// Right-click / long-press context menu listener.
library;

import 'package:flutter/material.dart';

/// Invokes [onSecondaryPress] with the pointer position when the [child] is
/// right-clicked (desktop) or long-pressed (touch).
class ContextMenuListener extends StatelessWidget {
  const ContextMenuListener({
    super.key,
    this.onSecondaryPress,
    required this.child,
  });

  final void Function(RelativeRect? position)? onSecondaryPress;

  final Widget child;

  void _handle(BuildContext context, Offset offset) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      onSecondaryPress?.call(null);
      return;
    }
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy,
      overlay.size.width - offset.dx,
      overlay.size.height - offset.dy,
    );
    onSecondaryPress?.call(position);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapDown: (details) => _handle(context, details.globalPosition),
      onLongPressStart: (details) => _handle(context, details.globalPosition),
      child: child,
    );
  }
}
