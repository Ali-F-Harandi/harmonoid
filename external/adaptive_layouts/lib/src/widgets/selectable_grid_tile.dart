/// Selectable grid tile.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../functions.dart';
import 'context_menu_listener.dart';

/// A fixed-size grid tile with hover actions, popup menu & selection.
class SelectableGridTile extends StatefulWidget {
  const SelectableGridTile({
    super.key,
    required this.width,
    required this.height,
    required this.title,
    this.subtitle,
    this.leading,
    this.popupMenuBuilder,
    this.onItemPressed,
    this.onPopupMenuItemSelected,
    this.showItemSelection = false,
    this.isItemSelected = false,
    this.onItemSelected,
  });

  /// Default tile size.
  static const double kWidth = 172.0;
  static const double kHeight = 216.0;

  final double width;
  final double height;

  /// Title widget (typically [TappableText]).
  final Widget title;

  /// Subtitle widgets shown below the title.
  final List<Widget>? subtitle;

  /// Leading widget (typically the cover image).
  final Widget? leading;

  /// Popup menu items builder.
  final FutureOr<List<PopupMenuItem<int>>> Function()? popupMenuBuilder;

  /// Invoked when the tile is pressed.
  final VoidCallback? onItemPressed;

  /// Invoked when a popup menu item is selected.
  final ValueChanged<int>? onPopupMenuItemSelected;

  /// Whether the tile can be (multi-)selected.
  final bool showItemSelection;

  /// Whether the tile is currently selected.
  final bool isItemSelected;

  /// Invoked when the selection changes.
  final ValueChanged<bool>? onItemSelected;

  @override
  State<SelectableGridTile> createState() => _SelectableGridTileState();
}

class _SelectableGridTileState extends State<SelectableGridTile> {
  bool _hovered = false;

  Future<void> _showPopupMenu(BuildContext context) async {
    final items = await widget.popupMenuBuilder?.call();
    if (items == null || items.isEmpty || !mounted) return;
    final result = await showMenuItems<int>(context, items);
    if (result == null) return;
    widget.onPopupMenuItemSelected?.call(result);
  }

  Future<void> _showPopupMenuAt(BuildContext context, RelativeRect? position) async {
    if (position == null) {
      await _showPopupMenu(context);
      return;
    }
    final items = await widget.popupMenuBuilder?.call();
    if (items == null || items.isEmpty || !mounted) return;
    final result = await showMenu<int>(
      context: context,
      position: position,
      items: items,
    );
    if (result == null) return;
    widget.onPopupMenuItemSelected?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverSize = widget.width;
    final showCheckbox = widget.showItemSelection && (widget.isItemSelected || _hovered);

    final cover = SizedBox(
      width: coverSize,
      height: coverSize,
      child: widget.leading ??
          Icon(
            Icons.album_outlined,
            size: coverSize * 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ContextMenuListener(
        onSecondaryPress: (position) => _showPopupMenuAt(context, position),
        child: InkWell(
          onTap: widget.onItemPressed,
          onLongPress: widget.showItemSelection
              ? () => widget.onItemSelected?.call(!widget.isItemSelected)
              : () => _showPopupMenu(context),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    cover,
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: widget.title,
                    ),
                    if (widget.subtitle != null)
                      for (final subtitle in widget.subtitle!)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: subtitle,
                        ),
                  ],
                ),
                if (widget.isItemSelected)
                  Positioned.fill(
                    child: ColoredBox(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    ),
                  ),
                if (showCheckbox)
                  Positioned(
                    top: 4.0,
                    left: 4.0,
                    child: Checkbox(
                      value: widget.isItemSelected,
                      onChanged: (value) =>
                          widget.onItemSelected?.call(value ?? false),
                    ),
                  ),
                if (_hovered && widget.popupMenuBuilder != null)
                  Positioned(
                    right: 4.0,
                    bottom: widget.height - coverSize + 4.0,
                    child: Material(
                      shape: const CircleBorder(),
                      color: theme.colorScheme.inverseSurface,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _showPopupMenu(context),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.more_vert,
                            size: 16.0,
                            color: theme.colorScheme.onInverseSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
