import 'package:flutter/foundation.dart';

/// Result of the backend CV quality gate (Flow 2 pre-submit step).
///
/// Generic and CV-only: it answers "is this file a usable CV?", never
/// "does it match this internship?". [reason] is user-safe plain language and
/// is shown only when [isValid] is false.
@immutable
class CvValidationResult {
  const CvValidationResult({required this.isValid, this.reason});

  final bool isValid;

  /// Why the CV was rejected; `null` when [isValid] is true.
  final String? reason;

  @override
  bool operator ==(Object other) =>
      other is CvValidationResult &&
      other.isValid == isValid &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(isValid, reason);

  @override
  String toString() => 'CvValidationResult(isValid: $isValid, reason: $reason)';
}
