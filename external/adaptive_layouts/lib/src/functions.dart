/// Utility functions for the adaptive UI.
library;

import 'package:flutter/material.dart';

/// Shows a popup/context menu built from [items].
///
/// When [position] is provided the menu appears there (right-click context
/// menu); otherwise it appears centered-ish near the [context] widget.
Future<T?> showMenuItems<T>(
  BuildContext context,
  List<PopupMenuEntry<T>> items, {
  RelativeRect? position,
}) {
  if (items.isEmpty) return Future.value();
  if (position != null) {
    return showMenu<T>(
      context: context,
      position: position,
      items: items,
    );
  }
  final renderBox = context.findRenderObject() as RenderBox?;
  final overlayRenderBox =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  final size = renderBox?.size ?? Size.zero;
  final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  final overlaySize = overlayRenderBox?.size ?? MediaQuery.sizeOf(context);
  final target = RelativeRect.fromLTRB(
    offset.dx,
    offset.dy + size.height,
    overlaySize.width - offset.dx - size.width,
    overlaySize.height - offset.dy - size.height,
  );
  return showMenu<T>(
    context: context,
    position: target,
    items: items,
  );
}
