import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/allowance.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/widgets/company_logo.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// Header of Application Detail: the position, the company and the facts
/// the listing gave.
///
/// The status badge lives only on the tracker below (DC-29); showing it
/// here too would repeat the same status twice on screen. `Duration` from
/// the frame is absent: Google Jobs does not provide it (DC-10). No
/// verified tick: the app has no data behind "verified" (precedent DC-15,
/// DC-24). Facts without data are hidden.
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
      if (listing?.scheduleType case final type?)
        (icon: Symbols.work_history_rounded, text: type),
      if (listing?.postedText case final posted?)
        (icon: Symbols.schedule_rounded, text: 'Posted $posted'),
    ];
    final location = listing?.location;

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
              CompanyLogo(
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
                    // The city joins the company line (Figma Application
                    // Detail v2, DC-31) instead of taking a chip.
                    Text(
                      location == null
                          ? application.companyName
                          : '${application.companyName} · $location',
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
          if (facts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final fact in facts)
                  _Fact(icon: fact.icon, text: fact.text),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              const Icon(
                Symbols.event_available_rounded,
                size: AppSizes.iconSmall,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Text(
                  'Submitted ${formatShortDate(application.appliedAt)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One fact chip, read as a single label; `surface-variant` background per
/// the frame (never an invented tint — design-system.md §2.12 precedent).
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
      child: DecoratedBox(
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
              Text(text, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
