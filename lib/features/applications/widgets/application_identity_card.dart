import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/allowance.dart';
import '../../../core/utils/display_format.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../../internships/widgets/detail_parts.dart';
import 'application_status_badge.dart';

/// Header of Application Detail: the position, the company, the facts the
/// listing gave and the current status.
///
/// `Duration` from the frame is absent: Google Jobs does not provide it
/// (DC-10). Facts without data are hidden.
class ApplicationIdentityCard extends StatelessWidget {
  const ApplicationIdentityCard({
    super.key,
    required this.application,
    this.listing,
  });

  final InternshipApplication application;

  /// `null` once the listing left the shared pool.
  final Internship? listing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final facts = <({IconData icon, String text})>[
      if (listing?.salary case final salary?)
        (icon: Symbols.payments_rounded, text: formatAllowance(salary)),
      if (listing?.workMode case final mode?)
        (icon: Symbols.home_work_rounded, text: 'Work mode ${mode.label}'),
      if (listing?.location case final location?)
        (icon: Symbols.location_on_rounded, text: location),
      if (listing?.scheduleType case final type?)
        (icon: Symbols.work_history_rounded, text: type),
      (
        icon: Symbols.event_available_rounded,
        text: 'Submitted ${formatShortDate(application.appliedAt)}',
      ),
      if (listing?.postedText case final posted?)
        (icon: Symbols.schedule_rounded, text: 'Posted $posted'),
    ];

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailCompanyLogo(
                companyName: application.companyName,
                size: AppSizes.companyLogoLarge,
                url: listing?.logoUrl,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        application.title,
                        style: textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      application.companyName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              ApplicationStatusBadge(status: application.status),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s16,
            runSpacing: AppSpacing.s8,
            children: [
              for (final fact in facts) _Fact(icon: fact.icon, text: fact.text),
            ],
          ),
        ],
      ),
    );
  }
}

/// One fact chip, read as a single label.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s4),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
