/// Localizations for the package's own built-in UI.
library;

import 'package:flutter/widgets.dart';

/// Supplies localized strings used by widgets of this package
/// (e.g. [FileExplorer]).
class AdaptiveLayoutsLocalizations extends InheritedWidget {
  const AdaptiveLayoutsLocalizations({
    super.key,
    required this.code,
    required this.aToZ,
    required this.back,
    required this.dateAdded,
    required this.files,
    required this.folders,
    required this.grid,
    required this.hideHiddenFiles,
    required this.list,
    required this.more,
    required this.select,
    required this.showHiddenFiles,
    required this.type,
    required this.unselect,
    required super.child,
  });

  /// Locale code, e.g. `en_US`.
  final String code;
  final String aToZ;
  final String back;
  final String dateAdded;
  final String files;
  final String folders;
  final String grid;
  final String hideHiddenFiles;
  final String list;
  final String more;
  final String select;
  final String showHiddenFiles;
  final String type;
  final String unselect;

  /// English fallback values.
  static const AdaptiveLayoutsLocalizations fallback = AdaptiveLayoutsLocalizations(
    code: 'en_US',
    aToZ: 'A to Z',
    back: 'Back',
    dateAdded: 'Date added',
    files: 'Files',
    folders: 'Folders',
    grid: 'Grid',
    hideHiddenFiles: 'Hide hidden files',
    list: 'List',
    more: 'More',
    select: 'Select',
    showHiddenFiles: 'Show hidden files',
    type: 'Type',
    unselect: 'Unselect',
    child: SizedBox.shrink(),
  );

  /// Returns the nearest [AdaptiveLayoutsLocalizations] or English fallback.
  static AdaptiveLayoutsLocalizations of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AdaptiveLayoutsLocalizations>() ??
        fallback;
  }

  @override
  bool updateShouldNotify(AdaptiveLayoutsLocalizations oldWidget) {
    return code != oldWidget.code ||
        aToZ != oldWidget.aToZ ||
        back != oldWidget.back ||
        dateAdded != oldWidget.dateAdded ||
        files != oldWidget.files ||
        folders != oldWidget.folders ||
        grid != oldWidget.grid ||
        hideHiddenFiles != oldWidget.hideHiddenFiles ||
        list != oldWidget.list ||
        more != oldWidget.more ||
        select != oldWidget.select ||
        showHiddenFiles != oldWidget.showHiddenFiles ||
        type != oldWidget.type ||
        unselect != oldWidget.unselect;
  }
}
