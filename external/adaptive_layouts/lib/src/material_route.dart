/// Adaptive material page route.
library;

import 'package:flutter/material.dart';

import 'theme.dart';

/// A [PageRoute] with a subtle fade & slide transition, honoring the
/// application's [AnimationDuration].
class MaterialRoute<T> extends PageRouteBuilder<T> {
  MaterialRoute({
    required WidgetBuilder builder,
    super.settings,
    bool fullscreenDialog = false,
  }) : super(
          fullscreenDialog: fullscreenDialog,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          transitionDuration: kDefaultTransitionDuration,
          reverseTransitionDuration: kDefaultTransitionDuration,
        );

  /// Default duration of the page transition.
  static const Duration kDefaultTransitionDuration = Duration(milliseconds: 300);

  /// Animation durations of the currently active theme.
  ///
  /// Fed by [createM3Theme] / [createM2Theme].
  static AnimationDuration? animationDuration;
}
