import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/cv_library.dart' as cv_library;
import '../../../models/app_user.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_profile_service.dart';

/// What the Profile screen shows: the stored profile plus the Google
/// account, whose email and photo are never copied into Firestore, and the
/// CV library.
@immutable
class ProfileOverview {
  const ProfileOverview({
    required this.account,
    required this.profile,
    required this.cvs,
    this.defaultCvId,
  });

  final AppUser account;
  final UserProfile profile;

  /// `users/{uid}/cvs`, newest first; without the legacy mirror.
  final List<CvFile> cvs;
  final String? defaultCvId;

  /// What the CV section lists: the library plus the legacy mirror, without
  /// duplicates (G-33).
  List<CvFile> get library => cv_library.mergeLegacyCv(cvs, profile.cv);

  /// The CV marked default, falling back to the legacy mirror and then the
  /// newest file.
  CvFile? get defaultCv => cv_library.defaultCv(cvs, defaultCvId, profile.cv);

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

/// Live profile of the signed-in student (`users/{uid}`) and their CV
/// library.
///
/// A missing document is not an empty state: the screen shows the Google
/// account with empty sections, each with its own call to action.
class ProfileViewModel extends Notifier<ViewState<ProfileOverview>> {
  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<List<CvFile>>? _cvsSubscription;

  UserProfile? _profile;
  List<CvFile> _cvs = const <CvFile>[];
  bool _profileLoaded = false;
  bool _cvsLoaded = false;
  AppUser? _account;

  @override
  ViewState<ProfileOverview> build() {
    // User-scoped (AGENTS.md rule 11): sign-out or an account switch
    // rebuilds this provider and cancels the old listeners.
    ref.watch(currentUserIdProvider);
    final account = ref.watch(
      authStateChangesProvider.select((auth) => auth.value),
    );
    final service = ref.watch(userProfileServiceProvider);
    ref.onDispose(() {
      unawaited(_profileSubscription?.cancel());
      unawaited(_cvsSubscription?.cancel());
    });

    unawaited(_profileSubscription?.cancel());
    unawaited(_cvsSubscription?.cancel());
    _profileLoaded = false;
    _cvsLoaded = false;

    // Signed out: the router is already leaving this screen.
    if (account == null) return const ViewLoading();
    _account = account;
    _subscribe(service, account);
    return const ViewLoading();
  }

  Future<void> retry() async {
    if (state.isLoading) return;
    final service = ref.read(userProfileServiceProvider);
    final account = ref.read(authStateChangesProvider).value;
    if (account == null) return;
    _profileLoaded = false;
    _cvsLoaded = false;
    state = const ViewLoading();
    _subscribe(service, account);
  }

  void _subscribe(UserProfileService service, AppUser account) {
    unawaited(_profileSubscription?.cancel());
    unawaited(_cvsSubscription?.cancel());

    _profileSubscription = service.watchProfile(account.uid).listen(
      (profile) {
        if (!ref.mounted) return;
        _profile = profile;
        _profileLoaded = true;
        _emitIfReady();
      },
      onError: (Object error, StackTrace _) =>
          _fail(error, 'We could not load your profile.'),
    );

    _cvsSubscription = service.watchCvs(account.uid).listen(
      (cvs) {
        if (!ref.mounted) return;
        _cvs = cvs;
        _cvsLoaded = true;
        _emitIfReady();
      },
      onError: (Object error, StackTrace _) =>
          _fail(error, 'We could not load your CV library.'),
    );
  }

  void _emitIfReady() {
    final account = _account;
    if (!_profileLoaded || !_cvsLoaded || account == null) return;
    state = ViewData(
      ProfileOverview(
        account: account,
        profile: _profile ?? const UserProfile(),
        cvs: _cvs,
        defaultCvId: _profile?.defaultCvId,
      ),
    );
  }

  void _fail(Object error, String message) {
    if (!ref.mounted) return;
    state = ViewError(
      error is AppException
          ? error
          : AppException(
              AppErrorKind.unknown,
              '$message Try again in a moment.',
              cause: error,
            ),
    );
  }
}
