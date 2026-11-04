import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';
import '../../internships/viewmodels/apply_form_viewmodel.dart'
    show ApplySession;
import '../widgets/cv_validation_step.dart';

/// Validate CV (G-24, DC-19): the gate between the Apply Form and
/// Application Review.
///
/// A valid CV continues to Review automatically; a rejected CV or a check
/// that could not run offers `Update CV` (back to the form) and `Retry`.
class CvValidationScreen extends StatelessWidget {
  const CvValidationScreen({
    super.key,
    required this.internshipKey,
    required this.source,
    this.session,
  });

  final String internshipKey;

  /// Tab the Detail was opened from (`home`, `search` or `saved`).
  final String source;

  /// `null` when the route is opened without going through the form.
  final ApplySession? session;

  @override
  Widget build(BuildContext context) {
    final session = this.session;
    if (session == null) {
      return Scaffold(
        appBar: const AppTopBar.back(title: 'Validate CV'),
        body: StateView.empty(
          icon: Symbols.description_rounded,
          title: 'Choose a CV first',
          message:
              'Start the application from the Apply Form so we know which CV '
              'to check.',
          actionLabel: 'Back to the form',
          onAction: () =>
              context.go(AppRoutes.applyForm('/$source', internshipKey)),
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar.back(title: 'Validate CV'),
      body: Center(
        child: SingleChildScrollView(
          child: CvValidationStep(
            storagePath: session.cv.file.storagePath,
            // Replaces this step, so Back from Review returns to the form
            // and the check does not run again.
            onValid: () => context.pushReplacement(
              AppRoutes.applicationReview('/$source', internshipKey),
              extra: session,
            ),
            onUpdateCv: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}
