import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/profile_viewmodel.dart';

/// Identity card at the top of Profile: avatar, name, academic line,
/// university, contact rows and the primary `Edit profile` action.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.overview,
    required this.onEdit,
  });

  final ProfileOverview overview;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = overview.profile.details;
    final academic = [
      if (details.yearOfStudy case final year?) 'Year $year',
      ?details.major,
    ].join(' · ');
    final hasAcademic = academic.isNotEmpty || details.university != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Avatar(photoUrl: overview.account.photoUrl),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(overview.displayName, style: textTheme.titleLarge),
                      if (details.headline case final headline?) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          headline,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                      if (academic.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          academic,
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      if (details.university case final university?) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(university, style: textTheme.bodyMedium),
                      ],
                      if (!hasAcademic) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          'Add your university and major.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            if (overview.account.email case final email?)
              _ContactRow(
                icon: Symbols.mail_rounded,
                label: 'Email',
                text: email,
              ),
            if (details.phone case final phone?) ...[
              const SizedBox(height: AppSpacing.s8),
              _ContactRow(
                icon: Symbols.call_rounded,
                label: 'Phone',
                text: phone,
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            AppButton(
              label: 'Edit profile',
              icon: Symbols.edit_rounded,
              expand: true,
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox.square(
          dimension: AppSizes.profileHeaderAvatar,
          child: ColoredBox(
            color: AppColors.primaryContainer,
            child: url == null
                ? const _AvatarFallback()
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _AvatarFallback(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(Symbols.person_rounded, color: AppColors.primary);
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;

  /// Spoken before the value, since the icon alone carries the meaning.
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $text',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
