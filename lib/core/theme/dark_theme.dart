import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_button_theme.dart';
import 'app_input_theme.dart';
import 'app_text_styles.dart';

abstract final class DarkTheme {
  static ThemeData build() {
    final colors =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF7AA2FF),
          onPrimary: AppColors.darkBackground,
          secondary: const Color(0xFF5EEAD4),
          tertiary: const Color(0xFFFBBF24),
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: AppTextStyles.textTheme(AppColors.darkText),
      inputDecorationTheme: AppInputTheme.build(colors),
      filledButtonTheme: AppButtonTheme.filled(colors),
      elevatedButtonTheme: AppButtonTheme.elevated(colors),
      outlinedButtonTheme: AppButtonTheme.outlined(colors),
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        indicatorColor: colors.primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
