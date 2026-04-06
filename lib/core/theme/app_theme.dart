import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
    );

    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      secondary: AppColors.ghostBlue,
      onSecondary: AppColors.background,
      error: AppColors.primary,
      onError: AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.textSecondary, width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.card, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      textTheme: _textTheme(base.textTheme),
    );
  }

  static String get _fontFamily {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => '.SF Pro Text',
      _ => 'Roboto',
    };
  }

  static TextTheme _textTheme(TextTheme base) {
    TextStyle body(Color color, FontWeight weight, double size, double height) {
      return TextStyle(
        fontFamily: _fontFamily,
        inherit: true,
        color: color,
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: 0.1,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    return base.copyWith(
      displayLarge: body(AppColors.textPrimary, FontWeight.w700, 32, 1.15),
      displayMedium: body(AppColors.textPrimary, FontWeight.w700, 28, 1.2),
      displaySmall: body(AppColors.textPrimary, FontWeight.w600, 24, 1.2),
      headlineLarge: body(AppColors.textPrimary, FontWeight.w600, 22, 1.25),
      headlineMedium: body(AppColors.textPrimary, FontWeight.w600, 20, 1.25),
      headlineSmall: body(AppColors.textPrimary, FontWeight.w600, 18, 1.3),
      titleLarge: body(AppColors.textPrimary, FontWeight.w600, 17, 1.3),
      titleMedium: body(AppColors.textPrimary, FontWeight.w600, 15, 1.35),
      titleSmall: body(AppColors.textSecondary, FontWeight.w600, 13, 1.35),
      bodyLarge: body(AppColors.textPrimary, FontWeight.w400, 16, 1.45),
      bodyMedium: body(AppColors.textPrimary, FontWeight.w400, 14, 1.45),
      bodySmall: body(AppColors.textSecondary, FontWeight.w400, 12, 1.4),
      labelLarge: body(AppColors.textPrimary, FontWeight.w600, 14, 1.2),
      labelMedium: body(AppColors.textSecondary, FontWeight.w500, 12, 1.2),
      labelSmall: body(AppColors.textSecondary, FontWeight.w500, 11, 1.2),
    );
  }
}
