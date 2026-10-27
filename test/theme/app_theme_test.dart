import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/theme/app_colors.dart';
import 'package:internly/theme/app_elevation.dart';
import 'package:internly/theme/app_theme.dart';

void main() {
  final theme = AppTheme.light();

  group('Color tokens (DESIGN.md §4 / Figma page 04)', () {
    test('ColorScheme maps the semantic tokens', () {
      final scheme = theme.colorScheme;
      expect(scheme.primary, const Color(0xFF2563EB));
      expect(scheme.onPrimary, const Color(0xFFFFFFFF));
      expect(scheme.primaryContainer, const Color(0xFFDBEAFE));
      expect(scheme.surface, const Color(0xFFFFFFFF));
      expect(scheme.surfaceContainerHighest, const Color(0xFFF1F5F9));
      expect(scheme.onSurface, const Color(0xFF0F172A));
      expect(scheme.onSurfaceVariant, const Color(0xFF475569));
      expect(scheme.outline, const Color(0xFFCBD5E1));
      expect(scheme.error, const Color(0xFFDC2626));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
    });

    test('status colors are exposed through the theme extension', () {
      final status = theme.extension<AppStatusColors>()!;
      expect(status.success, const Color(0xFF15803D));
      expect(status.warning, const Color(0xFFB45309));
      expect(status.disabled, const Color(0xFF94A3B8));
    });
  });

  group('Typography tokens (DESIGN.md §5)', () {
    final text = theme.textTheme;

    void expectStyle(
      TextStyle? style,
      double size,
      FontWeight weight,
      double lineHeight,
    ) {
      expect(style?.fontSize, size);
      expect(style?.fontWeight, weight);
      expect(style!.height! * style.fontSize!, closeTo(lineHeight, 0.001));
      expect(style.fontFamily, 'Inter');
    }

    test('maps the eight Figma text styles', () {
      expectStyle(text.headlineMedium, 28, FontWeight.w700, 36); // display
      expectStyle(text.headlineSmall, 24, FontWeight.w700, 32); // heading/large
      expectStyle(text.titleLarge, 20, FontWeight.w600, 28); // heading/medium
      expectStyle(text.titleMedium, 18, FontWeight.w600, 24); // title
      expectStyle(text.bodyLarge, 16, FontWeight.w400, 24); // body/medium
      expectStyle(text.bodyMedium, 14, FontWeight.w400, 20); // body/small
      expectStyle(text.labelLarge, 14, FontWeight.w600, 20); // label/medium
      expectStyle(text.bodySmall, 12, FontWeight.w500, 16); // caption
    });

    test('body text is never smaller than 14 sp', () {
      expect(text.bodyLarge!.fontSize, greaterThanOrEqualTo(14));
      expect(text.bodyMedium!.fontSize, greaterThanOrEqualTo(14));
    });
  });

  group('Component defaults (Figma page 05)', () {
    test('buttons have a 48 dp minimum height and radius 12', () {
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
        theme.textButtonTheme.style!,
      ]) {
        expect(style.minimumSize!.resolve({})!.height, 48);
        final shape = style.shape!.resolve({})! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(12));
      }
    });

    test('disabled buttons use surfaceVariant fill and disabled label', () {
      const disabled = {WidgetState.disabled};
      final filled = theme.filledButtonTheme.style!;
      expect(
        filled.backgroundColor!.resolve(disabled),
        AppColors.surfaceVariant,
      );
      expect(filled.foregroundColor!.resolve(disabled), AppColors.disabled);
    });

    test('secondary button has a primary border', () {
      final side = theme.outlinedButtonTheme.style!.side!.resolve({})!;
      expect(side.color, AppColors.primary);
    });

    test('text button has no background block', () {
      final background = theme.textButtonTheme.style!.backgroundColor!;
      expect(background.resolve({}), Colors.transparent);
      expect(background.resolve({WidgetState.disabled}), Colors.transparent);
    });

    test('pressed primary uses reduced emphasis, not a new color', () {
      final bg = theme.filledButtonTheme.style!.backgroundColor!.resolve({
        WidgetState.pressed,
      })!;
      expect(
        bg.toARGB32() & 0x00FFFFFF,
        AppColors.primary.toARGB32() & 0x00FFFFFF,
      );
      expect(bg.a, lessThan(1));
    });

    test('cards are flat white with a border and radius 16', () {
      final card = theme.cardTheme;
      expect(card.elevation, 0);
      expect(card.color, AppColors.surface);
      final shape = card.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
      expect(shape.side.color, AppColors.border);
    });

    test('bottom navigation: selected primary, unselected textSecondary', () {
      final icons = theme.navigationBarTheme.iconTheme!;
      expect(icons.resolve({WidgetState.selected})!.color, AppColors.primary);
      expect(icons.resolve({})!.color, AppColors.textSecondary);
      expect(theme.navigationBarTheme.indicatorColor, Colors.transparent);
    });
  });

  test('elevation tokens match DESIGN.md §8', () {
    expect(AppElevation.level0, isEmpty);
    expect(AppElevation.level1.single.offset, const Offset(0, 1));
    expect(AppElevation.level1.single.blurRadius, 3);
    expect(AppElevation.level1.single.color.a, closeTo(0.08, 0.005));
    expect(AppElevation.level2.single.offset, const Offset(0, 8));
    expect(AppElevation.level2.single.blurRadius, 24);
    expect(AppElevation.level2.single.color.a, closeTo(0.12, 0.005));
  });
}
