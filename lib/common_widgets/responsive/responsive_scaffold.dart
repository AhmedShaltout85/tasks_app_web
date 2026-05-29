import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? sidebarContent;
  final FloatingActionButton? floatingActionButton;

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
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    if (isDesktop && sidebarContent != null) {
      return Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            SizedBox(
              width: 280,
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
