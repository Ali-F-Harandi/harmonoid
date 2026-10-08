/// Theme extensions & theme builders for the adaptive UI.
library;

import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'enums.dart';
import 'constants.dart';
import 'material_route.dart';

/// Carries the current [LayoutVariant] inside [ThemeData].
///
/// The value is resolved live (per access) from the platform & window size,
/// so it stays correct across window resizes.
class LayoutVariantThemeExtension
    extends ThemeExtension<LayoutVariantThemeExtension> {
  const LayoutVariantThemeExtension();

  /// Currently resolved layout variant.
  LayoutVariant get value => resolveLayoutVariant();

  /// Resolves the layout variant for the running platform & window size.
  ///
  /// NOTE: [LayoutVariant.tablet] is never returned — the host application
  /// does not implement tablet-specific layouts yet.
  static LayoutVariant resolveLayoutVariant() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return LayoutVariant.desktop;
    }
    try {
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return LayoutVariant.mobile;
      final view = views.first;
      final ratio = view.devicePixelRatio == 0 ? 1.0 : view.devicePixelRatio;
      final width = view.physicalSize.width / ratio;
      if (width >= 900) return LayoutVariant.desktop;
      return LayoutVariant.mobile;
    } catch (_) {
      return LayoutVariant.mobile;
    }
  }

  @override
  LayoutVariantThemeExtension copyWith() => this;

  @override
  LayoutVariantThemeExtension lerp(
    covariant ThemeExtension<LayoutVariantThemeExtension>? other,
    double t,
  ) => this;
}

/// Carries the Material design generation (2 or 3) inside [ThemeData].
class MaterialStandard extends ThemeExtension<MaterialStandard> {
  const MaterialStandard(this.value);

  final int value;

  @override
  MaterialStandard copyWith({int? value}) => MaterialStandard(value ?? this.value);

  @override
  MaterialStandard lerp(covariant ThemeExtension<MaterialStandard>? other, double t) {
    if (other is! MaterialStandard) return this;
    return t < 0.5 ? this : other;
  }
}

/// Global animation speeds injected into [ThemeData].
class AnimationDuration extends ThemeExtension<AnimationDuration> {
  const AnimationDuration({
    this.fast = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 300),
    this.slow = const Duration(milliseconds: 450),
  });

  factory AnimationDuration.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      int? milliseconds(Object? value) => value is num ? value.round() : null;
      return AnimationDuration(
        fast: Duration(milliseconds: milliseconds(json['fast']) ?? 150),
        medium: Duration(milliseconds: milliseconds(json['medium']) ?? 300),
        slow: Duration(milliseconds: milliseconds(json['slow']) ?? 450),
      );
    }
    return const AnimationDuration();
  }

  final Duration fast;
  final Duration medium;
  final Duration slow;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fast': fast.inMilliseconds,
        'medium': medium.inMilliseconds,
        'slow': slow.inMilliseconds,
      };

  @override
  AnimationDuration copyWith({
    Duration? fast,
    Duration? medium,
    Duration? slow,
  }) {
    return AnimationDuration(
      fast: fast ?? this.fast,
      medium: medium ?? this.medium,
      slow: slow ?? this.slow,
    );
  }

  @override
  AnimationDuration lerp(covariant ThemeExtension<AnimationDuration>? other, double t) {
    if (other is! AnimationDuration) return this;
    return AnimationDuration(
      fast: Duration(milliseconds: lerpNum(fast.inMilliseconds, other.fast.inMilliseconds, t).round()),
      medium: Duration(milliseconds: lerpNum(medium.inMilliseconds, other.medium.inMilliseconds, t).round()),
      slow: Duration(milliseconds: lerpNum(slow.inMilliseconds, other.slow.inMilliseconds, t).round()),
    );
  }

  static double lerpNum(num a, num b, double t) => a + (b - a) * t;
}

/// Theme-provided icon colors for special contexts (e.g. dark overlays).
class IconColors extends ThemeExtension<IconColors> {
  const IconColors({
    this.appBarLight = const Color(0xFF000000),
    this.appBarDark = const Color(0xFFFFFFFF),
  });

  final Color appBarLight;
  final Color appBarDark;

  @override
  IconColors copyWith({Color? appBarLight, Color? appBarDark}) => IconColors(
        appBarLight: appBarLight ?? this.appBarLight,
        appBarDark: appBarDark ?? this.appBarDark,
      );

  @override
  IconColors lerp(covariant ThemeExtension<IconColors>? other, double t) {
    if (other is! IconColors) return this;
    return IconColors(
      appBarLight: Color.lerp(appBarLight, other.appBarLight, t) ?? appBarLight,
      appBarDark: Color.lerp(appBarDark, other.appBarDark, t) ?? appBarDark,
    );
  }
}

/// Builds the Material-3 [ThemeData] used by the application.
ThemeData createM3Theme({
  required BuildContext context,
  required ColorScheme lightColorScheme,
  required ColorScheme darkColorScheme,
  required ThemeMode mode,
  required AnimationDuration animationDuration,
}) {
  final colorScheme = mode == ThemeMode.dark ? darkColorScheme : lightColorScheme;
  MaterialRoute.animationDuration = animationDuration;
  return ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: kDefaultAppBarElevation,
      scrolledUnderElevation: kDefaultAppBarElevation,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: kDefaultCardElevation,
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      elevation: kDefaultHeavyElevation - 1.0,
      color: colorScheme.surfaceContainer,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1.0,
      space: 1.0,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: kDefaultHeavyElevation,
    ),
    extensions: <ThemeExtension<dynamic>>[
      const MaterialStandard(3),
      animationDuration,
      const IconColors(),
      const LayoutVariantThemeExtension(),
    ],
  );
}

/// Builds the Material-2 [ThemeData] used by the application.
ThemeData createM2Theme({
  required BuildContext context,
  required Color color,
  required ThemeMode mode,
  AnimationDuration? animationDuration,
}) {
  final duration = animationDuration ?? const AnimationDuration();
  MaterialRoute.animationDuration = duration;
  final brightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: color,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: false,
    brightness: brightness,
    colorScheme: colorScheme,
    primaryColor: color,
    scaffoldBackgroundColor:
        brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
    appBarTheme: AppBarTheme(
      backgroundColor: color,
      foregroundColor: brightness == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFFFFFFFF),
      elevation: kDefaultAppBarElevation,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: kDefaultCardElevation,
      color: brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(
      color: brightness == Brightness.dark
          ? const Color(0xFF3C3C3C)
          : const Color(0xFFE0E0E0),
      thickness: 1.0,
      space: 1.0,
    ),
    extensions: <ThemeExtension<dynamic>>[
      const MaterialStandard(2),
      duration,
      const IconColors(),
      const LayoutVariantThemeExtension(),
    ],
  );
}
