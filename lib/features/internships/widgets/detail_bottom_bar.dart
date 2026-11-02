import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// Figma "Bottom action bar" of Internship Detail: Save Toggle + `Apply now`,
/// or `View application` once the student applied ("Internship Detail –
/// Applied").
class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.isSaved,
    required this.onToggleSave,
    required this.onPrimary,
    this.isApplied = false,
  });

  final bool isSaved;
  final bool isApplied;
  final VoidCallback onToggleSave;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              _SaveToggle(isSaved: isSaved, onPressed: onToggleSave),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: AppButton(
                  label: isApplied ? 'View application' : 'Apply now',
                  onPressed: onPrimary,
                  expand: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma "Save Toggle" (`State=Default` / `State=Saved`). The label changes
/// with the state, so it is not shown by the icon fill alone.
class _SaveToggle extends StatelessWidget {
  const _SaveToggle({required this.isSaved, required this.onPressed});

  final bool isSaved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isSaved ? 'Saved. Remove from saved' : 'Save internship',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadii.mediumAll,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.mediumAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.bookmark_rounded,
                    fill: isSaved ? 1 : 0,
                    size: AppSizes.icon,
                    color: isSaved
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    isSaved ? 'Saved' : 'Save',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
