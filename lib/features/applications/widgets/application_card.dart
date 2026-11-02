import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import 'application_status_badge.dart';

/// Application Card of the My Applications screen (Figma frame
/// `my-applications-final.png`).
///
/// Position, company, submitted date and current status, plus the next date
/// to act on when the document has one. Accepted applications also show the
/// frame's `Review offer` action. The whole card opens Application Detail.
///
/// Feature-local on purpose: only My Applications and (later) Application
/// Detail use it, and its layout is not a shared Lab 2 component.
class ApplicationCard extends StatelessWidget {
  const ApplicationCard({
    super.key,
    required this.application,
    this.onTap,
    this.onPrimaryAction,
  });

  /// Label of the accepted-state action in the frame.
  static const String reviewOfferLabel = 'Review offer';

  final InternshipApplication application;
  final VoidCallback? onTap;

  /// Handles [reviewOfferLabel]; hidden when null.
  final VoidCallback? onPrimaryAction;

  /// Interview slots read as a date, reply deadlines as a request.
  bool get _isInterview => application.status == ApplicationStatus.interview;

  String get _nextStepText {
    final nextStepAt = application.nextStepAt;
    if (nextStepAt == null) return '';
    return _isInterview
        ? formatMonthDayTime(nextStepAt)
        : formatReplyBy(nextStepAt);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appliedText = 'Applied ${formatDayMonth(application.appliedAt)}';
    final nextStepAt = application.nextStepAt;
    final showReviewOffer =
        application.status == ApplicationStatus.accepted &&
        onPrimaryAction != null;

    // One labeled node for screen readers and ARTEMIS (Lab 3 §7); visible
    // texts are excluded so they are not read twice, while the action stays
    // its own tappable node.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        button: onTap != null,
        label: _summary(appliedText),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.largeAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          application.title,
                          style: textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    ExcludeSemantics(
                      child: ApplicationStatusBadge(status: application.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: [
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          '${application.companyName} · $appliedText',
                          style: textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: AppSpacing.s8),
                      const ExcludeSemantics(
                        child: Icon(
                          Symbols.chevron_right_rounded,
                          size: AppSizes.iconSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (nextStepAt != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        Icon(
                          _isInterview
                              ? Symbols.event_rounded
                              : Symbols.schedule_rounded,
                          size: AppSizes.iconSmall,
                          color: _isInterview
                              ? AppColors.primary
                              : AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        Flexible(
                          child: Text(
                            _nextStepText,
                            style: textTheme.bodySmall?.copyWith(
                              color: _isInterview
                                  ? AppColors.primary
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (showReviewOffer) ...[
                  const SizedBox(height: AppSpacing.s16),
                  AppButton(
                    label: reviewOfferLabel,
                    onPressed: onPrimaryAction,
                    expand: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _summary(String appliedText) {
    return [
      '${application.title} at ${application.companyName}',
      'Status: ${application.status.label}',
      appliedText,
      if (application.nextStepAt != null) _nextStepText,
    ].join('. ');
  }
}
