import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'SuisseIntl';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 34,
      height: 40 / 34,
      fontWeight: bold,
      color: AppColors.text1,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      height: 34 / 28,
      fontWeight: bold,
      color: AppColors.text1,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      height: 30 / 24,
      fontWeight: semiBold,
      color: AppColors.text1,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 21,
      height: 28 / 21,
      fontWeight: semiBold,
      color: AppColors.text1,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: regular,
      color: AppColors.text1,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 22 / 16,
      fontWeight: regular,
      color: AppColors.text2,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: regular,
      color: AppColors.text2,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: semiBold,
      color: AppColors.text1,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      height: 20 / 15,
      fontWeight: medium,
      color: AppColors.text2,
    ),
  );
}
