import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/distinct_listings.dart';
import '../../../services/application_service.dart';

/// Jobs ([jobIdentity]) the signed-in student tracks in My Applications, for
/// the `Applied` badge on Home, Search Results and Saved cards (Flow 2c).
/// Identities, not keys: the card may show another synced copy of the job
/// than the one applied to (CR-07).
///
/// [applicationServiceProvider] watches `currentUserIdProvider`, so the set
/// is dropped on sign-out (AGENTS.md rule 11); one listener serves every
/// card, as `savedInternshipIdsProvider` does for the Save Toggle.
final appliedJobsProvider = StreamProvider<Set<String>>((ref) {
  final service = ref.watch(applicationServiceProvider);
  return service.watchApplications().map(
    (applications) => {
      for (final application in applications)
        jobIdentity(application.title, application.companyName),
    },
  );
});
