import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/feed/screens/feed_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'app_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          FeedScreen(),
          LeaderboardScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentShellIndex: _tab,
        onShellTabSelected: (i) => setState(() => _tab = i),
        onRunPressed: () => context.push('/run'),
      ),
    );
  }
}
