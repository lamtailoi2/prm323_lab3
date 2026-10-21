import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// Button variants from Lab 2 `DESIGN.md` §10 and Figma page 05
/// "Button / 12 specimens".
enum AppButtonVariant {
  /// Main action (`FilledButton`). One per screen.
  primary,

  /// Supporting action (`OutlinedButton`, primary border).
  secondary,

  /// Low-emphasis action (`TextButton`).
  text,
}

/// The single button component used across Internly.
///
/// States: default, pressed (reduced emphasis, from the theme), disabled
/// (`onPressed == null`) and loading. While [isLoading] is true the button
/// keeps its default colors, shows a spinner next to the label and ignores
/// taps, preventing duplicate submissions.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;

  /// `null` renders the disabled state.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Full width, for the dominant action of a screen.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final themeStyle = _themeStyle(Theme.of(context));
    final enabledLook = isLoading || onPressed != null;
    final contentColor = themeStyle?.foregroundColor?.resolve(
      enabledLook ? const <WidgetState>{} : const {WidgetState.disabled},
    );
    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      spinnerColor: contentColor,
    );
    final callback = isLoading ? null : onPressed;
    final style = isLoading ? _loadingStyle(themeStyle) : null;

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: callback,
        style: style,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        style: style,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: callback,
        style: style,
        child: child,
      ),
    };

    return Semantics(
      container: true,
      button: true,
      enabled: callback != null,
      label: isLoading ? '$label, loading' : null,
      excludeSemantics: isLoading,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }

  ButtonStyle? _themeStyle(ThemeData theme) => switch (variant) {
    AppButtonVariant.primary => theme.filledButtonTheme.style,
    AppButtonVariant.secondary => theme.outlinedButtonTheme.style,
    AppButtonVariant.text => theme.textButtonTheme.style,
  };

  /// Freezes the enabled colors so the disabled-while-loading button still
  /// looks like the Figma "Loading" specimen instead of the disabled one.
  static ButtonStyle? _loadingStyle(ButtonStyle? themeStyle) {
    if (themeStyle == null) return null;
    const enabled = <WidgetState>{};
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        themeStyle.backgroundColor?.resolve(enabled),
      ),
      foregroundColor: WidgetStatePropertyAll(
        themeStyle.foregroundColor?.resolve(enabled),
      ),
      side: WidgetStatePropertyAll(themeStyle.side?.resolve(enabled)),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.spinnerColor,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color? spinnerColor;

  @override
  Widget build(BuildContext context) {
    final Widget? leading = isLoading
        ? SizedBox.square(
            dimension: AppSizes.iconSmall,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : icon == null
        ? null
        : Icon(icon, size: AppSizes.iconSmall);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: AppSpacing.s8)],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
