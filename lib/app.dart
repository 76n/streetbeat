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
import 'shared/widgets/main_shell.dart';
import 'features/run/screens/run_screen.dart';
import 'features/run/models/run_summary_payload.dart';
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
            child: const MainShell(),
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
          pageBuilder: (context, state) {
            final extra = state.extra;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: RunSummaryScreen(
                payload: extra is RunSummaryPayload ? extra : null,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curved),
                  child: FadeTransition(
                    opacity: curved,
                    child: child,
                  ),
                );
              },
            );
          },
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
