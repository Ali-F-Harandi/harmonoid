/// PageStorage-persisted scroll controllers.
library;

import 'package:flutter/material.dart';

/// Builds a widget with a [PageStorage]-persisted [ScrollController].
class ScrollControllerBuilder extends StatefulWidget {
  const ScrollControllerBuilder({
    super.key,
    required this.keyName,
    required this.builder,
  });

  /// Storage key of the controller.
  final String keyName;

  /// Builder receiving the persisted controller.
  final Widget Function(BuildContext context, ScrollController controller) builder;

  @override
  State<ScrollControllerBuilder> createState() => _ScrollControllerBuilderState();
}

class _ScrollControllerBuilderState extends State<ScrollControllerBuilder> {
  late final ScrollController _controller = ScrollController(
    keepScrollOffset: true,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: PageStorageKey<String>(widget.keyName),
      child: widget.builder(context, _controller),
    );
  }
}

/// Mixin providing [PageStorage]-persisted scroll controllers to [State]s.
mixin ScrollControllerMixin<T extends StatefulWidget> on State<T> {
  final Map<String, ScrollController> _scrollControllers = <String, ScrollController>{};

  /// Returns a [PageStorage]-persisted scroll controller for [keyName].
  ScrollController getScrollController(
    String keyName, {
    double initialScrollOffset = 0.0,
  }) {
    return _scrollControllers.putIfAbsent(
      keyName,
      () => ScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: true,
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    super.dispose();
  }
}
