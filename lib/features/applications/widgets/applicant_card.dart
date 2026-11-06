import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/cv_file_tile.dart';
import '../../../core/widgets/detail_row.dart';
import '../../../core/widgets/detail_section_card.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_spacing.dart';

/// `Applicant & Submitted CV` of Application Detail: the CV that was sent
/// (view only) and the details stored with the application.
///
/// Shown only for documents that carry the `applicant` snapshot; applications
/// saved before it existed simply hide the card. Rows without data are left
/// out; `Matched candidate skills` needs the live listing, so it hides once the
/// listing leaves the shared pool (G-25).
class ApplicantCard extends StatelessWidget {
  const ApplicantCard({
    super.key,
    required this.application,
    required this.onPreview,
    this.listing,
  });

  final InternshipApplication application;

  /// `null` once the listing expired from `/internships`.
  final Internship? listing;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final applicant = application.applicant;
    if (applicant == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final email = applicant.email?.trim();
    final phone = applicant.phone?.trim();
    final matched = _matchedSkills(applicant.skills, listing?.skills);

    return DetailSectionCard(
      icon: Symbols.badge_rounded,
      title: 'Applicant & Submitted CV',
      children: [
        if (application.cvFileName case final name?) ...[
          CvFileTile(fileName: name, details: _cvDetails(application)),
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
        DetailRow(label: 'Full name', value: applicant.fullName),
        if (email != null && email.isNotEmpty)
          DetailRow(label: 'University email', value: email),
        if (phone != null && phone.isNotEmpty)
          DetailRow(label: 'Phone number', value: phone),
        if (matched.isNotEmpty) ...[
          Semantics(
            header: true,
            child: Text(
              'Matched candidate skills',
              style: textTheme.labelLarge,
            ),
          ),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [for (final skill in matched) AppTag(label: skill)],
          ),
        ],
      ],
    );
  }

  /// `{size} • Uploaded {date}` per the frame; `Submitted` on an application
  /// saved before the size was recorded, so nothing is invented (DC-29).
  static String _cvDetails(InternshipApplication application) {
    final date = formatShortDate(application.appliedAt);
    if (application.cvSizeBytes case final bytes?) {
      return '${formatFileSize(bytes)} • Uploaded $date';
    }
    return 'PDF · Submitted $date';
  }

  /// The skills sent that the live listing also asks for, in the applicant's
  /// order. Without a listing there is nothing to match against.
  static List<String> _matchedSkills(
    List<String> sent,
    List<String>? required,
  ) {
    if (required == null || required.isEmpty) return const <String>[];
    final wanted = {for (final skill in required) skill.toLowerCase()};
    return [
      for (final skill in sent)
        if (wanted.contains(skill.toLowerCase())) skill,
    ];
  }
}
