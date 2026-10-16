import 'package:flutter/material.dart';

/// ألوان اللعبة: أجواء قاتمة مع إضاءة حمراء لنقاط الضعف.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0E0F13);
  static const Color surface = Color(0xFF1A1C23);
  static const Color surfaceLight = Color(0xFF262932);

  static const Color primary = Color(0xFFC9A24B); // ذهبي باهت
  static const Color danger = Color(0xFFE53935); // نقطة الضعف والخطر
  static const Color success = Color(0xFF5FA55A);

  static const Color textPrimary = Color(0xFFEDE7D9);
  static const Color textSecondary = Color(0xFF9A978F);

  // ألوان عناصر اللعب.
  static const Color ground = Color(0xFF2B2A26);
  static const Color wall = Color(0xFF6B675E);
  static const Color wallDark = Color(0xFF45423B);
  static const Color giantSkin = Color(0xFFB98E75);
  static const Color weakSpot = Color(0xFFFF3B30);
  static const Color bullet = Color(0xFFFFE08A);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final ColorScheme scheme = const ColorScheme.dark().copyWith(
      primary: AppColors.primary,
      secondary: AppColors.danger,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      useMaterial3: true,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 54),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
