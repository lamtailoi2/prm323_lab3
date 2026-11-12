import 'package:flutter/foundation.dart';

/// Result of the automatic CV selection (`selectCv`, G-33 item 8).
///
/// The score is computed server-side from the internship requirements, the
/// Profile skills and the skills found in each CV's text; the model only
/// writes [reason]. Parsing lives in `CvSelectService`.
@immutable
class CvSelection {
  const CvSelection({
    required this.storagePath,
    required this.percent,
    required this.matchedCount,
    required this.totalRequired,
    required this.reason,
    required this.cvReadable,
  });

  /// The `storagePath` of the CV the server chose.
  final String storagePath;

  /// 0–100; 0 when the listing lists no known skill.
  final int percent;
  final int matchedCount;
  final int totalRequired;

  /// One honest sentence explaining the choice.
  final String reason;

  /// `false` when the chosen CV's PDF text could not be read; the score then
  /// compares Profile skills only.
  final bool cvReadable;

  @override
  bool operator ==(Object other) =>
      other is CvSelection &&
      other.storagePath == storagePath &&
      other.percent == percent &&
      other.matchedCount == matchedCount &&
      other.totalRequired == totalRequired &&
      other.reason == reason &&
      other.cvReadable == cvReadable;

  @override
  int get hashCode => Object.hash(
    storagePath,
    percent,
    matchedCount,
    totalRequired,
    reason,
    cvReadable,
  );

  @override
  String toString() =>
      'CvSelection($storagePath, $percent%, $matchedCount/$totalRequired)';
}
