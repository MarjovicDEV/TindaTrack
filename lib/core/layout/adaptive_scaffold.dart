import 'package:flutter/material.dart';

/// Max width for main content on large screens (Clean Ledger web layout).
const double _kContentMaxWidth = 1200;

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.title,
    this.titleWidget,
    this.appBarActions = const [],
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    super.key,
  });

  final String title;
  final Widget? titleWidget;
  final List<Widget> appBarActions;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final scheme = Theme.of(context).colorScheme;

    Widget framedBody(BoxConstraints constraints) {
      final w = constraints.maxWidth;
      final padH = w >= 1200 ? 28.0 : (w >= 600 ? 20.0 : 16.0);
      final padV = w >= 600 ? 14.0 : 10.0;
      final padded = Padding(
        padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
        child: isWide
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _kContentMaxWidth,
                  ),
                  child: body,
                ),
              )
            : body,
      );
      return padded;
    }

    return Scaffold(
      appBar: AppBar(title: titleWidget ?? Text(title), actions: appBarActions),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: scheme.surface,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon ?? d.icon,
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: LayoutBuilder(builder: (context, c) => framedBody(c)),
                ),
              ],
            )
          : LayoutBuilder(builder: (context, c) => framedBody(c)),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ),
    );
  }
}
