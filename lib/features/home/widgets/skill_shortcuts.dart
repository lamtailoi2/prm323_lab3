import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// "Browse by skill": a horizontally scrolling row of filter chips. At most
/// one is selected; the selected chip shows a check, not only a color.
class SkillShortcuts extends StatelessWidget {
  const SkillShortcuts({
    super.key,
    required this.skills,
    required this.selected,
    required this.onSelected,
  });

  final List<String> skills;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.minTouchTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        itemCount: skills.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, index) {
          final skill = skills[index];
          return Center(
            child: FilterChip(
              label: Text(skill),
              selected: skill == selected,
              onSelected: (_) => onSelected(skill),
            ),
          );
        },
      ),
    );
  }
}
