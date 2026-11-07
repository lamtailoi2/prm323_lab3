import 'package:flutter/foundation.dart';

/// A subject line and cover letter drafted for one internship.
@immutable
class CoverLetterDraft {
  const CoverLetterDraft({
    required this.subject,
    required this.body,
    required this.usedAi,
  });

  final String subject;
  final String body;

  /// `false` when the deterministic template was used because the model was
  /// unavailable; the screen then says so instead of pretending.
  final bool usedAi;
}
