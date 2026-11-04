import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/internship.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../widgets/detail_parts.dart';

/// What Review hands to Success through the route `extra`: the recap of the
/// application that was just recorded.
typedef ApplicationSuccessArgs = ({
  String internshipTitle,
  String companyName,
  WorkMode? workMode,
  String? logoUrl,
  DateTime submittedAt,
});

/// Application Success (Flow 2 frame "Application submitted"): the
/// application is recorded in `users/{uid}/applications`, so the student can
/// track it from now on.
///
/// No ViewModel: the screen confirms, recaps and offers the two next steps.
class ApplicationSuccessScreen extends StatelessWidget {
  const ApplicationSuccessScreen({
    super.key,
    this.internshipTitle,
    this.companyName,
    this.workMode,
    this.logoUrl,
    this.submittedAt,
  });

  /// Recap of what was recorded; all are `null` when the route is opened
  /// without a submission (then only the confirmation is shown).
  final String? internshipTitle;
  final String? companyName;
  final WorkMode? workMode;
  final String? logoUrl;
  final DateTime? submittedAt;

  static const double _iconSize = AppSizes.icon * 2;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = internshipTitle;
    final company = companyName;
    final when = submittedAt;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Symbols.check_circle_rounded,
                    size: _iconSize,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'Application submitted!',
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    title != null && company != null
                        ? 'Your application for $title at $company is saved '
                              'in My Applications.'
                        : 'Your application is saved in My Applications.',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (title != null && company != null) ...[
                    const SizedBox(height: AppSpacing.s24),
                    _RecapCard(
                      title: title,
                      company: company,
                      workMode: workMode,
                      logoUrl: logoUrl,
                      submittedAt: when,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  _WhatHappensNext(textTheme: textTheme),
                  const SizedBox(height: AppSpacing.s32),
                  AppButton(
                    label: 'View my applications',
                    expand: true,
                    onPressed: () => context.go(AppRoutes.applications),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  AppButton(
                    label: 'Back to Home',
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The application that was saved: logo, position, company and submit time.
class _RecapCard extends StatelessWidget {
  const _RecapCard({
    required this.title,
    required this.company,
    required this.workMode,
    required this.logoUrl,
    required this.submittedAt,
  });

  final String title;
  final String company;
  final WorkMode? workMode;
  final String? logoUrl;
  final DateTime? submittedAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [company, ?workMode?.label].join(' · ');
    final when = submittedAt;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.largeAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DetailCompanyLogo(
                companyName: company,
                size: AppSizes.companyLogoLarge,
                url: logoUrl,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      when == null
                          ? 'Submitted'
                          : 'Submitted ${formatShortDateTime(when)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              const StatusBadge(
                label: 'Submitted',
                icon: Symbols.check_circle_rounded,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Honest "What happens next?" steps: the app records the application and the
/// student updates the status themselves (G-25 #6, DC-28).
class _WhatHappensNext extends StatelessWidget {
  const _WhatHappensNext({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('What happens next?', style: textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.s12),
        _Step(
          index: 1,
          text: 'We saved your details and CV with this application.',
        ),
        const SizedBox(height: AppSpacing.s8),
        const _Step(
          index: 2,
          text:
              'Update the status in My Applications when the company replies.',
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.iconSmall,
          height: AppSizes.iconSmall,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(child: Text(text, style: textTheme.bodyMedium)),
      ],
    );
  }
}
