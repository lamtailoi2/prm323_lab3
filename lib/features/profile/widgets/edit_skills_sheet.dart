import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/edit_skills_viewmodel.dart';
import 'profile_section.dart';
import 'profile_sheet.dart';

/// Edit skills sheet (Lab 2 `profile-skills.png`): search, the selected
/// skills with remove and `Clear all`, and suggested skills to toggle.
class EditSkillsSheet extends ConsumerWidget {
  const EditSkillsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editSkillsViewModelProvider);
    final viewModel = ref.read(editSkillsViewModelProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final selected = state.selected.toSet();

    return ProfileSheet(
      icon: Symbols.code_rounded,
      title: 'Edit skills',
      subtitle: 'Select your technical proficiencies',
      primaryLabel: 'Save changes',
      primaryIcon: Symbols.check_rounded,
      isLoading: state.save.isLoading,
      error: switch (state.save.error) {
        final AppException error => error,
        _ => null,
      },
      onPrimary: () async {
        if (await viewModel.save() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      children: [
        AppSearchField(
          hintText: 'Search skills (e.g. Flutter, SQL, Python)',
          onChanged: viewModel.search,
        ),
        const SizedBox(height: AppSpacing.s16),
        _SelectedSkills(
          skills: state.selected,
          onRemove: viewModel.toggle,
          onClearAll: viewModel.clearAll,
        ),
        const SizedBox(height: AppSpacing.s16),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Suggested skills', style: textTheme.labelLarge),
              ),
            ),
            Text('Tap to add or remove', style: textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        if (state.suggestions.isEmpty)
          ProfileHint('No skills match "${state.query.trim()}".')
        else
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s4,
            children: [
              for (final skill in state.suggestions)
                SheetChip(
                  label: skill,
                  selected: selected.contains(skill),
                  showAddIcon: true,
                  onSelected: () => viewModel.toggle(skill),
                ),
            ],
          ),
      ],
    );
  }
}

class _SelectedSkills extends StatelessWidget {
  const _SelectedSkills({
    required this.skills,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<String> skills;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadii.mediumAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s12,
          AppSpacing.s4,
          AppSpacing.s4,
          AppSpacing.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  header: true,
                  child: Text('Selected skills', style: textTheme.labelLarge),
                ),
                const SizedBox(width: AppSpacing.s8),
                _CountBadge(count: skills.length),
                const Spacer(),
                // Destructive text action: error color, as in the frame.
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    disabledForegroundColor: AppColors.disabled,
                  ),
                  onPressed: skills.isEmpty ? null : onClearAll,
                  child: const Text('Clear all'),
                ),
              ],
            ),
            if (skills.isEmpty)
              const ProfileHint('No skills selected yet.')
            else
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s4,
                children: [
                  for (final skill in skills)
                    InputChip(
                      label: Text(skill),
                      padding: SheetChip.padding,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: SheetChip.outlineWidth,
                      ),
                      labelStyle: textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                      deleteIcon: const Icon(
                        Symbols.close_rounded,
                        size: AppSizes.iconSmall,
                      ),
                      deleteIconColor: AppColors.primary,
                      deleteButtonTooltipMessage: 'Remove $skill',
                      onDeleted: () => onRemove(skill),
                      onPressed: () => onRemove(skill),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// "4 chosen" pill next to the Selected skills heading.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppRadii.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Text(
          '$count chosen',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
