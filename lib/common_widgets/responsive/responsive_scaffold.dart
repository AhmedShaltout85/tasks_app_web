import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

const double _kTopNavBreakpoint = 1000;

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? sidebarContent;
  final Widget? floatingActionButton;
  final Widget? topNavBar;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.sidebarContent,
    this.floatingActionButton,
    this.topNavBar,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showTopNav = topNavBar != null && screenWidth >= _kTopNavBreakpoint;
    final showSidebar =
        sidebarContent != null && screenWidth < _kTopNavBreakpoint;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    final effectiveTopNav = showTopNav ? topNavBar! : null;

    final topColumn = effectiveTopNav != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              effectiveTopNav,
              if (appBar != null) appBar!,
            ],
          )
        : null;

    final topHeight = (effectiveTopNav != null ? 64.0 : 0.0) +
        (appBar != null ? kToolbarHeight : 0.0);

    if (showSidebar) {
      final sidebarWidth = isTablet ? 240.0 : 220.0;

      return Scaffold(
        appBar: topColumn != null
            ? _PreferredSizeFromWidget(child: topColumn, height: topHeight)
            : appBar,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            SizedBox(
              width: sidebarWidth,
              child: Material(elevation: 2, child: sidebarContent!),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: topColumn != null
          ? _PreferredSizeFromWidget(child: topColumn, height: topHeight)
          : appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class _PreferredSizeFromWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final Widget child;
  final double height;

  const _PreferredSizeFromWidget({required this.child, required this.height});

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) => child;
}
