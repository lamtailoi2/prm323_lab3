import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/skill_match.dart';
import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// Figma "Match Card" on Internship Detail, fed by Profile skills only
/// (DC-24): the percentage, a level badge, and one Skill Tag per listing
/// skill, matched ones with a check.
///
/// A student without any Profile skill sees an invitation instead of
/// "0% skill match / Low match": the listing's skills and `Add skills`.
class SkillMatchCard extends StatelessWidget {
  const SkillMatchCard({super.key, required this.match, this.onAddSkills});

  final SkillMatch match;

  /// Opens Profile, where skills are edited; shown only while the profile
  /// has no skill.
  final VoidCallback? onAddSkills;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasSkills = match.profileHasSkills;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppRadii.largeAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.info_rounded,
                size: AppSizes.iconSmall,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Text(
                  hasSkills
                      ? '${match.percent}% skill match'
                      : 'See how you match',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (hasSkills) ...[
                const SizedBox(width: AppSpacing.s8),
                _LevelBadge(match.level),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            hasSkills
                ? 'Based on the skills in your Profile.'
                : 'Add your skills in Profile to see how you match.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.s12),
          Text(
            hasSkills
                ? 'You have ${match.matched.length} of ${match.total} '
                      'required skills'
                : 'This internship asks for ${match.total} '
                      '${match.total == 1 ? 'skill' : 'skills'}',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final skill in match.matched)
                _SkillChip(label: skill, status: _ChipStatus.matched),
              for (final skill in match.missing)
                _SkillChip(
                  label: skill,
                  status: hasSkills ? _ChipStatus.missing : _ChipStatus.listed,
                ),
            ],
          ),
          if (!hasSkills && onAddSkills != null) ...[
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: 'Add skills',
              variant: AppButtonVariant.text,
              icon: Symbols.add_rounded,
              onPressed: onAddSkills,
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge(this.level);

  final MatchLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.fullAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        level.label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

/// `listed` is a listing skill shown to a student who has no Profile skill
/// yet, so it is not announced as "missing".
enum _ChipStatus { matched, missing, listed }

/// Figma "Skill Tag" on a container: matched = check + primary label,
/// missing / listed = secondary label. The semantics label states the
/// status, so it is never conveyed by color alone.
class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.status});

  final String label;
  final _ChipStatus status;

  @override
  Widget build(BuildContext context) {
    final matched = status == _ChipStatus.matched;
    final color = matched ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      container: true,
      label: switch (status) {
        _ChipStatus.matched => '$label, you have this skill',
        _ChipStatus.missing => '$label, missing',
        _ChipStatus.listed => label,
      },
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.smallAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (matched) ...[
              Icon(
                Symbols.check_rounded,
                size: AppSizes.iconSmall,
                color: color,
              ),
              const SizedBox(width: AppSpacing.s4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
