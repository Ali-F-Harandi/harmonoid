/// Weighted carousel view & controller.
///
/// NOTE: This is a community reimplementation of the (upstream private)
/// carousel API used by the application. Flutter's own `CarouselView` does
/// not expose a builder-based `CarouselView.weighted`, so this package
/// provides its own implementation.
library;

import 'package:flutter/material.dart';

/// Controls a [CarouselView].
class CarouselController {
  /// Creates a carousel controller which starts at [initialItem].
  CarouselController({int initialItem = 0}) : _initialItem = initialItem;

  final int _initialItem;

  ScrollController? _scrollController;
  double Function(int index)? _offsetOfItem;

  /// Index the view should start at.
  int get initialItem => _initialItem;

  bool get _hasClients =>
      _scrollController != null && _scrollController!.hasClients;

  void _attach(
    ScrollController scrollController,
    double Function(int index) offsetOfItem,
  ) {
    _scrollController = scrollController;
    _offsetOfItem = offsetOfItem;
  }

  void _detach() {
    _scrollController = null;
    _offsetOfItem = null;
  }

  /// Jumps to [index] without animation.
  void jumpToItem(int index) {
    if (!_hasClients || _offsetOfItem == null) return;
    final position = _scrollController!.position;
    final target = _offsetOfItem!(index)
        .clamp(0.0, position.maxScrollExtent);
    _scrollController!.jumpTo(target);
  }

  /// Animates to [index].
  Future<void> animateToItem(
    int index, {
    required Duration duration,
    required Curve curve,
  }) async {
    if (!_hasClients || _offsetOfItem == null) return;
    final position = _scrollController!.position;
    final target = _offsetOfItem!(index)
        .clamp(0.0, position.maxScrollExtent);
    await _scrollController!.animateTo(
      target,
      duration: duration,
      curve: curve,
    );
  }

  /// Releases resources.
  void dispose() {
    _detach();
  }
}

/// A horizontally scrolling carousel whose item sizes follow repeating
/// flex [CarouselView.flexWeights].
class CarouselView extends StatefulWidget {
  /// Creates a uniform carousel.
  const CarouselView({
    super.key,
    this.padding = EdgeInsets.zero,
    this.itemSnapping = false,
    this.controller,
    this.itemCount,
    this.itemBuilder,
    this.flexWeights = const <int>[1],
    this.onTap,
    this.margin,
    this.backgroundColor,
    this.elevation,
  });

  /// Creates a carousel whose item sizes follow repeating [flexWeights].
  const CarouselView.weighted({
    super.key,
    this.padding = EdgeInsets.zero,
    this.itemSnapping = false,
    this.controller,
    this.itemCount,
    this.itemBuilder,
    this.flexWeights = const <int>[1, 2, 1],
    this.onTap,
    this.margin,
    this.backgroundColor,
    this.elevation,
  });

  final EdgeInsetsGeometry padding;
  final bool itemSnapping;
  final CarouselController? controller;
  final int? itemCount;
  final Widget? Function(BuildContext context, int index)? itemBuilder;
  final List<int> flexWeights;
  final void Function(int index)? onTap;

  // Decoration-related parameters kept for API compatibility.
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;

  @override
  State<CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<CarouselView> {
  final ScrollController _scrollController = ScrollController();
  double _viewportWidth = 0.0;
  double _leadingPadding = 0.0;
  bool _initialPositionApplied = false;

  @override
  void didUpdateWidget(covariant CarouselView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      _attachController();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _scrollController.dispose();
    super.dispose();
  }

  void _attachController() {
    widget.controller?._attach(_scrollController, _offsetOfItem);
  }

  double get _weightsSum =>
      widget.flexWeights.fold<int>(0, (a, b) => a + b).toDouble();

  double get _base => _viewportWidth / (_weightsSum == 0 ? 1 : _weightsSum);

  double _itemWidth(int index) {
    final weight =
        widget.flexWeights[index % widget.flexWeights.length].toDouble();
    return _base * weight;
  }

  double _offsetOfItem(int index) {
    var offset = _leadingPadding;
    for (var i = 0; i < index; i++) {
      offset += _itemWidth(i);
    }
    return offset;
  }

  void _applyInitialPosition() {
    if (_initialPositionApplied || !_scrollController.hasClients) return;
    _initialPositionApplied = true;
    final controller = widget.controller;
    if (controller != null && controller.initialItem != 0) {
      final target = _offsetOfItem(controller.initialItem);
      _scrollController
          .jumpTo(target.clamp(0.0, _scrollController.position.maxScrollExtent));
    }
  }

  void _snap() {
    if (!widget.itemSnapping || !_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;
    final count = widget.itemCount ?? 0;
    var best = _leadingPadding;
    var bestDelta = (best - pixels).abs();
    var offset = _leadingPadding;
    for (var i = 0; i < count; i++) {
      final delta = (offset - pixels).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = offset;
      }
      offset += _itemWidth(i);
      if (offset > pixels + _viewportWidth + _base) break;
    }
    if (bestDelta < 0.5) return;
    _scrollController.animateTo(
      best.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportWidth = constraints.maxWidth;
        final textDirection = Directionality.of(context);
        final resolvedPadding = widget.padding.resolve(textDirection);
        _leadingPadding = resolvedPadding.left;
        _attachController();
        if (!_initialPositionApplied) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _applyInitialPosition());
        }
        return NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            _snap();
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            itemCount: widget.itemCount ?? 0,
            itemBuilder: (context, index) {
              final item =
                  widget.itemBuilder?.call(context, index) ?? const SizedBox.shrink();
              return InkWell(
                onTap: widget.onTap == null ? null : () => widget.onTap!(index),
                child: SizedBox(
                  width: _itemWidth(index),
                  height: constraints.maxHeight,
                  child: item,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
