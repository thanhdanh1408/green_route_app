import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF12A454); // green main
  static const Color primaryVariant = Color(0xFF0E8A3B);
  static const Color accent = Color(0xFF8EE39E);
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Colors.white;
  static const Color danger = Color(0xFFDF3E30);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
}

class AppPadding {
  AppPadding._();
  static const double small = 8.0;
  static const double normal = 16.0;
  static const double large = 24.0;
}

class AppTextStyle {
  AppTextStyle._();

  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleTextStyle: AppTextStyle.headline2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) => AppColors.primary,
          ),
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) => Colors.white,
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyle.headline1,
        headlineMedium: AppTextStyle.headline2,
        bodyLarge: AppTextStyle.body,
        labelLarge: AppTextStyle.button,
      ),
    );
  }

  static ButtonStyle roundedButtonStyle({
    Color? backgroundColor,
    double radius = 12.0,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary,
      padding:
          padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
