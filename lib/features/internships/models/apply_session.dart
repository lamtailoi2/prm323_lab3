import 'package:flutter/foundation.dart';

import '../../../models/user_profile.dart';

/// Where the CV for this application comes from.
enum CvSource { profile, uploaded }

/// The CV the student is applying with, handed to the optional CV checks.
@immutable
class ApplyCv {
  const ApplyCv(this.file, this.source);

  final CvFile file;
  final CvSource source;
}

/// What the compose screen hands to the optional CV Match / Validate steps:
/// the CV, the Profile details being sent, and when the screen opened.
@immutable
class ApplySession {
  const ApplySession({
    required this.cv,
    required this.startedAt,
    required this.email,
    required this.details,
    required this.skills,
    required this.introduction,
  });

  final ApplyCv cv;
  final DateTime startedAt;

  /// The Google address shown on the compose screen.
  final String email;
  final ProfileDetails details;
  final List<String> skills;

  /// The cover letter written for this application.
  final String introduction;
}
