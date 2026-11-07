import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_profile_service.dart';

/// Login screen state: `AsyncData` = idle, `AsyncLoading` = signing in,
/// `AsyncError` = an [AppException] whose message the screen shows. A
/// cancelled account picker is also reported (kind `cancelled`), because
/// Lab 3 §6 requires a visible message; the screen styles it as info.
///
/// Successful sign-in needs no navigation here: the router redirects as soon
/// as the auth state changes.
final loginViewModelProvider =
    NotifierProvider.autoDispose<LoginViewModel, AsyncValue<void>>(
      LoginViewModel.new,
    );

class LoginViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signInWithGoogle() async {
    if (state.isLoading) return;
    // Read dependencies before awaiting: the screen (and this provider) may
    // be disposed by the redirect that follows a successful sign-in.
    final auth = ref.read(authServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final profiles = ref.read(userProfileServiceProvider);

    state = const AsyncLoading();
    try {
      final user = await auth.signInWithGoogle();
      await analytics.logLogin(method: 'google');
      final givenName = user.givenName;
      if (givenName != null) {
        // Best effort: without it Home greets with the full account name.
        try {
          await profiles.updateGivenName(user.uid, givenName);
        } on AppException {
          // Ignored: sign-in itself succeeded.
        }
      }
      if (ref.mounted) state = const AsyncData(null);
    } on AppException catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
    }
  }
}
