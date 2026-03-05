import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: AppTypography.fontFamily,
  textTheme: AppTypography.textTheme,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primary600,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.info,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.surface3,
    onSecondaryContainer: AppColors.text1,
    tertiary: AppColors.warning,
    onTertiary: Colors.black,
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
    onInverseSurface: AppColors.bg,
    inversePrimary: AppColors.primary600,
    surfaceTint: Colors.transparent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface1,
    foregroundColor: AppColors.text1,
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: AppColors.text1),
    titleTextStyle: TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: AppTypography.semiBold,
      color: AppColors.text1,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface1,
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
      side: const BorderSide(color: AppColors.border),
    ),
    margin: const EdgeInsets.all(0),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surface1,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
      side: const BorderSide(color: AppColors.border),
    ),
    titleTextStyle: AppTypography.textTheme.headlineMedium,
    contentTextStyle: AppTypography.textTheme.bodyLarge,
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: AppColors.surface1,
    surfaceTintColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppColors.radius),
      ),
      side: BorderSide(color: AppColors.border),
    ),
    modalBarrierColor: Colors.black54,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.text3),
    labelStyle: AppTypography.textTheme.bodyMedium,
    helperStyle: AppTypography.textTheme.bodySmall,
    errorStyle: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.danger),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      gapPadding: 4,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
    ),
  ),
  iconTheme: const IconThemeData(
    color: AppColors.text2,
    size: 22,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.surface3,
    contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.text1),
    actionTextColor: AppColors.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
    ),
    behavior: SnackBarBehavior.floating,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return 0;
        return 1;
      }),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.surface3;
        if (states.contains(WidgetState.pressed)) return AppColors.primary600;
        return AppColors.primary;
      }),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          height: 18 / 14,
          fontWeight: AppTypography.semiBold,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
        ),
      ),
      overlayColor: const WidgetStatePropertyAll(AppColors.focus),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
      foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
      side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          height: 18 / 14,
          fontWeight: AppTypography.semiBold,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
        ),
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
          fontSize: 14,
          height: 18 / 14,
          fontWeight: AppTypography.semiBold,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
        ),
      ),
      overlayColor: const WidgetStatePropertyAll(AppColors.focus),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surface2,
    selectedColor: AppColors.primary.withOpacity(0.2),
    disabledColor: AppColors.surface3,
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
    ),
    labelStyle: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.text1),
    secondaryLabelStyle: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.primary),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    brightness: Brightness.dark,
  ),
  splashColor: AppColors.focus,
  highlightColor: Colors.transparent,
  focusColor: AppColors.focus,
  hoverColor: AppColors.focus,
);
