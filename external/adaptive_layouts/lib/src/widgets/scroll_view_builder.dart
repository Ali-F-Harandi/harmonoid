/// Sectioned grid/scroll-view builder.
library;

import 'package:flutter/material.dart';

import '../enums.dart';
import '../theme.dart';

/// An adaptive grid with optional section headers.
class ScrollViewBuilder extends StatefulWidget {
  const ScrollViewBuilder({
    super.key,
    required this.margin,
    this.span,
    this.displayHeaders = true,
    required this.headerCount,
    required this.headerBuilder,
    required this.headerHeight,
    required this.itemCounts,
    required this.itemBuilder,
    required this.itemWidth,
    required this.itemHeight,
    this.displayLabel = false,
    this.labelTextStyle,
    required this.padding,
    this.shrinkWrap = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// Outer margin of the scroll view.
  final double margin;

  /// Number of mobile grid columns; `null` on desktop.
  final int? span;

  /// Whether section headers are displayed.
  final bool displayHeaders;

  /// Number of sections.
  final int headerCount;

  /// Builds the header of the section at [index].
  final Widget Function(BuildContext context, int index, double width)
      headerBuilder;

  /// Height of each section header.
  final double headerHeight;

  /// Number of items per section.
  final List<int> itemCounts;

  /// Builds the item at [itemIndex] within the section [sectionIndex].
  final Widget Function(
    BuildContext context,
    int sectionIndex,
    int itemIndex,
    double width,
    double height,
  ) itemBuilder;

  final double itemWidth;
  final double itemHeight;

  /// Whether item labels are displayed (mobile linear tiles).
  final bool displayLabel;

  final TextStyle? labelTextStyle;

  final EdgeInsets padding;

  /// Whether the view shrink-wraps (embedded, non-scrolling usage).
  final bool shrinkWrap;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<ScrollViewBuilder> createState() => ScrollViewBuilderState();
}

/// Public state of [ScrollViewBuilder]; supports [animateToHeader].
class ScrollViewBuilderState extends State<ScrollViewBuilder> {
  final ScrollController _controller = ScrollController();
  final List<GlobalKey> _headerKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didUpdateWidget(covariant ScrollViewBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.headerCount != widget.headerCount) {
      _syncKeys();
    }
  }

  void _syncKeys() {
    _headerKeys
      ..clear()
      ..addAll(List<GlobalKey>.generate(widget.headerCount, (_) => GlobalKey()));
  }

  /// Scrolls to the section [header] with an additional pixel [difference].
  void animateToHeader(int header, {double difference = 0.0}) {
    if (header < 0 || header >= _headerKeys.length) return;
    final context = _headerKeys[header].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      alignment: 0.0,
    );
    if (difference != 0.0 && _controller.hasClients) {
      final target = (_controller.offset + difference)
          .clamp(0.0, _controller.position.maxScrollExtent);
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant =
        theme.extension<LayoutVariantThemeExtension>()?.value ?? LayoutVariant.mobile;
    final isDesktop = variant == LayoutVariant.desktop;

    final slivers = <Widget>[];
    for (var section = 0; section < widget.headerCount; section++) {
      if (widget.displayHeaders) {
        slivers.add(
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _headerKeys[section],
              child: SizedBox(
                height: widget.headerHeight,
                child: widget.headerBuilder(context, section, double.infinity),
              ),
            ),
          ),
        );
      }
      final count = widget.itemCounts.length > section
          ? widget.itemCounts[section]
          : 0;
      if (isDesktop && widget.span == null) {
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.symmetric(vertical: widget.margin * 0.5),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.crossAxisExtent;
                final crossAxisCount =
                    (available / widget.itemWidth).floor().clamp(1, 1024);
                final tileWidth = available / crossAxisCount;
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => widget.itemBuilder(
                      context,
                      section,
                      index,
                      tileWidth,
                      widget.itemHeight,
                    ),
                    childCount: count,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: widget.margin * 0.5,
                    crossAxisSpacing: widget.margin * 0.5,
                    childAspectRatio: tileWidth / widget.itemHeight,
                  ),
                );
              },
            ),
          ),
        );
      } else if (widget.span == 1) {
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.symmetric(vertical: widget.margin * 0.25),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SizedBox(
                  height: widget.itemHeight,
                  child: widget.itemBuilder(
                    context,
                    section,
                    index,
                    double.infinity,
                    widget.itemHeight,
                  ),
                ),
                childCount: count,
              ),
            ),
          ),
        );
      } else {
        final crossAxisCount = widget.span ?? 2;
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.symmetric(vertical: widget.margin * 0.5),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.crossAxisExtent;
                final tileWidth = available / crossAxisCount;
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => widget.itemBuilder(
                      context,
                      section,
                      index,
                      tileWidth,
                      widget.itemHeight,
                    ),
                    childCount: count,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: widget.margin * 0.5,
                    crossAxisSpacing: widget.margin * 0.5,
                    childAspectRatio: tileWidth / widget.itemHeight,
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    return CustomScrollView(
      controller: _controller,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      slivers: [
        SliverPadding(
          padding: widget.padding,
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
  }
}
