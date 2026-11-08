import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth_service.dart';
import '../../../services/user_profile_service.dart';

/// The name the Home header greets the student by (DC-31): Google's
/// `given_name`, saved to `users/{uid}.givenName` at sign-in. `null` until
/// it is known (or if the profile cannot be read), so Home falls back to the
/// full account name.
///
/// Watches `currentUserIdProvider`, so sign-out drops it (AGENTS.md rule 11).
final homeGivenNameProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(null);
  return ref
      .watch(userProfileServiceProvider)
      .watchProfile(uid)
      .map((profile) => profile?.givenName);
});
