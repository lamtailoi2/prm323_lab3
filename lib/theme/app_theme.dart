import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the Internly [ThemeData] from the Lab 2 design tokens.
///
/// Token → Flutter mapping follows the Lab 2 README handoff table. Values
/// that the handoff does not document are left at Material defaults and are
/// listed in `docs/records/handoff-gaps.md` instead of being invented here.
abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primary,
      // The design has a single brand color. Material uses the secondary
      // container for selected filter chips and navigation indicators, which
      // DESIGN.md renders as primary-container + primary text.
      secondary: AppColors.primary,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.primaryContainer,
      onSecondaryContainer: AppColors.primary,
      error: AppColors.error,
      onError: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      surfaceTint: Colors.transparent,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      shadow: AppColors.textPrimary,
    );

    OutlineInputBorder inputBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: AppRadii.mediumAll,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: AppColors.background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: const <ThemeExtension<dynamic>>[AppStatusColors.light],
      appBarTheme: const AppBarThemeData(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: AppSizes.appBarHeight,
        // Figma "Back" variant (title 18/600). The "Main" variant of
        // top-level screens is applied by AppTopBar.main.
        titleTextStyle: AppTypography.title,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          background: AppColors.primary,
          foreground: AppColors.onPrimary,
          pressedReducesBackground: true,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          background: AppColors.surface,
          foreground: AppColors.primary,
          border: AppColors.primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyle(
          background: AppColors.surface,
          foreground: AppColors.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.minTouchTarget),
          iconSize: AppSizes.icon,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.surfaceVariant
              : AppColors.surface,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        labelStyle: AppTypography.label,
        floatingLabelStyle: AppTypography.label,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
        helperStyle: AppTypography.bodySmall,
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        helperMaxLines: 3,
        errorMaxLines: 3,
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        disabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary, width: 2),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, width: 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.surfaceVariant,
        checkmarkColor: AppColors.primary,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mediumAll),
        labelStyle: AppTypography.label.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.largeAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.largeAll),
        titleTextStyle: AppTypography.title,
        contentTextStyle: AppTypography.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.large),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSizes.bottomNavHeight,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSizes.icon,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceVariant,
      ),
    );
  }

  /// Opacity applied to the emphasised part of a button while pressed.
  ///
  /// Figma page 05: "Pressed uses reduced emphasis, not a new color". The
  /// exact opacity is not documented; 0.7 is estimated from the specimen and
  /// must be verified in Figma (docs/records/handoff-gaps.md G-07).
  static const double pressedOpacity = 0.7;

  /// Shared recipe for the Primary / Secondary / Text button variants
  /// (Figma page 05 "Button / 12 specimens").
  static ButtonStyle _buttonStyle({
    required Color background,
    required Color foreground,
    Color? border,
    bool pressedReducesBackground = false,
  }) {
    Color resolveForeground(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) return AppColors.disabled;
      if (states.contains(WidgetState.pressed) && !pressedReducesBackground) {
        return foreground.withValues(alpha: pressedOpacity);
      }
      return foreground;
    }

    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(AppSizes.minTouchTarget, AppSizes.buttonHeight),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadii.mediumAll),
      ),
      textStyle: const WidgetStatePropertyAll(AppTypography.label),
      elevation: const WidgetStatePropertyAll(0),
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.surfaceVariant;
        }
        if (states.contains(WidgetState.pressed) && pressedReducesBackground) {
          return background.withValues(alpha: pressedOpacity);
        }
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(resolveForeground),
      iconColor: WidgetStateProperty.resolveWith(resolveForeground),
      side: border == null
          ? null
          : WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return const BorderSide(color: AppColors.border);
              }
              if (states.contains(WidgetState.pressed)) {
                return BorderSide(
                  color: border.withValues(alpha: pressedOpacity),
                );
              }
              return BorderSide(color: border);
            }),
    );
  }
}

/// Status colors that have no [ColorScheme] slot.
///
/// The Lab 2 handoff maps `color/success` and `color/warning` to a
/// `ThemeExtension`. Read it with `Theme.of(context).extension<AppStatusColors>()!`.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.disabled,
  });

  static const AppStatusColors light = AppStatusColors(
    success: AppColors.success,
    warning: AppColors.warning,
    disabled: AppColors.disabled,
  );

  final Color success;
  final Color warning;
  final Color disabled;

  @override
  AppStatusColors copyWith({Color? success, Color? warning, Color? disabled}) {
    return AppStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}
