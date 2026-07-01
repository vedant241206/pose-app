import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color accent = Color(0xFFFFD700);
  static const Color accentLight = Color(0xFFFFF3B0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteHigh = Color(0xB3FFFFFF); // 70%
  static const Color whiteMed = Color(0x80FFFFFF);  // 50%
  static const Color whiteLow = Color(0x4DFFFFFF);  // 30%
  static const Color gridLine = Color(0x4DFFFFFF);  // 30%
  static const Color pillBorder = Color(0x80FFFFFF); // 50%
  static const Color pillSelected = Color(0xFFFFD700);
  static const Color error = Color(0xFFFF4444);
  static const Color transparent = Colors.transparent;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.accent,
        secondary: AppColors.accent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.whiteHigh,
        size: 24,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.white, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.whiteHigh, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.whiteMed, fontSize: 12),
        labelLarge: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: AppColors.whiteHigh, fontSize: 12, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      useMaterial3: true,
    );
  }
}
