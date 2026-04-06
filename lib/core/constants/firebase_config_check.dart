import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';

bool isLikelyFirebasePlaceholder(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) {
    return true;
  }
  final lower = s.toLowerCase();
  return lower.contains('your_') ||
      lower.contains('placeholder') ||
      lower.contains('example') ||
      lower.contains('changeme') ||
      lower.contains('replace') ||
      lower.contains('todo');
}

bool areFirebaseOptionsConfigured(FirebaseOptions options) {
  final projectId = options.projectId.trim();
  final apiKey = options.apiKey.trim();
  final appId = options.appId.trim();
  if (projectId.isEmpty || apiKey.isEmpty || appId.isEmpty) {
    return false;
  }
  if (isLikelyFirebasePlaceholder(projectId) ||
      isLikelyFirebasePlaceholder(apiKey) ||
      isLikelyFirebasePlaceholder(appId)) {
    return false;
  }
  return true;
}

class FirebaseConfigSetupScreen extends StatelessWidget {
  const FirebaseConfigSetupScreen({
    super.key,
    this.details,
    this.onRetry,
  });

  final String? details;
  final Future<void> Function()? onRetry;

  static const _steps = <_Step>[
    _Step(
      title: 'Create a Firebase project',
      body:
          'Open console.firebase.google.com and create a project (e.g. streetbeat).',
    ),
    _Step(
      title: 'Add the Android app',
      body:
          'Package name: com.streetbeat.app. Download google-services.json and place it at android/app/google-services.json.',
    ),
    _Step(
      title: 'Enable Auth & Firestore',
      body:
          'Authentication: Email/Password and Google. Firestore: create database (production mode, pick a region).',
    ),
    _Step(
      title: 'Deploy backend (optional)',
      body:
          'From the repo root: firebase deploy --only firestore:rules and deploy Cloud Functions per SETUP.md.',
    ),
    _Step(
      title: 'Rebuild the app',
      body:
          'Stop the app, run flutter clean if needed, then full restart — not just hot reload.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary, height: 1.45),
          bodyMedium: TextStyle(color: AppColors.textSecondary, height: 1.45),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.card.withValues(alpha: 0.95),
                              AppColors.surface,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.rocket_launch_outlined,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Almost there',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'StreetBeat needs a real Firebase config. '
                                    'Follow the steps below — the app stays '
                                    'runnable so you can finish setup anytime.',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Setup checklist',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final step = _steps[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StepCard(index: index + 1, step: step),
                      );
                    },
                    childCount: _steps.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (details != null && details!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: SelectableText(
                            details!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (onRetry != null)
                        ElevatedButton(
                          onPressed: () => onRetry!(),
                          child: const Text('Check again'),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Full guide: see SETUP.md in the project root.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step {
  const _Step({required this.title, required this.body});

  final String title;
  final String body;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.step});

  final int index;
  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.card.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
