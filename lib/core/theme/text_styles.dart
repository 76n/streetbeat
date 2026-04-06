import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class AppTextStyles {
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static TextStyle wordmark(double size) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  static TextStyle tagline(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ) ??
      const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  static TextStyle statNumber(double fontSize, {Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.3,
        color: color ?? AppColors.textPrimary,
        fontFeatures: tabularFigures,
      );

  static TextStyle statLabel(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ) ??
      const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );

  static TextStyle hudPrimary(double size) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.05,
        color: AppColors.textPrimary,
        fontFeatures: tabularFigures,
      );

  static TextStyle hudSecondary(double size) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        fontFeatures: tabularFigures,
      );

  static String get _fontFamily {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => '.SF Pro Text',
      _ => 'Roboto',
    };
  }
}
