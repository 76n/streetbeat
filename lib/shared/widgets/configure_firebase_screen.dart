import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class ConfigureFirebaseScreen extends StatelessWidget {
  const ConfigureFirebaseScreen({super.key, this.details});

  final String? details;

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
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Configure Firebase',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Firebase did not initialize. Replace the placeholder '
                  'android/app/google-services.json with the file from your '
                  'Firebase console (Project settings → Your apps → Android).',
                ),
                const SizedBox(height: 16),
                const Text(
                  'For iOS, add GoogleService-Info.plist under ios/Runner. '
                  'For web, run flutterfire configure or add Firebase options '
                  'and pass them to Firebase.initializeApp().',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Then run flutter pub get and restart the app.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                if (details != null && details!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    details!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
