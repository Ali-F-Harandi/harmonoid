/// Adaptive screen scaffolding widgets.
library;

import 'package:flutter/material.dart';

import '../constants.dart';
import '../enums.dart';
import '../theme.dart';
import 'desktop_bars.dart';

/// A plain screen with a caption, a title and a single body [content].
class ContentScreen extends StatelessWidget {
  const ContentScreen({
    super.key,
    required this.caption,
    required this.title,
    required this.content,
  });

  final String caption;
  final String title;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant =
        theme.extension<LayoutVariantThemeExtension>()?.value ?? LayoutVariant.mobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (variant == LayoutVariant.desktop)
          DesktopCaptionBar(caption: caption),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}

/// A screen whose body is a [CustomScrollView] fed by [slivers].
class SliverContentScreen extends StatefulWidget {
  const SliverContentScreen({
    super.key,
    this.implyBackButton = true,
    required this.caption,
    required this.title,
    this.subtitle,
    this.bottom,
    this.trailing,
    this.actions,
    this.labels,
    required this.slivers,
    this.floatingActionButton,
    this.scrollController,
  });

  /// Whether to show a back button in the leading slot.
  final bool implyBackButton;

  final String caption;
  final String title;
  final String? subtitle;

  /// Bottom widget of the app bar (typically a search field).
  final PreferredSizeWidget? bottom;

  /// Widget shown after the title.
  final Widget? trailing;

  /// Icon actions; callbacks receive the [BuildContext].
  final Map<IconData, void Function(BuildContext)>? actions;

  /// Tooltip labels for [actions].
  final Map<IconData, String>? labels;

  final List<Widget> slivers;
  final Widget? floatingActionButton;
  final ScrollController? scrollController;

  @override
  State<SliverContentScreen> createState() => _SliverContentScreenState();
}

class _SliverContentScreenState extends State<SliverContentScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant =
        theme.extension<LayoutVariantThemeExtension>()?.value ?? LayoutVariant.mobile;
    final isDesktop = variant == LayoutVariant.desktop;

    final entries = widget.actions?.entries.toList() ?? const <MapEntry<IconData, void Function(BuildContext)>>[];
    final actions = entries
        .map(
          (entry) => IconButton(
            icon: Icon(entry.key),
            tooltip: widget.labels?[entry.key],
            onPressed: () => entry.value(context),
          ),
        )
        .toList();

    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          if (isDesktop)
            SliverToBoxAdapter(
              child: DesktopCaptionBar(caption: widget.caption),
            ),
          SliverAppBar(
            pinned: true,
            floating: false,
            automaticallyImplyLeading: widget.implyBackButton,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: kDefaultAppBarElevation,
            scrolledUnderElevation: kDefaultAppBarElevation,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (widget.trailing != null) widget.trailing!,
              ...actions,
            ],
            bottom: widget.bottom,
          ),
          ...widget.slivers,
        ],
      ),
    );
  }
}

/// A detail screen with a hero header, tabs & tab contents.
class HeroContentScreen extends StatelessWidget {
  const HeroContentScreen({
    super.key,
    this.mergeHeroAndContent,
    this.palette,
    this.heroBuilder,
    required this.caption,
    required this.title,
    this.subtitle,
    this.implyBackButton = true,
    this.actions,
    this.labels,
    required this.tabs,
    required this.content,
  });

  /// Whether the hero header merges visually with the content below.
  final bool? mergeHeroAndContent;

  /// Color palette used for the default hero gradient.
  final List<Color>? palette;

  /// Custom hero widget; defaults to a gradient with titles.
  final Widget Function(BuildContext context)? heroBuilder;

  final String caption;
  final String title;
  final String? subtitle;
  final bool implyBackButton;

  /// Icon actions; callbacks receive the [BuildContext] and an ignored value.
  final Map<IconData, void Function(BuildContext, dynamic)>? actions;

  /// Tooltip labels for [actions].
  final Map<IconData, String>? labels;

  /// Tab labels.
  final List<String> tabs;

  /// One widget per tab.
  final List<Widget> content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant =
        theme.extension<LayoutVariantThemeExtension>()?.value ?? LayoutVariant.mobile;
    final isDesktop = variant == LayoutVariant.desktop;
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight =
        isDesktop ? width.clamp(160.0, 320.0) * 0.75 : width * 0.55;

    final entries =
        actions?.entries.toList() ?? const <MapEntry<IconData, void Function(BuildContext, dynamic)>>[];
    final actionButtons = entries
        .map(
          (entry) => IconButton(
            icon: Icon(entry.key),
            tooltip: labels?[entry.key],
            onPressed: () => entry.value(context, null),
          ),
        )
        .toList();

    final palette = this.palette ??
        [
          theme.colorScheme.primary,
          theme.colorScheme.primaryContainer,
        ];

    final hero = heroBuilder?.call(context) ??
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: palette,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

    final merged = mergeHeroAndContent ?? true;

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop) DesktopCaptionBar(caption: caption),
          Stack(
            children: [
              SizedBox(
                height: heroHeight,
                width: double.infinity,
                child: hero,
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      if (implyBackButton && Navigator.of(context).canPop())
                        const BackButton(),
                      const Spacer(),
                      ...actionButtons,
                      const SizedBox(width: 8.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!merged) const Divider(height: 1.0),
          Material(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              tabs: [
                for (final tab in tabs)
                  Tab(
                    text: tab.isEmpty ? ' ' : tab,
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final tabContent in content)
                  tabContent,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
