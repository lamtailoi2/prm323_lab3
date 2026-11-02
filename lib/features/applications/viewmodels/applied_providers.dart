import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/application_service.dart';

/// Keys of the listings the signed-in student tracks in My Applications,
/// for the `Applied` badge on Home, Search Results and Saved cards (Flow 2c).
///
/// [applicationServiceProvider] watches `currentUserIdProvider`, so the set
/// is dropped on sign-out (AGENTS.md rule 11); one listener serves every
/// card, as `savedInternshipIdsProvider` does for the Save Toggle.
final appliedInternshipKeysProvider = StreamProvider<Set<String>>((ref) {
  final service = ref.watch(applicationServiceProvider);
  return service.watchApplications().map(
    (applications) => {
      for (final application in applications) application.jobKey,
    },
  );
});
