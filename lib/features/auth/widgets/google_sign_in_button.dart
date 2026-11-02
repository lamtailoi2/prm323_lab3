import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// The white "Continue with Google" button of the Login frame (DC-18).
///
/// Not an `AppButton` variant: Google's branding guidelines require a white
/// button with Google's own "G" asset, which the three Lab 2 variants do
/// not cover. Size, radius and label style still come from the theme's
/// filled button. While [isLoading] is true a spinner replaces the "G" and
/// taps are ignored, like `AppButton`.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  static const String label = 'Continue with Google';

  /// Google's "G" from the Sign in with Google assets (G-03).
  static const String logoAsset = 'assets/images/google_logo.png';

  final VoidCallback onPressed;
  final bool isLoading;

  static final ButtonStyle _style = ButtonStyle(
    // Stays white while loading (the button is then disabled) so it keeps
    // the frame's look; pressed uses the lightest surface for feedback.
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? AppColors.surfaceVariant
          : AppColors.surface,
    ),
    foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
  );

  @override
  Widget build(BuildContext context) {
    final leading = isLoading
        ? const SizedBox.square(
            dimension: AppSizes.iconSmall,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textPrimary,
            ),
          )
        : Image.asset(
            logoAsset,
            width: AppSizes.iconSmall,
            height: AppSizes.iconSmall,
            excludeFromSemantics: true,
          );

    return Semantics(
      container: true,
      button: true,
      enabled: !isLoading,
      label: isLoading ? '$label, loading' : null,
      excludeSemantics: isLoading,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: _style,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: AppSpacing.s12),
              const Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
