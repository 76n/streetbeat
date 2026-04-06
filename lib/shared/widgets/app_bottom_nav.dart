import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    this.selectedIndex = 0,
  });

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dynamic_feed_outlined),
          selectedIcon: Icon(Icons.dynamic_feed),
          label: 'Feed',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_run_outlined),
          selectedIcon: Icon(Icons.directions_run),
          label: 'Run',
        ),
        NavigationDestination(
          icon: Icon(Icons.leaderboard_outlined),
          selectedIcon: Icon(Icons.leaderboard),
          label: 'Board',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onDestinationSelected: (_) {},
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.25),
    );
  }
}
