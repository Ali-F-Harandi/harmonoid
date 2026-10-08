/// Desktop caption/app bars.
library;

import 'package:flutter/material.dart';
import 'package:window_plus/window_plus.dart';

import '../constants.dart';
import '../enums.dart';
import '../theme.dart';

/// The window caption bar (drag region + window buttons) shown on desktop.
class DesktopCaptionBar extends StatelessWidget {
  const DesktopCaptionBar({super.key, required this.caption, this.color});

  /// Caption text (application title) shown inside the bar.
  final String caption;

  /// Background color; defaults to the scaffold background.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant =
        theme.extension<LayoutVariantThemeExtension>()?.value ?? LayoutVariant.desktop;
    if (variant != LayoutVariant.desktop) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: color ?? theme.scaffoldBackgroundColor,
      child: WindowCaption(
        brightness: theme.brightness,
        child: Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}

/// The window caption bar with an optional elevation (used over the
/// now-playing screen).
class DesktopAppBar extends StatelessWidget {
  const DesktopAppBar({
    super.key,
    required this.caption,
    this.color,
    this.elevation,
  });

  final String caption;
  final Color? color;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color ?? theme.scaffoldBackgroundColor,
      elevation: elevation ?? kDefaultAppBarElevation,
      child: DesktopCaptionBar(caption: caption, color: color),
    );
  }
}
