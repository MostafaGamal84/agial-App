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
      fontSize: 32,
      height: 38 / 32,
      fontWeight: bold,
      color: AppColors.text1,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 26,
      height: 32 / 26,
      fontWeight: bold,
      color: AppColors.text1,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      height: 28 / 22,
      fontWeight: semiBold,
      color: AppColors.text1,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 19,
      height: 26 / 19,
      fontWeight: semiBold,
      color: AppColors.text1,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 22 / 16,
      fontWeight: regular,
      color: AppColors.text1,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      height: 21 / 15,
      fontWeight: regular,
      color: AppColors.text2,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      height: 18 / 13,
      fontWeight: regular,
      color: AppColors.text2,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 22 / 16,
      fontWeight: semiBold,
      color: AppColors.text1,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      height: 19 / 14,
      fontWeight: medium,
      color: AppColors.text2,
    ),
  );
}
