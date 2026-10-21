import 'package:flutter/material.dart';

/// Color tokens from Lab 2 `DESIGN.md` §4 (Figma collection
/// "Internship Finder — DESIGN.md", Light mode).
///
/// Only the 13 documented semantic tokens are defined here. The four Figma
/// helper colors (pressed, error container, disabled container, inverse
/// surface) have no documented values yet; see `docs/handoff-gaps.md` (G-07).
/// Do not add one-off colors in screens.
abstract final class AppColors {
  /// `color/primary` — primary CTA, selected navigation, focused inputs.
  static const Color primary = Color(0xFF2563EB);

  /// `color/on-primary` — text and icons on primary backgrounds.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// `color/primary-container` — selected chips, low-emphasis highlights.
  static const Color primaryContainer = Color(0xFFDBEAFE);

  /// `color/background` — main app background.
  static const Color background = Color(0xFFF8FAFC);

  /// `color/surface` — cards, app bars, dialogs, fields, bottom navigation.
  static const Color surface = Color(0xFFFFFFFF);

  /// `color/surface-variant` — chip backgrounds, skeleton blocks.
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  /// `color/text/primary` — headings, job titles, company names.
  static const Color textPrimary = Color(0xFF0F172A);

  /// `color/text/secondary` — metadata, helper text.
  static const Color textSecondary = Color(0xFF475569);

  /// `color/border` — dividers, input borders, card outlines.
  static const Color border = Color(0xFFCBD5E1);

  /// `color/success` — accepted status, success confirmation.
  static const Color success = Color(0xFF15803D);

  /// `color/warning` — under-review status, caution messages.
  static const Color warning = Color(0xFFB45309);

  /// `color/error` — errors, failed state, destructive actions.
  static const Color error = Color(0xFFDC2626);

  /// `color/disabled` — disabled text, icons and controls.
  static const Color disabled = Color(0xFF94A3B8);
}
