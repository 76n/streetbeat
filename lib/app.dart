import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'shared/repositories/auth_repository.dart';
import 'core/routing/go_router_refresh.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/feed/screens/feed_screen.dart';
import 'features/leaderboard/screens/leaderboard_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/run/screens/run_screen.dart';
import 'features/run/screens/run_summary_screen.dart';

class StreetbeatApp extends StatelessWidget {
  const StreetbeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(sl<AuthRepository>())..add(const AuthStarted()),
      child: const _StreetbeatRoot(),
    );
  }
}

class _StreetbeatRoot extends StatefulWidget {
  const _StreetbeatRoot();

  @override
  State<_StreetbeatRoot> createState() => _StreetbeatRootState();
}

class _StreetbeatRootState extends State<_StreetbeatRoot> {
  late final GoRouterRefreshStream _authRefresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRefresh = GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    );
    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _authRefresh,
      redirect: _authRedirect,
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/signup',
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SignupScreen(),
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const FeedScreen(),
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
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
  }

  @override
  void dispose() {
    _authRefresh.dispose();
    super.dispose();
  }

  static String? _authRedirect(BuildContext context, GoRouterState state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;
    final atAuth = loc == '/login' || loc == '/signup';
    if (!loggedIn && !atAuth) {
      return '/login';
    }
    if (loggedIn && atAuth) {
      return '/home';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
