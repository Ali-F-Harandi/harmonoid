/// Adaptive table/list widget.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../enums.dart';
import '../theme.dart';
import 'context_menu_listener.dart';
import 

/// Callback fired when desktop table columns are resized.
typedef DesktopOnColumnResize = void Function(List<double> widths);

/// A row of the [ListItemTable]; holds the per-column cell widgets.
class ListItemData extends StatelessWidget {
  const ListItemData({super.key, required this.children});

  /// Cell widgets, one per column.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(children: children);
  }
}

/// An adaptive table (desktop) / list (mobile) with selection & popup menus.
class ListItemTable extends StatefulWidget {
  const ListItemTable({
    super.key,
    this.verticalScrollKey,
    this.headerBuilder,
    this.footerBuilder,
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
    this.leadingBuilder,
    this.popupMenuBuilder,
    this.onItemPressed,
    this.onPopupMenuItemSelected,
    this.physics,
    this.desktopBorders = false,
    this.desktopLeadingColumn,
    this.desktopColumnWidths,
    this.desktopColumnRatios,
    this.desktopOnColumnResize,
    this.mobileHeaderHeight = 0.0,
    this.mobileSliverList = false,
    this.mobileDisplayLabel = false,
    this.mobileLabelTextStyle,
    this.showItemSelection = false,
    this.isItemSelected,
    this.onItemSelected,
    this.itemSelectionChangeNotifier,
  });

  /// PageStorage key for persisting the scroll offset.
  final Key? verticalScrollKey;

  /// Optional header shown above the table (inside the scroll view).
  final WidgetBuilder? headerBuilder;

  /// Optional footer shown below the table (inside the scroll view).
  final WidgetBuilder? footerBuilder;

  /// Column labels (desktop).
  final List<String> columns;

  /// Number of rows.
  final int itemCount;

  /// Builds the row at [index]; returns a [ListItemData] (or `null`).
  final Widget? Function(BuildContext context, int index) itemBuilder;

  /// Builds the leading cell content: a [Widget], [String] or [int].
  final Object? Function(BuildContext context, int index)? leadingBuilder;

  /// Popup menu items for the row at [index].
  final FutureOr<List<PopupMenuItem<int>>> Function(
    BuildContext context,
    int index,
  )? popupMenuBuilder;

  /// Invoked when a row is pressed.
  final void Function(BuildContext context, int index)? onItemPressed;

  /// Invoked when a popup menu item of the row at [index] is selected.
  final FutureOr<void> Function(BuildContext context, int index, dynamic result)?
      onPopupMenuItemSelected;

  final ScrollPhysics? physics;

  /// Whether horizontal borders are drawn between desktop rows.
  final bool desktopBorders;

  /// Leading column header (desktop).
  final Widget? desktopLeadingColumn;

  /// Absolute column widths (desktop).
  final List<double>? desktopColumnWidths;

  /// Relative column ratios (desktop); used when widths are absent.
  final List<double>? desktopColumnRatios;

  /// Fired when desktop columns are resized.
  final DesktopOnColumnResize? desktopOnColumnResize;

  /// Height of the mobile header slot.
  final double mobileHeaderHeight;

  /// Whether the list is rendered as slivers (mobile); currently behaves as
  /// a plain list.
  final bool mobileSliverList;

  /// Whether a label row is shown (mobile).
  final bool mobileDisplayLabel;

  /// Style of the mobile label row.
  final TextStyle? mobileLabelTextStyle;

  /// Whether rows can be (multi-)selected.
  final bool showItemSelection;

  /// Whether the row at [index] is selected.
  final bool Function(int index)? isItemSelected;

  /// Invoked when the selection of the row at [index] changes.
  final void Function(BuildContext context, int index, bool value)?
      onItemSelected;

  /// Notifier listened to for selection changes.
  final Listenable? itemSelectionChangeNotifier;

  @override
  State<ListItemTable> createState() => ListItemTableState();
}

/// Public state of [ListItemTable]; exposes row height constants.
class ListItemTableState extends State<ListItemTable> {
  /// Height of a single desktop row.
  static const double kDesktopRowHeight = 56.0;

  /// Height of a single mobile row.
  static const double kMobileRowHeight = 72.0;

  late List<double> _columnWidths;

  @override
  void initState() {
    super.initState();
    _columnWidths = List<double>.of(widget.desktopColumnWidths ?? const <double>[]);
  }

  @override
  void didUpdateWidget(covariant ListItemTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.desktopColumnWidths;
    if (incoming != null && incoming.length == widget.columns.length) {
      var changed = incoming.length != _columnWidths.length;
      if (!changed) {
        for (var i = 0; i < incoming.length; i++) {
          if ((incoming[i] - _columnWidths[i]).abs() > 0.01) {
            changed = true;
            break;
          }
        }
      }
      if (changed) {
        _columnWidths = List<double>.of(incoming);
      }
    } else if (widget.columns.length != _columnWidths.length) {
      _columnWidths = List<double>.of(widget.desktopColumnWidths ?? const <double>[]);
    }
  }

  void _handleColumnResize(int index, double delta) {
    setState(() {
      final value = _columnWidths[index] + delta;
      _columnWidths[index] = value.clamp(40.0, 4096.0);
    });
    widget.desktopOnColumnResize?.call(List<double>.of(_columnWidths));
  }

  List<double> _effectiveWidths(double available) {
    final count = widget.columns.length;
    if (_columnWidths.length == count) {
      final sum = _columnWidths.fold<double>(0.0, (a, b) => a + b);
      final target = available - ListItemTableState.kDesktopRowHeight;
      if (sum > 0 && (sum - target).abs() > 1.0) {
        final scale = target / sum;
        return _columnWidths.map((e) => e * scale).toList();
      }
      return _columnWidths;
    }
    if (widget.desktopColumnRatios != null &&
        widget.desktopColumnRatios!.length == count) {
      final target = (available - kDesktopRowHeight) /
          widget.desktopColumnRatios!.fold<double>(0.0, (a, b) => a + b);
      return widget.desktopColumnRatios!.map((e) => e * target).toList();
    }
    final each = (available - kDesktopRowHeight) / (count == 0 ? 1 : count);
    return List<double>.filled(count, each);
  }

  Future<void> _showPopupMenu(BuildContext context, int index) async {
    final items = await widget.popupMenuBuilder?.call(context, index);
    if (items == null || items.isEmpty || !mounted) return;
    final result = await showMenu<int>(
      context: context,
      items: items,
      position: _menuPosition(context),
    );
    if (result == null) return;
    await widget.onPopupMenuItemSelected?.call(context, index, result);
  }

  RelativeRect _menuPosition(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final size = box?.size ?? Size.zero;
    final offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final overlaySize = overlay?.size ?? MediaQuery.sizeOf(context);
    return RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + size.height,
      overlaySize.width - offset.dx,
      overlaySize.height - offset.dy - size.height,
    );
  }

  void _handleLongPress(BuildContext context, int index) {
    if (widget.showItemSelection) {
      final selected = widget.isItemSelected?.call(index) ?? false;
      widget.onItemSelected?.call(context, index, !selected);
    } else {
      _showPopupMenu(context, index);
    }
  }

  Widget _renderLeading(Object? value) {
    if (value == null) return const SizedBox.shrink();
    if (value is Widget) return value;
    if (value is String) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    if (value is int) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          value.toString(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant =
        theme.extension<LayoutVariantThemeExtension>()?.value ?? LayoutVariant.mobile;
    final body = variant == LayoutVariant.desktop
        ? _buildDesktop(context)
        : _buildMobile(context);
    if (widget.itemSelectionChangeNotifier != null) {
      return ListenableBuilder(
        listenable: widget.itemSelectionChangeNotifier!,
        builder: (context, _) => body,
      );
    }
    return body;
  }

  Widget _buildDesktop(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = _effectiveWidths(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.headerBuilder != null)
              widget.headerBuilder!.call(context),
            _DesktopTableHeader(
              columns: widget.columns,
              widths: widths,
              leading: widget.desktopLeadingColumn,
              borders: widget.desktopBorders,
              onColumnResize: _handleColumnResize,
            ),
            Expanded(
              child: ListView.builder(
                key: widget.verticalScrollKey,
                physics: widget.physics,
                itemCount: widget.itemCount,
                itemBuilder: (context, index) {
                  final row = widget.itemBuilder(context, index);
                  if (row == null) return const SizedBox.shrink();
                  final cells = row is ListItemData ? row.children : <Widget>[row];
                  final selected =
                      widget.isItemSelected?.call(index) ?? false;
                  return _DesktopTableRow(
                    cells: cells,
                    widths: widths,
                    borders: widget.desktopBorders,
                    selected: selected,
                    showSelection: widget.showItemSelection,
                    leading: _renderLeading(widget.leadingBuilder?.call(context, index)),
                    onPressed: () => widget.onItemPressed?.call(context, index),
                    onLongPressed: () => _handleLongPress(context, index),
                    onSecondaryTap: () => _showPopupMenu(context, index),
                    onSelectionChanged: (value) =>
                        widget.onItemSelected?.call(context, index, value),
                  );
                },
              ),
            ),
            if (widget.footerBuilder != null) widget.footerBuilder!.call(context),
          ],
        );
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = widget.mobileLabelTextStyle ??
        theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        );
    final headerCount = widget.headerBuilder != null ? 1 : 0;
    final labelCount = widget.mobileDisplayLabel ? 1 : 0;
    final footerCount = widget.footerBuilder != null ? 1 : 0;
    return ListView.builder(
      key: widget.verticalScrollKey,
      physics: widget.physics,
      itemCount: headerCount + labelCount + widget.itemCount + footerCount,
      itemBuilder: (context, position) {
        if (position == 0 && headerCount == 1) {
          return SizedBox(
            height: widget.mobileHeaderHeight,
            child: widget.headerBuilder!.call(context),
          );
        }
        if (position < 1 + labelCount) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: Text(
              widget.columns.firstOrNull ?? '',
              style: labelStyle,
            ),
          );
        }
        final index = position - headerCount - labelCount;
        if (index >= widget.itemCount) {
          return widget.footerBuilder?.call(context) ?? const SizedBox.shrink();
        }
        final row = widget.itemBuilder(context, index);
        if (row == null) return const SizedBox.shrink();
        final cells = row is ListItemData ? row.children : <Widget>[row];
        final selected = widget.isItemSelected?.call(index) ?? false;
        return _MobileTableRow(
          cells: cells,
          selected: selected,
          showSelection: widget.showItemSelection,
          leading: widget.leadingBuilder?.call(context, index),
          onPressed: () => widget.onItemPressed?.call(context, index),
          onLongPressed: () => _handleLongPress(context, index),
          onSelectionChanged: (value) =>
              widget.onItemSelected?.call(context, index, value),
        );
      },
    );
  }
}

class _DesktopTableHeader extends StatelessWidget {
  const _DesktopTableHeader({
    required this.columns,
    required this.widths,
    required this.leading,
    required this.borders,
    required this.onColumnResize,
  });

  final List<String> columns;
  final List<double> widths;
  final Widget? leading;
  final bool borders;
  final void Function(int index, double delta) onColumnResize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = borders
        ? Border(bottom: BorderSide(color: theme.dividerColor, width: 1.0))
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(border: border),
      child: SizedBox(
        height: ListItemTableState.kDesktopRowHeight,
        child: Row(
          children: [
            SizedBox(
              width: ListItemTableState.kDesktopRowHeight,
              child: Center(child: leading),
            ),
            for (var i = 0; i < columns.length; i++) ...[
              SizedBox(
                width: i < widths.length ? widths[i] : 96.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      columns[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesktopTableRow extends StatefulWidget {
  const _DesktopTableRow({
    required this.cells,
    required this.widths,
    required this.borders,
    required this.selected,
    required this.showSelection,
    required this.leading,
    required this.onPressed,
    required this.onLongPressed,
    required this.onSecondaryTap,
    required this.onSelectionChanged,
  });

  final List<Widget> cells;
  final List<double> widths;
  final bool borders;
  final bool selected;
  final bool showSelection;
  final Widget leading;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final VoidCallback? onSecondaryTap;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  State<_DesktopTableRow> createState() => _DesktopTableRowState();
}

class _DesktopTableRowState extends State<_DesktopTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = widget.borders
        ? Border(bottom: BorderSide(color: theme.dividerColor, width: 1.0))
        : null;
    final showCheckbox =
        widget.showSelection && (widget.selected || _hovered);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: border,
          color: widget.selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
              : null,
        ),
        child: ContextMenuListener(
          onSecondaryPress: (_) => widget.onSecondaryTap?.call(),
          child: InkWell(
            onTap: widget.onPressed,
            onLongPress: widget.onLongPressed,
            child: SizedBox(
              height: ListItemTableState.kDesktopRowHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: showCheckbox ? 40.0 : 0.0,
                    child: showCheckbox
                        ? Checkbox(
                            value: widget.selected,
                            onChanged: (value) =>
                                widget.onSelectionChanged?.call(value ?? false),
                          )
                        : null,
                  ),
                  SizedBox(
                    width: ListItemTableState.kDesktopRowHeight,
                    height: ListItemTableState.kDesktopRowHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: widget.leading,
                    ),
                  ),
                  for (var i = 0; i < widget.cells.length; i++)
                    SizedBox(
                      width:
                          i < widget.widths.length ? widget.widths[i] : 96.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: widget.cells[i],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileTableRow extends StatelessWidget {
  const _MobileTableRow({
    required this.cells,
    required this.selected,
    required this.showSelection,
    required this.leading,
    required this.onPressed,
    required this.onLongPressed,
    required this.onSelectionChanged,
  });

  final List<Widget> cells;
  final bool selected;
  final bool showSelection;
  final Object? leading;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = cells.firstOrNull ?? const SizedBox.shrink();
    final subtitle = cells.length > 1 ? cells[1] : null;
    Widget? leadingWidget;
    final value = leading;
    if (value is Widget) {
      leadingWidget = value;
    } else if (value is String) {
      leadingWidget = Text(value);
    } else if (value is int) {
      leadingWidget = Text(value.toString());
    }
    return InkWell(
      onTap: onPressed,
      onLongPress: onLongPressed,
      child: ColoredBox(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        child: SizedBox(
          height: ListItemTableState.kMobileRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                if (selected)
                  Checkbox(
                    value: selected,
                    onChanged: (value) =>
                        onSelectionChanged?.call(value ?? false),
                  ),
                if (leadingWidget != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 56.0,
                      height: 56.0,
                      child: Center(child: leadingWidget),
                    ),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (subtitle != null)
                        DefaultTextStyle(
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          child: subtitle,
                        ),
                    ],
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
