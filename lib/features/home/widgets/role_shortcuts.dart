import 'package:flutter/material.dart';

import '../../../core/utils/job_role.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// "Browse by Role": a horizontally scrolling row of filter chips. At most
/// one is selected; the selected chip shows a check, not only a color.
class RoleShortcuts extends StatelessWidget {
  const RoleShortcuts({
    super.key,
    required this.roles,
    required this.selected,
    required this.onSelected,
  });

  final List<JobRole> roles;
  final JobRole? selected;
  final ValueChanged<JobRole> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.minTouchTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        itemCount: roles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, index) {
          final role = roles[index];
          return Center(
            child: FilterChip(
              label: Text(role.label),
              selected: role == selected,
              showCheckmark: true,
              onSelected: (_) => onSelected(role),
            ),
          );
        },
      ),
    );
  }
}
