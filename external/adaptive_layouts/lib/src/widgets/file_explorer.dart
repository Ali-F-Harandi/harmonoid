/// Adaptive file explorer.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:safe_local_storage/file_system.dart';

import '../enums.dart';
import '../localizations.dart';
import '../order_result.dart';
import '../theme.dart';
import 'context_menu_listener.dart';
import 'list_item_table.dart'
    show DesktopOnColumnResize, ListItemData, ListItemTableState;

/// An adaptive file/folder browser with sorting, hidden-file toggling,
/// selection, popup menus & list/grid views.
class FileExplorer extends StatefulWidget {
  const FileExplorer({
    super.key,
    required this.viewType,
    required this.sortType,
    required this.sortAscending,
    required this.showHiddenFiles,
    this.initialLabel,
    this.initialDirectories = const <Directory>[],
    required this.columns,
    this.headerBuilder,
    this.emptyBuilder,
    required this.itemBuilder,
    this.leadingBuilder,
    this.popupMenuBuilder,
    this.directoryPopupMenuBuilder,
    this.onItemPressed,
    this.onPopupMenuItemSelected,
    this.onDirectoryPopupMenuItemSelected,
    this.showItemSelection = false,
    this.isItemSelectionEnabled,
    this.isItemSelected,
    this.onItemSelected,
    this.itemSelectionChangeNotifier,
    this.onLoaded,
    this.onViewTypeChanged,
    this.onShowHiddenFilesChanged,
    this.sortKey,
    this.sortCallback,
    this.filterCallback,
    required this.padding,
    required this.headerHeight,
    this.desktopColumnWidths,
    this.desktopOnColumnResize,
  });

  /// Current view mode.
  final FileExplorerViewType viewType;

  /// Current sort criterion.
  final FileExplorerSortType sortType;

  /// Whether sorting is ascending.
  final bool sortAscending;

  /// Whether hidden files are shown.
  final bool showHiddenFiles;

  /// Label of the root (e.g. `.`).
  final String? initialLabel;

  /// Directories listed at the root level.
  final List<Directory> initialDirectories;

  /// Column labels (desktop list view).
  final List<String> columns;

  /// Optional header shown at the top.
  final WidgetBuilder? headerBuilder;

  /// Optional empty-state widget.
  final WidgetBuilder? emptyBuilder;

  /// Builds the row of a file entity; returns a [ListItemData] or `null`.
  final Widget? Function(BuildContext context, FileSystemEntity entity)
      itemBuilder;

  /// Builds the leading cell (cover image) of a file entity.
  final Widget? Function(BuildContext context, FileSystemEntity entity)?
      leadingBuilder;

  /// Popup menu items for file entities.
  final FutureOr<List<PopupMenuItem<int>>> Function(
    BuildContext context,
    FileSystemEntity entity,
  )? popupMenuBuilder;

  /// Popup menu items for directories.
  final FutureOr<List<PopupMenuItem<int>>> Function(
    BuildContext context,
    Directory directory,
  )? directoryPopupMenuBuilder;

  /// Invoked when a file entity is pressed; receives all listed files.
  final void Function(
    BuildContext context,
    Iterable<File> entities,
    int index,
  )? onItemPressed;

  /// Invoked when a popup menu item of a file entity is selected.
  final FutureOr<void> Function(
    BuildContext context,
    FileSystemEntity entity,
    dynamic result,
  )? onPopupMenuItemSelected;

  /// Invoked when a popup menu item of a directory is selected.
  final FutureOr<void> Function(
    BuildContext context,
    Directory directory,
    dynamic result,
  )? onDirectoryPopupMenuItemSelected;

  /// Whether entities can be (multi-)selected.
  final bool showItemSelection;

  /// Whether an entity can be selected.
  final bool Function(FileSystemEntity entity)? isItemSelectionEnabled;

  /// Whether an entity is selected.
  final bool Function(FileSystemEntity entity)? isItemSelected;

  /// Invoked when the selection of an entity changes.
  final void Function(BuildContext context, FileSystemEntity entity, bool value)?
      onItemSelected;

  /// Notifier listened to for selection changes.
  final Listenable? itemSelectionChangeNotifier;

  /// Reports the loaded directory contents.
  final void Function(OrderResult result)? onLoaded;

  /// Invoked when the view type is changed through the built-in menu.
  final void Function(FileExplorerViewType viewType)? onViewTypeChanged;

  /// Invoked when the hidden-files visibility is toggled.
  final void Function(bool showHiddenFiles)? onShowHiddenFilesChanged;

  /// Invalidation key for sorting (re-sorts when changed).
  final Object? sortKey;

  /// Sort key provider for entities; `null` falls back to the file name.
  final Comparable<dynamic>? Function(FileSystemEntity entity)? sortCallback;

  /// Filter for entities.
  final bool Function(FileSystemEntity entity)? filterCallback;

  final EdgeInsets padding;

  /// Height of the [headerBuilder] slot.
  final double headerHeight;

  /// Absolute column widths (desktop list view).
  final List<double>? desktopColumnWidths;

  /// Fired when desktop columns are resized.
  final DesktopOnColumnResize? desktopOnColumnResize;

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

/// The currently active [FileExplorer] state, if any.
_FileExplorerState? _activeFileExplorer;

/// Whether the active [FileExplorer] can navigate back.
bool get fileExplorerCanPop => _activeFileExplorer?._canBack ?? false;

/// Handler for global "navigate back" requests (mouse buttons etc.).
///
/// Assigned by the active [FileExplorer]; returns whether the navigation
/// was handled.
bool Function()? fileExplorerNavigateBack;

/// Handler for global "navigate forward" requests (mouse buttons etc.).
///
/// Assigned by the active [FileExplorer]; returns whether the navigation
/// was handled.
bool Function()? fileExplorerNavigateForward;

class _FileExplorerState extends State<FileExplorer> {
  Directory? _directory;
  OrderResult _entities = const OrderResult();
  bool _loading = true;
  late List<double> _columnWidths;

  /// Navigation history; `null` represents the root view.
  final List<Directory?> _history = <Directory?>[null];
  int _historyIndex = 0;

  bool get _canBack => _historyIndex > 0;
  bool get _canForward => _historyIndex < _history.length - 1;

  @override
  void initState() {
    super.initState();
    _columnWidths = List<double>.of(widget.desktopColumnWidths ?? const <double>[]);
    _activeFileExplorer = this;
    fileExplorerNavigateBack = _handleGlobalNavigateBack;
    fileExplorerNavigateForward = _handleGlobalNavigateForward;
    _load();
  }

  @override
  void dispose() {
    if (_activeFileExplorer == this) {
      _activeFileExplorer = null;
      fileExplorerNavigateBack = null;
      fileExplorerNavigateForward = null;
    }
    super.dispose();
  }

  bool _handleGlobalNavigateBack() {
    if (!_canBack) return false;
    _navigateBack();
    return true;
  }

  bool _handleGlobalNavigateForward() {
    if (!_canForward) return false;
    _navigateForward();
    return true;
  }

  @override
  void didUpdateWidget(covariant FileExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortKey != widget.sortKey ||
        oldWidget.sortType != widget.sortType ||
        oldWidget.sortAscending != widget.sortAscending ||
        oldWidget.showHiddenFiles != widget.showHiddenFiles ||
        oldWidget.initialDirectories != widget.initialDirectories) {
      _load();
    }
    if (widget.desktopColumnWidths != null &&
        widget.desktopColumnWidths!.length == widget.columns.length) {
      _columnWidths = List<double>.of(widget.desktopColumnWidths!);
    }
  }

  Future<void> _load() async {
    final directory = _directory;
    var directories = <Directory>[];
    var files = <File>[];
    if (directory == null) {
      directories = List<Directory>.of(widget.initialDirectories);
    } else {
      try {
        final children = await directory.children_();
        for (final entity in children) {
          if (!widget.showHiddenFiles &&
              _basename(entity.path).startsWith('.')) {
            continue;
          }
          if (entity is Directory) {
            directories.add(entity);
          } else if (entity is File) {
            files.add(entity);
          }
        }
      } catch (_) {
        // Directory might have been removed.
      }
    }
    final filter = widget.filterCallback;
    if (filter != null) {
      directories = directories.where(filter).toList();
      files = files.where(filter).toList();
    }
    _sortEntities(directories);
    _sortEntities(files);
    if (!mounted) return;
    setState(() {
      _entities = OrderResult(directories: directories, files: files);
      _loading = false;
    });
    widget.onLoaded?.call(_entities);
  }

  void _sortEntities(List<FileSystemEntity> entities) {
    final callback = widget.sortCallback;
    entities.sort((a, b) {
      final ka = a is Directory ? _basename(a.path) : callback?.call(a);
      final kb = b is Directory ? _basename(b.path) : callback?.call(b);
      int result;
      if (ka == null && kb == null) {
        result = _basename(a.path).compareTo(_basename(b.path));
      } else if (ka == null) {
        result = 1;
      } else if (kb == null) {
        result = -1;
      } else {
        result = ka.compareTo(kb);
      }
      return widget.sortAscending ? result : -result;
    });
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').lastOrNull ?? path;
  }

  void _openDirectory(Directory directory) {
    _history.removeRange(_historyIndex + 1, _history.length);
    _history.add(directory);
    _historyIndex++;
    _setDirectory(directory);
  }

  void _setDirectory(Directory? directory) {
    setState(() {
      _directory = directory;
      _loading = true;
    });
    _load();
  }

  bool _navigateBack() {
    if (!_canBack) return false;
    _historyIndex--;
    _setDirectory(_history[_historyIndex]);
    return true;
  }

  bool _navigateForward() {
    if (!_canForward) return false;
    _historyIndex++;
    _setDirectory(_history[_historyIndex]);
    return true;
  }

  void _back() {
    _navigateBack();
  }

  String get _label {
    if (_directory == null) {
      return widget.initialLabel ?? '';
    }
    return _basename(_directory!.path);
  }

  Future<void> _showEntityMenu(
    BuildContext context,
    FileSystemEntity entity,
    RelativeRect? position,
  ) async {
    final List<PopupMenuItem<int>> items;
    if (entity is Directory) {
      items = await widget.directoryPopupMenuBuilder?.call(context, entity) ??
          const <PopupMenuItem<int>>[];
    } else {
      items =
          await widget.popupMenuBuilder?.call(context, entity) ?? const <PopupMenuItem<int>>[];
    }
    if (items.isEmpty || !mounted) return;
    final result = await showMenu<int>(
      context: context,
      position: position ?? _menuPosition(context),
      items: items,
    );
    if (result == null) return;
    if (entity is Directory) {
      await widget.onDirectoryPopupMenuItemSelected?.call(context, entity, result);
    } else {
      await widget.onPopupMenuItemSelected?.call(context, entity, result);
    }
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

  void _handleEntityPressed(FileSystemEntity entity) {
    if (entity is Directory) {
      _openDirectory(entity);
      return;
    }
    final files = _entities.files;
    final index = files.indexOf(entity as File);
    widget.onItemPressed?.call(context, files, index < 0 ? 0 : index);
  }

  void _handleEntityLongPress(FileSystemEntity entity) {
    if (widget.showItemSelection &&
        (widget.isItemSelectionEnabled?.call(entity) ?? true)) {
      final selected = widget.isItemSelected?.call(entity) ?? false;
      widget.onItemSelected?.call(context, entity, !selected);
    }
  }

  void _handleColumnResize(int index, double delta) {
    setState(() {
      final value = _columnWidths[index] + delta;
      _columnWidths[index] = value.clamp(40.0, 4096.0);
    });
    widget.desktopOnColumnResize?.call(List<double>.of(_columnWidths));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant =
        theme.extension<LayoutVariantThemeExtension>()?.value ?? LayoutVariant.mobile;
    final isDesktop = variant == LayoutVariant.desktop;
    final localization = AdaptiveLayoutsLocalizations.of(context);

    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_entities.directories.isEmpty && _entities.files.isEmpty) {
      content = widget.emptyBuilder?.call(context) ??
          Center(
            child: Text(
              'No items',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
    } else if (widget.viewType == FileExplorerViewType.grid) {
      content = _buildGrid(context);
    } else {
      content = isDesktop
          ? _buildDesktopList(context, localization)
          : _buildMobileList(context, localization);
    }

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerBuilder != null)
          SizedBox(
            height: widget.headerHeight,
            child: widget.headerBuilder!.call(context),
          ),
        if (!isDesktop) _buildLabelBar(context, localization),
        Expanded(
          child: Padding(
            padding: widget.padding,
            child: content,
          ),
        ),
      ],
    );

    if (widget.itemSelectionChangeNotifier != null) {
      body = ListenableBuilder(
        listenable: widget.itemSelectionChangeNotifier!,
        builder: (context, _) => body,
      );
    }

    return body;
  }

  Widget _buildLabelBar(
    BuildContext context,
    AdaptiveLayoutsLocalizations localization,
  ) {
    final theme = Theme.of(context);
    final canBack = _directory != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          if (canBack)
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              tooltip: localization.back,
              onPressed: _back,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: localization.more,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'view-type':
                  final next = widget.viewType == FileExplorerViewType.list
                      ? FileExplorerViewType.grid
                      : FileExplorerViewType.list;
                  widget.onViewTypeChanged?.call(next);
                  break;
                case 'hidden-files':
                  widget.onShowHiddenFilesChanged?.call(!widget.showHiddenFiles);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view-type',
                child: Text(
                  widget.viewType == FileExplorerViewType.list
                      ? localization.grid
                      : localization.list,
                ),
              ),
              PopupMenuItem(
                value: 'hidden-files',
                child: Text(
                  widget.showHiddenFiles
                      ? localization.hideHiddenFiles
                      : localization.showHiddenFiles,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);
    final entities = <FileSystemEntity>[
      ..._entities.directories,
      ..._entities.files,
    ];
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 156.0,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 0.82,
      ),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        final entity = entities[index];
        final row = widget.itemBuilder(context, entity);
        final cells =
            row is ListItemData ? row.children : const <Widget>[];
        final title = cells.firstOrNull;
        final subtitle = cells.length > 1 ? cells[1] : null;
        final selected = widget.isItemSelected?.call(entity) ?? false;
        final leading = entity is Directory
            ? Icon(
                Icons.folder_outlined,
                size: 96.0,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : widget.leadingBuilder?.call(context, entity);
        return ContextMenuListener(
          onSecondaryPress: (position) =>
              _showEntityMenu(context, entity, position),
          child: InkWell(
            onTap: () => _handleEntityPressed(entity),
            onLongPress: () => _handleEntityLongPress(entity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(child: leading ?? const SizedBox.shrink()),
                      if (selected)
                        ColoredBox(
                          color:
                              theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                        ),
                      if (selected)
                        Align(
                          alignment: AlignmentDirectional.topStart,
                          child: Checkbox(
                            value: true,
                            onChanged: (value) =>
                                widget.onItemSelected?.call(context, entity, false),
                          ),
                        ),
                    ],
                  ),
                ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: title,
                  ),
                if (subtitle != null) subtitle,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopList(
    BuildContext context,
    AdaptiveLayoutsLocalizations localization,
  ) {
    final theme = Theme.of(context);
    final entities = <FileSystemEntity>[
      ..._entities.directories,
      ..._entities.files,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        var widths = _columnWidths;
        if (widths.length != widget.columns.length) {
          final each = (constraints.maxWidth - ListItemTableState.kDesktopRowHeight) /
              (widget.columns.length == 0 ? 1 : widget.columns.length);
          widths = List<double>.filled(widget.columns.length, each);
          _columnWidths = widths;
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DesktopExplorerHeader(
                columns: widget.columns,
                widths: widths,
                leadingIcon: Icons.folder_outlined,
                onColumnResize: _handleColumnResize,
              ),
            ),
            SliverList.builder(
              itemBuilder: (context, index) {
                final entity = entities[index];
                return _buildDesktopRow(
                  context,
                  entity,
                  widths,
                  theme,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopRow(
    BuildContext context,
    FileSystemEntity entity,
    List<double> widths,
    ThemeData theme,
  ) {
    final isDirectory = entity is Directory;
    final row = isDirectory ? null : widget.itemBuilder(context, entity);
    final cells = row is ListItemData ? row.children : const <Widget>[];
    final selected = widget.isItemSelected?.call(entity) ?? false;
    final leading = isDirectory
        ? Icon(
            Icons.folder_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          )
        : widget.leadingBuilder?.call(context, entity);

    final children = <Widget>[
      SizedBox(
        width: ListItemTableState.kDesktopRowHeight,
        height: ListItemTableState.kDesktopRowHeight,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(child: leading),
        ),
      ),
      for (var i = 0; i < widget.columns.length; i++)
        SizedBox(
          width: i < widths.length ? widths[i] : 96.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: i == 0
                  ? (isDirectory
                      ? Text(
                          _basename(entity.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        )
                      : (cells.firstOrNull ??
                          const SizedBox.shrink()))
                  : (i < cells.length && !isDirectory
                      ? cells[i]
                      : const SizedBox.shrink()),
            ),
          ),
        ),
    ];

    return ContextMenuListener(
      onSecondaryPress: (position) => _showEntityMenu(context, entity, position),
      child: InkWell(
        onTap: () => _handleEntityPressed(entity),
        onLongPress: () => _handleEntityLongPress(entity),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1.0),
            ),
            color: selected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                : null,
          ),
          child: SizedBox(
            height: ListItemTableState.kDesktopRowHeight,
            child: Row(children: children),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    AdaptiveLayoutsLocalizations localization,
  ) {
    final theme = Theme.of(context);
    final entities = <FileSystemEntity>[
      ..._entities.directories,
      ..._entities.files,
    ];
    return ListView.builder(
      itemCount: entities.length,
      itemBuilder: (context, index) {
        final entity = entities[index];
        final isDirectory = entity is Directory;
        final row = isDirectory ? null : widget.itemBuilder(context, entity);
        final cells = row is ListItemData ? row.children : const <Widget>[];
        final selected = widget.isItemSelected?.call(entity) ?? false;
        final leading = isDirectory
            ? Icon(
                Icons.folder_outlined,
                size: 48.0,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : widget.leadingBuilder?.call(context, entity);
        return ContextMenuListener(
          onSecondaryPress: (position) =>
              _showEntityMenu(context, entity, position),
          child: InkWell(
            onTap: () => _handleEntityPressed(entity),
            onLongPress: () => _handleEntityLongPress(entity),
            child: SizedBox(
              height: ListItemTableState.kMobileRowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    if (selected)
                      Checkbox(
                        value: true,
                        onChanged: (value) =>
                            widget.onItemSelected?.call(context, entity, false),
                      ),
                    SizedBox(
                      width: 56.0,
                      height: 56.0,
                      child: Center(child: leading),
                    ),
                    Expanded(
                      child: isDirectory
                          ? Text(
                              _basename(entity.path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                cells.firstOrNull ?? const SizedBox.shrink(),
                                if (cells.length > 1)
                                  DefaultTextStyle(
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    child: cells[1],
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
      },
    );
  }
}

class _DesktopExplorerHeader extends StatelessWidget {
  const _DesktopExplorerHeader({
    required this.columns,
    required this.widths,
    required this.leadingIcon,
    required this.onColumnResize,
  });

  final List<String> columns;
  final List<double> widths;
  final IconData leadingIcon;
  final void Function(int index, double delta) onColumnResize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.0)),
      ),
      child: SizedBox(
        height: ListItemTableState.kDesktopRowHeight,
        child: Row(
          children: [
            SizedBox(
              width: ListItemTableState.kDesktopRowHeight,
              child: Icon(leadingIcon, size: 20.0),
            ),
            for (var i = 0; i < columns.length; i++)
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
        ),
      ),
    );
  }
}
