import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: AppTypography.fontFamily,
  textTheme: AppTypography.textTheme,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primary600,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.warning,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.surface3,
    onSecondaryContainer: AppColors.text1,
    tertiary: AppColors.success,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.surface3,
    onTertiaryContainer: AppColors.text1,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.surface3,
    onErrorContainer: AppColors.text1,
    surface: AppColors.surface1,
    onSurface: AppColors.text1,
    onSurfaceVariant: AppColors.text2,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.text1,
    onInverseSurface: Colors.white,
    inversePrimary: AppColors.primary600,
    surfaceTint: Colors.transparent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bg,
    foregroundColor: AppColors.text1,
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: AppColors.text1),
    titleTextStyle: TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 22,
      fontWeight: AppTypography.bold,
      color: AppColors.text1,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface1,
    elevation: 1,
    shadowColor: Colors.black.withOpacity(0.06),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    margin: const EdgeInsets.all(0),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface1,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    hintStyle: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.text3),
    labelStyle: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.primary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
    ),
  ),
  iconTheme: const IconThemeData(
    color: AppColors.primary,
    size: 20,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return const Color(0xFFD5D5D5);
        return AppColors.primary;
      }),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: AppTypography.semiBold,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      overlayColor: const WidgetStatePropertyAll(AppColors.focus),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 15,
          fontWeight: AppTypography.semiBold,
        ),
      ),
      overlayColor: const WidgetStatePropertyAll(AppColors.focus),
    ),
  ),
);
