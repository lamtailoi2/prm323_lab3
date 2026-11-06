import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/display_format.dart';
import '../../../core/widgets/detail_section_card.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import 'application_status_badge.dart';

/// How one step of the tracker reads.
enum _StepState { done, active, upcoming, withdrawn, rejected }

typedef _Step = ({
  String title,
  String? date,
  String description,
  _StepState state,
});

/// `Status tracker` of Application Detail.
///
/// The steps follow the status the **student** set (G-25 #6): the screen
/// never claims employer events, a review deadline or step notes the app
/// does not have, unlike the frame's "Expected review outcome by Oct 24"
/// banner and per-step process notes (DC-29).
class ApplicationStatusTracker extends StatelessWidget {
  const ApplicationStatusTracker({super.key, required this.application});

  final InternshipApplication application;

  static const List<({String title, String description})> _steps = [
    (
      title: 'Submitted',
      description: 'Your details and CV are saved with this application.',
    ),
    (
      title: 'Under review',
      description: 'You are waiting for the company to reply.',
    ),
    (
      title: 'Technical interview',
      description: 'An interview is scheduled or has taken place.',
    ),
    (
      title: 'Offer decision',
      description: 'The company has sent its decision.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final steps = _rows();
    final progress = _progress();
    return DetailSectionCard(
      icon: Symbols.timeline_rounded,
      title: 'Status tracker',
      action: ApplicationStatusBadge(status: application.status),
      children: [
        if (progress case final progress?) _ProgressLine(progress: progress),
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s16),
          _StepRow(step: steps[i]),
        ],
      ],
    );
  }

  /// `Step X of 4 (Y% completed)`; only meaningful while the tracker shows
  /// the normal 4-step flow (not the 2-step withdrawn / rejected one).
  ({int step, int total, int percent})? _progress() {
    final activeIndex = switch (application.status) {
      ApplicationStatus.submitted => 0,
      ApplicationStatus.underReview => 1,
      ApplicationStatus.interview => 2,
      ApplicationStatus.accepted => 3,
      _ => null,
    };
    if (activeIndex == null) return null;
    final total = _steps.length;
    final step = activeIndex + 1;
    return (step: step, total: total, percent: (step * 100) ~/ total);
  }

  List<_Step> _rows() {
    final _Step submitted = (
      title: 'Submitted',
      date: formatShortDate(application.appliedAt),
      description: _steps.first.description,
      state: application.status == ApplicationStatus.submitted
          ? _StepState.active
          : _StepState.done,
    );

    if (application.status == ApplicationStatus.withdrawn) {
      final when = application.withdrawnAt;
      return [
        submitted,
        (
          title: 'Withdrawn',
          date: when == null ? null : formatShortDate(when),
          description: 'You took this application back.',
          state: _StepState.withdrawn,
        ),
      ];
    }

    if (application.status == ApplicationStatus.rejected) {
      return [
        submitted,
        (
          title: 'Not selected',
          date: null,
          description: 'The company did not go ahead with this application.',
          state: _StepState.rejected,
        ),
      ];
    }

    final activeIndex = switch (application.status) {
      ApplicationStatus.underReview => 1,
      ApplicationStatus.interview => 2,
      ApplicationStatus.accepted => 3,
      _ => 0,
    };
    final interviewAt = application.nextStepAt;

    return [
      for (var i = 0; i < _steps.length; i++)
        (
          title: _steps[i].title,
          date: switch (i) {
            0 => formatShortDate(application.appliedAt),
            2 when interviewAt != null => formatMonthDayTime(interviewAt),
            _ => null,
          },
          description: _steps[i].description,
          state: i < activeIndex
              ? _StepState.done
              : i == activeIndex
              ? _StepState.active
              : _StepState.upcoming,
        ),
    ];
  }
}

/// `Step X of 4 (Y% completed)` caption and progress bar above the steps.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress});

  final ({int step, int total, int percent}) progress;

  @override
  Widget build(BuildContext context) {
    final label =
        'Step ${progress.step} of ${progress.total} '
        '(${progress.percent}% completed)';
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.s8),
          ClipRRect(
            borderRadius: AppRadii.smallAll,
            child: LinearProgressIndicator(
              value: progress.step / progress.total,
              minHeight: AppSpacing.s8,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, color) = switch (step.state) {
      _StepState.done => (Symbols.check_circle_rounded, AppColors.success),
      _StepState.active => (
        Symbols.radio_button_checked_rounded,
        AppColors.primary,
      ),
      _StepState.upcoming => (
        Symbols.radio_button_unchecked_rounded,
        AppColors.disabled,
      ),
      _StepState.withdrawn => (Symbols.undo_rounded, AppColors.textSecondary),
      _StepState.rejected => (Symbols.cancel_rounded, AppColors.error),
    };
    final muted = step.state == _StepState.upcoming;

    final active = step.state == _StepState.active;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.icon, color: color),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      step.title,
                      style: textTheme.labelLarge?.copyWith(
                        color: muted ? AppColors.textSecondary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (step.state == _StepState.active) ...[
                    const SizedBox(width: AppSpacing.s8),
                    const _ActiveChip(),
                  ],
                  if (step.date case final date?) ...[
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      date,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                step.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: muted ? AppColors.textSecondary : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      container: true,
      label: [
        step.title,
        ?step.date,
        step.description,
        if (active) 'Active step',
      ].join('. '),
      excludeSemantics: true,
      // The current step is tinted so it stands out (Application Detail v2,
      // DC-31).
      child: active
          ? DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppRadii.mediumAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s8),
                child: row,
              ),
            )
          : row,
    );
  }
}

/// `Active step` pill of the frame, white on the tinted step row.
class _ActiveChip extends StatelessWidget {
  const _ActiveChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Text(
          'Active step',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
