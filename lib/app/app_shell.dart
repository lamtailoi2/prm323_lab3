import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Top-level destinations, in the fixed order of `DESIGN.md` §9 and Figma
/// page 05 "Bottom Navigation". Never rename or reorder them per screen.
enum AppDestination {
  home('Home', Symbols.home_rounded),
  search('Search', Symbols.search_rounded),
  saved('Saved', Symbols.bookmark_rounded),
  applications('Applications', Symbols.description_rounded),
  profile('Profile', Symbols.person_rounded);

  const AppDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Scaffold with the bottom navigation for the five top-level tabs. Each tab
/// keeps its own navigation stack ([StatefulNavigationShell]).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Re-tapping the current tab returns to its first screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final destination in AppDestination.values)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
