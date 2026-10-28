import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// Tag sizes. [compact] is the Internship Card specimen; [large] is the
/// Profile skill and preference tag (44 dp tall, design owner 2026-10-28).
enum AppTagSize { compact, large }

/// Compact, non-interactive tag for skills (Lab 2 component "Skill Tag";
/// tag style taken from the Internship Card specimen on Figma page 05).
///
/// Use `FilterChip` instead when the tag can be selected.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.size = AppTagSize.compact,
  });

  final String label;
  final AppTagSize size;

  @override
  Widget build(BuildContext context) {
    final large = size == AppTagSize.large;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadii.smallAll,
      ),
      child: SizedBox(
        height: large ? AppSizes.tagLarge : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            // The large tag has a fixed height; the label is centred in it.
            vertical: large ? 0 : AppSpacing.s4,
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ),
    );
  }
}
