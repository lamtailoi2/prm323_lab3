import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens from Lab 2 `DESIGN.md` §5 (Inter; Roboto fallback).
///
/// Line height is expressed as `height = lineHeight / fontSize`.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';
  static const List<String> fontFamilyFallback = <String>['Roboto'];

  /// `type/display` — 28/36, 700. Hero titles, used sparingly.
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    color: AppColors.textPrimary,
  );

  /// `type/heading/large` — 24/32, 700. Screen title, job detail title.
  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    color: AppColors.textPrimary,
  );

  /// `type/heading/medium` — 20/28, 600. Section headings.
  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.textPrimary,
  );

  /// `type/title` — 18/24, 600. Card titles, dialog titles, app bar titles.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: AppColors.textPrimary,
  );

  /// `type/body/medium` — 16/24, 400. Main text, form input text.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  /// `type/body/small` — 14/20, 400. Metadata, helper text.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.textSecondary,
  );

  /// `type/label/medium` — 14/20, 600. Buttons, chips, form labels, status.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  /// `type/caption` — 12/16, 500. Dates, compact badges, minor metadata.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  /// Maps the design tokens onto the Material 3 [TextTheme] slots.
  ///
  /// `type/body/medium → bodyLarge` comes from the Lab 2 handoff table; the
  /// other slots follow the closest Material size. Screens should read styles
  /// from `Theme.of(context).textTheme`.
  static const TextTheme textTheme = TextTheme(
    headlineMedium: display,
    headlineSmall: headingLarge,
    titleLarge: headingMedium,
    titleMedium: title,
    titleSmall: label,
    bodyLarge: body,
    bodyMedium: bodySmall,
    bodySmall: caption,
    labelLarge: label,
    labelMedium: caption,
    labelSmall: caption,
  );
}
