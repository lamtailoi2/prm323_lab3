import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';
import '../../internships/viewmodels/apply_form_viewmodel.dart'
    show ApplySession;
import '../widgets/cv_match_step.dart';

/// CV Match Check (G-24, DC-09): an advisory comparison between the CV /
/// Profile skills and the internship being applied to.
///
/// It sits between the Apply Form and the Validate CV gate and never blocks.
class CvMatchScreen extends StatelessWidget {
  const CvMatchScreen({
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
        appBar: const AppTopBar.back(title: 'CV match'),
        body: StateView.empty(
          icon: Symbols.description_rounded,
          title: 'Choose a CV first',
          message:
              'Start the application from the Apply Form so we know which CV '
              'to compare with this internship.',
          actionLabel: 'Back to the form',
          onAction: () =>
              context.go(AppRoutes.applyForm('/$source', internshipKey)),
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar.back(title: 'CV match'),
      body: Center(
        child: SingleChildScrollView(
          child: CvMatchStep(
            storagePath: session.cv.file.storagePath,
            internshipKey: internshipKey,
            // Back from the Validate CV gate returns to the Apply Form, not to
            // this advisory screen.
            onContinue: () => context.pushReplacement(
              AppRoutes.applyValidation('/$source', internshipKey),
              extra: session,
            ),
            // The form owns the Edit skills / Replace CV sheets, so editing
            // there rebuilds the session (and the submitted skills).
            onEdit: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}
