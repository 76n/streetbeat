import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/feed/screens/feed_screen.dart';
import 'features/leaderboard/screens/leaderboard_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/run/screens/run_screen.dart';
import 'features/run/screens/run_summary_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const FeedScreen(),
    ),
    GoRoute(
      path: '/run',
      builder: (context, state) => const RunScreen(),
    ),
    GoRoute(
      path: '/run-summary',
      builder: (context, state) => const RunSummaryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
  ],
);

class StreetbeatApp extends StatelessWidget {
  const StreetbeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
