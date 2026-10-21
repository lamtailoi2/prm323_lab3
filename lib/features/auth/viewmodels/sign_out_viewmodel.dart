import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';

/// Sign-out action state. The router returns to Login once auth changes.
final signOutViewModelProvider =
    NotifierProvider.autoDispose<SignOutViewModel, AsyncValue<void>>(
      SignOutViewModel.new,
    );

class SignOutViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signOut() async {
    if (state.isLoading) return;
    final auth = ref.read(authServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    state = const AsyncLoading();
    try {
      // Logged before signing out so the event keeps the user's session.
      await analytics.logLogout();
      await auth.signOut();
      if (ref.mounted) state = const AsyncData(null);
    } on AppException catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
    }
  }
}
