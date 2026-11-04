import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../services/analytics_service.dart';
import '../../../services/application_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/crashlytics_service.dart';
import '../../../services/internship_service.dart';
import '../../../services/user_profile_service.dart';
import 'apply_form_viewmodel.dart';

/// Which listing is reviewed and the tab its Detail was opened from
/// (`home`, `search` or `saved`).
typedef ApplicationReviewArgs = ({String internshipKey, String source});

/// Application Review (Flow 2: Confirm Application).
@immutable
class ApplicationReviewState {
  const ApplicationReviewState({
    this.internship = const ViewLoading(),
    this.submit = const AsyncData(null),
  });

  final ViewState<Internship> internship;

  /// `AsyncError` carries an [AppException] with a message safe to show.
  final AsyncValue<void> submit;

  ApplicationReviewState copyWith({
    ViewState<Internship>? internship,
    AsyncValue<void>? submit,
  }) {
    return ApplicationReviewState(
      internship: internship ?? this.internship,
      submit: submit ?? this.submit,
    );
  }
}

final applicationReviewViewModelProvider = NotifierProvider.autoDispose
    .family<
      ApplicationReviewViewModel,
      ApplicationReviewState,
      ApplicationReviewArgs
    >(ApplicationReviewViewModel.new);

class ApplicationReviewViewModel extends Notifier<ApplicationReviewState> {
  ApplicationReviewViewModel(this.args);

  final ApplicationReviewArgs args;

  StreamSubscription<Internship?>? _listingSubscription;

  /// The listing last seen, so `submit` does not need it from the View.
  Internship? _listing;

  @override
  ApplicationReviewState build() {
    final internships = ref.watch(internshipServiceProvider);
    // User-scoped (AGENTS.md rule 11).
    ref.watch(currentUserIdProvider);
    _listing = null;
    ref.onDispose(() => unawaited(_listingSubscription?.cancel()));
    _subscribe(internships);
    return const ApplicationReviewState();
  }

  /// `Retry` after the listing failed to load.
  void retry() {
    if (state.internship.isLoading) return;
    state = state.copyWith(internship: const ViewLoading());
    _subscribe(ref.read(internshipServiceProvider));
  }

  /// Writes the application, logs `application_create`, and returns the
  /// submit time so the View can open the success screen. `null` means it
  /// failed: the screen stays and `state.submit` holds the message.
  Future<DateTime?> submit(ApplySession session) async {
    if (state.submit.isLoading) return null;
    final internship = _listing;
    if (internship == null) return null;

    // Read every provider before the first await (AGENTS.md).
    final service = ref.read(applicationServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final profiles = ref.read(userProfileServiceProvider);
    final crashlytics = ref.read(crashlyticsServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      state = state.copyWith(submit: _error(_signedOut));
      return null;
    }

    state = state.copyWith(submit: const AsyncLoading());
    try {
      await service.createApplication(
        internshipKey: internship.key,
        title: internship.title,
        companyName: internship.companyName,
        cvStoragePath: session.cv.file.storagePath,
        cvFileName: session.cv.file.fileName,
        cvUrl: session.cv.file.url,
        applicant: ApplicationApplicant(
          fullName: session.details.fullName ?? '',
          email: session.email.isEmpty ? null : session.email,
          phone: session.details.phone,
          university: session.details.university,
          yearOfStudy: session.details.yearOfStudy,
          skills: session.skills,
          introduction: session.introduction.isEmpty
              ? null
              : session.introduction,
        ),
      );
      final submittedAt = DateTime.now();
      await analytics.logEvent('application_create', {
        'internship_id': internship.key,
        'cv_source': session.cv.source.name,
        'duration_sec': _elapsedSeconds(session.startedAt),
      });
      // The application is stored now, so a Profile sync failure never turns
      // a real submission into an error.
      await _syncProfile(profiles, crashlytics, uid, session);
      if (!ref.mounted) return submittedAt;
      state = state.copyWith(submit: const AsyncData(null));
      return submittedAt;
    } on AppException catch (error, stack) {
      if (ref.mounted) state = state.copyWith(submit: AsyncError(error, stack));
      return null;
    } on Exception catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          submit: _error(
            AppException(
              AppErrorKind.unknown,
              'We could not submit your application. Try again in a moment.',
              cause: error,
            ),
          ),
        );
      }
      return null;
    }
  }

  /// Keeps `users/{uid}` in step with what was sent (name, phone, university,
  /// year of study and skills), so the next application is prefilled.
  Future<void> _syncProfile(
    UserProfileService profiles,
    CrashlyticsService crashlytics,
    String uid,
    ApplySession session,
  ) async {
    try {
      await profiles.updateApplyDetails(uid, session.details);
      await profiles.updateSkills(uid, session.skills);
    } on AppException catch (error, stack) {
      unawaited(
        crashlytics.recordError(
          error,
          stack,
          reason: 'Skipped syncing the Profile after an application',
        ),
      );
    }
  }

  void _subscribe(InternshipService service) {
    unawaited(_listingSubscription?.cancel());
    _listingSubscription = service
        .watchByKey(args.internshipKey)
        .listen(
          (listing) {
            if (!ref.mounted) return;
            _listing = listing;
            state = state.copyWith(
              internship: listing == null
                  ? const ViewEmpty()
                  : ViewData(listing),
            );
          },
          onError: (Object error, StackTrace _) {
            if (!ref.mounted) return;
            state = state.copyWith(
              internship: ViewError(
                error is AppException
                    ? error
                    : AppException(
                        AppErrorKind.unknown,
                        'We could not load this internship. Try again in a '
                        'moment.',
                        cause: error,
                      ),
              ),
            );
          },
        );
  }

  /// Seconds from opening the form to submitting, never negative when the
  /// device clock moves backwards.
  static int _elapsedSeconds(DateTime startedAt) {
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  static AsyncError<void> _error(AppException error) =>
      AsyncError<void>(error, StackTrace.current);

  static const AppException _signedOut = AppException(
    AppErrorKind.permissionDenied,
    'Sign in again and try once more.',
  );
}
