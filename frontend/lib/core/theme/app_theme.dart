import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.cyan,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      surface: AppColors.surface,
      onSurface: AppColors.navy,
      error: AppColors.danger,
    );
    final radio8 = BorderRadius.circular(8);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppColors.navy,
            displayColor: AppColors.navy,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: radio8),
        enabledBorder: OutlineInputBorder(
          borderRadius: radio8,
          borderSide: const BorderSide(color: Color(0x330C203F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radio8,
          borderSide: const BorderSide(color: AppColors.cyan, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: radio8),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.cyan),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.surfaceLow,
      ),
    );
  }
}
