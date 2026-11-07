import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// White bordered section with the Figma Section Header on top.
///
/// Shared by Internship Detail, the Apply Form, Application Review, Application
/// Success and Application Detail (design-system.md › components).
class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.spacing = AppSpacing.s12,
    this.isRequired = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  /// Adds the red ` *` of the Apply Form, read as "required".
  final bool isRequired;

  /// Optional action at the end of the header row, e.g. `Edit` on Application
  /// Review or `Add skill` on the Apply Form.
  final Widget? action;

  /// Gap between the header and each child (Figma: 8 for "About the role",
  /// 12 for the other sections).
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.largeAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppSizes.iconSmall,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: title,
                      children: [
                        if (isRequired)
                          const TextSpan(
                            text: ' *',
                            semanticsLabel: ', required',
                            style: TextStyle(color: AppColors.error),
                          ),
                      ],
                    ),
                    style: textTheme.titleMedium,
                  ),
                ),
                ?action,
              ],
            ),
          ),
          for (final child in children) ...[SizedBox(height: spacing), child],
        ],
      ),
    );
  }
}
