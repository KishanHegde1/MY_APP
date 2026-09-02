import 'package:flutter/material.dart';

class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
    required this.destinations,
    super.key,
  });
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final List<NavigationDestination> destinations;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
    ),
  );
}
