import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/allowance.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/utils/posted_age.dart';
import '../../../core/widgets/company_logo.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_elevation.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../../applications/widgets/application_status_badge.dart';

/// Top of Internship Detail (Figma "Job Hero Card", DC-31): one card with a
/// decorative cover, the company logo overlapping it, the title, the
/// company and city, the posted age and source site, the allowance as the
/// highlighted fact, then work mode and job type.
///
/// When the student already tracks an [application], its status badge sits
/// beside the logo and a note at the bottom says when they applied (this
/// replaces the separate "Applied" banner).
///
/// Google Jobs has no cover photo, deadline, duration or verified flag
/// (G-25, DC-24), so the cover is one shared image and those fields are not
/// shown.
class JobHeroCard extends StatelessWidget {
  const JobHeroCard({super.key, required this.internship, this.application});

  /// Shared cover image. It is decoration only: replace the file to change
  /// it.
  static const String coverAsset = 'assets/images/job_cover.jpg';

  static const String notDisclosed = 'Not disclosed';

  final Internship internship;
  final InternshipApplication? application;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tracked = application;
    final postedAt = internship.postedAt;
    final posted = postedAt != null
        ? formatPostedAgeLong(postedAt)
        : internship.postedText;
    final via = internship.via;
    final location = internship.location;
    const logoOverlap = AppSizes.companyLogoHero / 2;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.largeAll,
        boxShadow: AppElevation.level1,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.largeAll,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: AppSizes.jobCoverHeight,
                  child: Image.asset(
                    coverAsset,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: AppColors.primaryContainer),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    0,
                    AppSpacing.s16,
                    AppSpacing.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room for the lower half of the logo; the status badge
                      // sits on its right.
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: logoOverlap,
                        ),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: tracked == null
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.s8,
                                  ),
                                  child: ApplicationStatusBadge(
                                    status: tracked.status,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Semantics(
                        header: true,
                        child: Text(
                          internship.title,
                          style: textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: internship.companyName,
                              style: textTheme.labelLarge?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            if (location != null)
                              TextSpan(
                                text: ' · $location',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (posted != null || via != null) ...[
                        const SizedBox(height: AppSpacing.s12),
                        Wrap(
                          spacing: AppSpacing.s8,
                          runSpacing: AppSpacing.s8,
                          children: [
                            if (posted != null)
                              _MetaChip(
                                icon: Symbols.schedule_rounded,
                                text: 'Posted $posted',
                              ),
                            if (via != null)
                              _MetaChip(
                                icon: Symbols.public_rounded,
                                text: 'via $via',
                              ),
                          ],
                        ),
                      ],
                      const Divider(height: AppSpacing.s32),
                      _AllowanceFact(value: formatAllowance(internship.salary)),
                      const SizedBox(height: AppSpacing.s12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _Fact(
                                icon: Symbols.home_work_rounded,
                                label: 'Work mode',
                                value:
                                    internship.workMode?.label ?? notDisclosed,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: _Fact(
                                icon: Symbols.work_history_rounded,
                                label: 'Job type',
                                value: internship.scheduleType ?? notDisclosed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (tracked != null) ...[
                        const SizedBox(height: AppSpacing.s12),
                        _AppliedNote(
                          title:
                              'You applied on '
                              '${formatShortDate(tracked.appliedAt)}',
                          // Students update the status themselves (G-25 #6),
                          // so the note points there instead of promising a
                          // notification.
                          message:
                              'Status: ${tracked.status.label}. Update it in '
                              'My Applications when the company replies.',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: AppSpacing.s16,
              top: AppSizes.jobCoverHeight - logoOverlap,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.largeAll,
                  boxShadow: AppElevation.level1,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: CompanyLogo(
                    companyName: internship.companyName,
                    url: internship.logoUrl,
                    size: AppSizes.companyLogoHero - AppSpacing.s8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadii.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSizes.iconSmall,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.fileTile,
      height: AppSizes.fileTile,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: AppSizes.iconSmall, color: foreground),
    );
  }
}

/// The allowance is what students compare first, so it gets its own band.
class _AllowanceFact extends StatelessWidget {
  const _AllowanceFact({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppRadii.mediumAll,
      ),
      child: Row(
        children: [
          const _IconCircle(
            icon: Symbols.payments_rounded,
            background: AppColors.primary,
            foreground: AppColors.onPrimary,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allowance',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadii.mediumAll,
      ),
      child: Row(
        children: [
          _IconCircle(
            icon: icon,
            background: AppColors.primaryContainer,
            foreground: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(value, style: textTheme.labelLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppliedNote extends StatelessWidget {
  const _AppliedNote({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadii.mediumAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Symbols.check_circle_rounded,
              size: AppSizes.iconSmall,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    message,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
