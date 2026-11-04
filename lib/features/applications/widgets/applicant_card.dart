import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/cv_file_tile.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_spacing.dart';
import '../../internships/widgets/application_review_parts.dart';
import '../../internships/widgets/detail_parts.dart';

/// `Applicant & Submitted CV` of Application Detail: the CV that was sent
/// (view only) and the details stored with the application.
///
/// Shown only for documents that carry the `applicant` snapshot; applications
/// saved before it existed simply hide the card.
class ApplicantCard extends StatelessWidget {
  const ApplicantCard({
    super.key,
    required this.application,
    required this.onPreview,
  });

  final InternshipApplication application;
  final VoidCallback onPreview;

  static const String _notAdded = 'Not added';

  @override
  Widget build(BuildContext context) {
    final applicant = application.applicant;
    if (applicant == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final year = applicant.yearOfStudy;

    return DetailSectionCard(
      icon: Symbols.badge_rounded,
      title: 'Applicant & Submitted CV',
      children: [
        if (application.cvFileName case final name?) ...[
          CvFileTile(
            fileName: name,
            details:
                'PDF · Submitted '
                '${formatShortDate(application.appliedAt)}',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Preview',
              icon: Symbols.visibility_rounded,
              variant: AppButtonVariant.text,
              onPressed: application.cvUrl == null ? null : onPreview,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
        ReviewDetailRow(label: 'Full name', value: applicant.fullName),
        ReviewDetailRow(label: 'Email', value: applicant.email ?? _notAdded),
        ReviewDetailRow(
          label: 'Phone number',
          value: applicant.phone ?? _notAdded,
        ),
        ReviewDetailRow(
          label: 'University',
          value: applicant.university ?? _notAdded,
        ),
        ReviewDetailRow(
          label: 'Year of study',
          value: year == null ? _notAdded : 'Year $year',
        ),
        if (applicant.skills.isNotEmpty) ...[
          Semantics(
            header: true,
            child: Text('Skills sent', style: textTheme.labelLarge),
          ),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final skill in applicant.skills) AppTag(label: skill),
            ],
          ),
        ],
      ],
    );
  }
}
