import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// Non-interactive status badge (Figma page 05 "Application Status").
///
/// 14 sp label + meaningful 20 dp icon on `surfaceVariant`; never color
/// alone. Features map their own statuses to [label], [icon] and [color]
/// (e.g. Under review → hourglass_top + `AppColors.warning`).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.icon,
    this.color = AppColors.textSecondary,
  });

  final String label;
  final IconData icon;

  /// Foreground for icon and label. Use a semantic token only.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadii.smallAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconSmall, color: color),
              const SizedBox(width: AppSpacing.s4),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
