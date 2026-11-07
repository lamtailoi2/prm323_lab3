import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_colors.dart';

/// Maps the applications statuses onto the shared [StatusBadge]
/// (design-system.md §2.12).
///
/// Label + meaningful icon, never color alone. The neutral/a11y color pairs
/// come from the Figma specimens; the rejected contrast fix is tracked as
/// DC-04 and stays a token change, not a one-off color here.
class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      ApplicationStatus.submitted => (
        Symbols.send_rounded,
        AppColors.textSecondary,
      ),
      ApplicationStatus.underReview => (
        Symbols.hourglass_top_rounded,
        AppColors.warning,
      ),
      ApplicationStatus.interview => (Symbols.event_rounded, AppColors.primary),
      ApplicationStatus.accepted => (
        Symbols.check_circle_rounded,
        AppColors.success,
      ),
      ApplicationStatus.rejected => (Symbols.cancel_rounded, AppColors.error),
      // Flow 3d: the student took the application back (G-18 resolved by the
      // Application Detail frame).
      ApplicationStatus.withdrawn => (
        Symbols.undo_rounded,
        AppColors.textSecondary,
      ),
    };

    return StatusBadge(label: status.label, icon: icon, color: color);
  }
}
