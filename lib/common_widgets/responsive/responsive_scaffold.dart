import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? sidebarContent;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.sidebarContent,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveValue = ResponsiveBreakpoints.of(context);
    final isDesktop = responsiveValue.isDesktop;
    final isTablet = responsiveValue.isTablet;

    if (sidebarContent != null) {
      final sidebarWidth = isDesktop ? 280.0 : (isTablet ? 240.0 : 220.0);

      return Scaffold(
        appBar: appBar,
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
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
