import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/skill_match.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/detail_section_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/apply_form_viewmodel.dart';

/// "Personal information" of the Apply Form frames: the details the company
/// receives, prefilled from the Profile and editable here.
class ApplyPersonalSection extends StatelessWidget {
  const ApplyPersonalSection({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.university,
    required this.yearOfStudy,
    required this.errors,
    required this.onSelectUniversity,
    required this.onSelectYear,
  });

  final TextEditingController fullName;
  final TextEditingController email;
  final TextEditingController phone;

  /// Read-only fields; the picker sheets write their text.
  final TextEditingController university;
  final TextEditingController yearOfStudy;

  final ApplyFieldErrors errors;
  final VoidCallback onSelectUniversity;
  final VoidCallback onSelectYear;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      icon: Symbols.person_rounded,
      title: 'Personal information',
      isRequired: true,
      children: [
        AppTextField(
          label: 'Full name',
          isRequired: true,
          controller: fullName,
          hintText: 'e.g. Minh Nguyen',
          errorText: errors.fullName,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
        ),
        AppTextField(
          label: 'Email',
          controller: email,
          prefixIcon: Symbols.alternate_email_rounded,
          helperText: 'From your Google account',
          enabled: false,
          suffix: const Icon(
            Symbols.lock_rounded,
            size: AppSizes.iconSmall,
            color: AppColors.disabled,
          ),
        ),
        AppTextField(
          label: 'Phone number',
          isRequired: true,
          controller: phone,
          prefixIcon: Symbols.call_rounded,
          hintText: 'e.g. 0908 123 456',
          helperText: 'The company will use this to arrange an interview',
          errorText: errors.phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        AppTextField(
          label: 'University',
          isRequired: true,
          controller: university,
          prefixIcon: Symbols.school_rounded,
          hintText: 'Select your university',
          errorText: errors.university,
          readOnly: true,
          onTap: onSelectUniversity,
          suffix: const Icon(
            Symbols.expand_more_rounded,
            size: AppSizes.iconSmall,
            color: AppColors.textSecondary,
          ),
        ),
        AppTextField(
          label: 'Year of study',
          isRequired: true,
          controller: yearOfStudy,
          prefixIcon: Symbols.calendar_month_rounded,
          hintText: 'Select year of study',
          errorText: errors.yearOfStudy,
          readOnly: true,
          onTap: onSelectYear,
          suffix: const Icon(
            Symbols.expand_more_rounded,
            size: AppSizes.iconSmall,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// "Skills" of the Apply Form frames: the Profile skills that go with the
/// application, the listing's missing skills in the error colour, and
/// `Add skill`, which opens the Profile Edit skills sheet over the form.
class ApplySkillsSection extends StatelessWidget {
  const ApplySkillsSection({
    super.key,
    required this.skills,
    required this.match,
    required this.onAddSkill,
  });

  final List<String> skills;

  /// `null` when the listing names no known skill or `cv_match_enabled` is
  /// off; the section then shows only the student's skills.
  final SkillMatch? match;
  final VoidCallback onAddSkill;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final missing = match?.missing ?? const <String>[];
    // A student with no skills yet is invited to add them instead of being
    // shown "0 of N" and every requirement in red (as on Internship Detail).
    final hasSkills = match?.profileHasSkills ?? skills.isNotEmpty;
    return DetailSectionCard(
      icon: Symbols.code_rounded,
      title: 'Skills',
      action: AppButton(
        label: 'Add skill',
        icon: Symbols.add_rounded,
        variant: AppButtonVariant.text,
        onPressed: onAddSkill,
      ),
      children: [
        if (match case final match?) ...[
          Text(
            match.profileHasSkills
                ? 'You have ${match.matched.length} of ${match.total} '
                      'required skills'
                : 'This internship asks for ${match.total} '
                      '${match.total == 1 ? 'skill' : 'skills'}',
            style: textTheme.labelLarge,
          ),
          if (match.profileHasSkills && missing.isNotEmpty)
            Text(
              'Missing: ${missing.join(', ')}',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
        if (skills.isEmpty && missing.isEmpty)
          Text('No skills added yet.', style: textTheme.bodyMedium)
        else
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final skill in skills)
                _SkillChip(label: skill, missing: false),
              for (final skill in missing)
                _SkillChip(label: skill, missing: hasSkills),
            ],
          ),
      ],
    );
  }
}

/// One skill tag of the form: a check for a skill the student has, an error
/// icon for one the listing asks for. Meaning never rests on colour alone.
class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.missing});

  final String label;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final color = missing ? AppColors.error : AppColors.primary;
    return Semantics(
      label: missing ? '$label, missing' : label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
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
              Icon(
                missing ? Symbols.close_rounded : Symbols.check_rounded,
                size: AppSizes.iconSmall,
                color: color,
              ),
              const SizedBox(width: AppSpacing.s4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Short introduction" of the Apply Form frames; the text goes with this
/// application only (it is not the Profile bio).
class ApplyIntroductionSection extends StatelessWidget {
  const ApplyIntroductionSection({super.key, required this.controller});

  final TextEditingController controller;

  /// Longest accepted introduction (frame: `0 / 500`).
  static const int maxLength = 500;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      icon: Symbols.notes_rounded,
      title: 'Short introduction',
      children: [
        AppTextField(
          label: 'Why are you interested in this role?',
          controller: controller,
          helperText: '2-3 sentences is enough.',
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 4,
          maxLines: 6,
          maxLength: maxLength,
        ),
      ],
    );
  }
}
