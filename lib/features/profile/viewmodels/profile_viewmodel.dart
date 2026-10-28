import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../models/app_user.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_profile_service.dart';

/// What the Profile screen shows: the stored profile plus the Google
/// account, whose email and photo are never copied into Firestore.
@immutable
class ProfileOverview {
  const ProfileOverview({required this.account, required this.profile});

  final AppUser account;
  final UserProfile profile;

  /// The saved name first, then the Google name, so a new student never
  /// sees an empty header.
  String get displayName =>
      profile.details.fullName ??
      account.displayName ??
      account.email ??
      'Student';
}

final profileViewModelProvider =
    NotifierProvider.autoDispose<ProfileViewModel, ViewState<ProfileOverview>>(
      ProfileViewModel.new,
    );

/// Live profile of the signed-in student (`users/{uid}`).
///
/// A missing document is not an empty state: the screen shows the Google
/// account with empty sections, each with its own call to action.
class ProfileViewModel extends Notifier<ViewState<ProfileOverview>> {
  StreamSubscription<UserProfile?>? _subscription;

  @override
  ViewState<ProfileOverview> build() {
    // User-scoped (AGENTS.md rule 11): sign-out or an account switch
    // rebuilds this provider and cancels the old listener.
    ref.watch(currentUserIdProvider);
    final account = ref.watch(
      authStateChangesProvider.select((auth) => auth.value),
    );
    final service = ref.watch(userProfileServiceProvider);
    ref.onDispose(() => unawaited(_subscription?.cancel()));

    // Signed out: the router is already leaving this screen.
    if (account == null) return const ViewLoading();
    _subscribe(service, account);
    return const ViewLoading();
  }

  Future<void> retry() async {
    if (state.isLoading) return;
    final service = ref.read(userProfileServiceProvider);
    final account = ref.read(authStateChangesProvider).value;
    if (account == null) return;
    state = const ViewLoading();
    _subscribe(service, account);
  }

  void _subscribe(UserProfileService service, AppUser account) {
    unawaited(_subscription?.cancel());
    _subscription = service
        .watchProfile(account.uid)
        .listen(
          (profile) {
            if (!ref.mounted) return;
            state = ViewData(
              ProfileOverview(
                account: account,
                profile: profile ?? const UserProfile(),
              ),
            );
          },
          onError: (Object error, StackTrace _) {
            if (!ref.mounted) return;
            state = ViewError(
              error is AppException
                  ? error
                  : AppException(
                      AppErrorKind.unknown,
                      'We could not load your profile. Try again in a moment.',
                      cause: error,
                    ),
            );
          },
        );
  }
}
