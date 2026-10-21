import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import 'app_button.dart';

/// Shows the Dialog component (Figma page 05 "Dialog / 3 specimens":
/// Confirm, Cancel, Error).
///
/// Radius 16, `elevation/2`, short title, 16 sp body, one secondary action on
/// the left and one primary action on the right, each ≥ 48 dp.
///
/// Returns `true` for the primary action, `false` for the secondary action,
/// and `null` when the dialog is dismissed.
Future<bool?> showAppDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String primaryLabel,
  String secondaryLabel = 'Cancel',
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AppDialog(
      title: title,
      message: message,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      onPrimary: () => Navigator.of(context).pop(true),
      onSecondary: () => Navigator.of(context).pop(false),
    ),
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      // The surface and the exact elevation/2 shadow are drawn below instead
      // of Material's elevation shadow.
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s24,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.largeAll,
          boxShadow: AppElevation.level2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: textTheme.titleMedium),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(message, style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.s24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: secondaryLabel,
                      onPressed: onSecondary,
                      variant: AppButtonVariant.secondary,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: AppButton(
                      label: primaryLabel,
                      onPressed: onPrimary,
                      expand: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
