import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/allowance.dart';
import '../../../core/widgets/company_logo.dart';
import '../../../models/internship.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// Internship summary card at the top of the compose screen: logo, title,
/// `Company · Work mode` (or the location when Google gives no work mode)
/// and the allowance and job type from the Detail key facts.
class ApplySummaryCard extends StatelessWidget {
  const ApplySummaryCard({super.key, required this.internship});

  final Internship internship;

  static const String _notDisclosed = 'Not disclosed';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      internship.companyName,
      ?(internship.workMode?.label ?? internship.location),
    ].join(' · ');
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
              CompanyLogo(
                companyName: internship.companyName,
                size: AppSizes.companyLogoLarge,
                url: internship.logoUrl,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      internship.title,
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
          Wrap(
            spacing: AppSpacing.s16,
            runSpacing: AppSpacing.s8,
            children: [
              _SummaryFact(
                icon: Symbols.payments_rounded,
                label: 'Allowance',
                value: formatAllowance(internship.salary),
              ),
              _SummaryFact(
                icon: Symbols.work_history_rounded,
                label: 'Job type',
                value: internship.scheduleType ?? _notDisclosed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One key fact in the summary card: icon and value, read with its label
/// (e.g. "Allowance: Negotiable").
class _SummaryFact extends StatelessWidget {
  const _SummaryFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
