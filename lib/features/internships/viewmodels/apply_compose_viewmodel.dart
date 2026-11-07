import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/contact_email.dart';
import '../../../core/utils/mailto.dart';
import '../../../core/utils/validators.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../models/user_profile.dart';
import '../../../services/analytics_service.dart';
import '../../../services/application_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/cover_letter_service.dart';
import '../../../services/external_link_service.dart';
import '../../../services/internship_service.dart';
import '../../../services/user_profile_service.dart';
import '../models/apply_session.dart';

/// Which listing the student applies to and the tab its Detail was opened
/// from (`home`, `search` or `saved`).
typedef ApplyComposeArgs = ({String internshipKey, String source});

/// What a successful `I've sent it` hands to the View so it can open Success.
typedef ApplicationSent = ({DateTime submittedAt, Internship internship});

/// Compose the application email (Flow 2 replacement for the Apply Form).
@immutable
class ApplyComposeState {
  const ApplyComposeState({
    this.internship = const ViewLoading(),
    this.profileLoaded = false,
    this.profile,
    this.profileError,
    this.recipientEmail = '',
    this.recipientError,
    this.subject = '',
    this.body = '',
    this.draftVersion = 0,
    this.usedAi = true,
    this.generate = const AsyncData(null),
    this.send = const AsyncData(null),
    this.openingEmail = false,
    this.emailOpened = false,
    this.openError,
  });

  final ViewState<Internship> internship;

  /// `false` until the profile arrives (or fails).
  final bool profileLoaded;
  final UserProfile? profile;
  final AppException? profileError;

  final String recipientEmail;

  /// Message under the To field (invalid address).
  final String? recipientError;
  final String subject;
  final String body;

  /// Increments when the ViewModel replaces the draft, so the screen knows
  /// when to copy the new text into its controllers (and never overwrites
  /// what the student typed).
  final int draftVersion;
  final bool usedAi;

  /// `AsyncLoading` while Groq drafts; `AsyncError` when the call itself
  /// failed (the draft is then left as it was).
  final AsyncValue<void> generate;
  final AsyncValue<void> send;
  final bool openingEmail;
  final bool emailOpened;
  final AppException? openError;

  bool get isGenerating => generate.isLoading;
  bool get isSending => send.isLoading;

  static const Object _keep = Object();

  ApplyComposeState copyWith({
    ViewState<Internship>? internship,
    bool? profileLoaded,
    Object? profile = _keep,
    Object? profileError = _keep,
    String? recipientEmail,
    Object? recipientError = _keep,
    String? subject,
    String? body,
    int? draftVersion,
    bool? usedAi,
    AsyncValue<void>? generate,
    AsyncValue<void>? send,
    bool? openingEmail,
    bool? emailOpened,
    Object? openError = _keep,
  }) {
    return ApplyComposeState(
      internship: internship ?? this.internship,
      profileLoaded: profileLoaded ?? this.profileLoaded,
      profile: identical(profile, _keep)
          ? this.profile
          : profile as UserProfile?,
      profileError: identical(profileError, _keep)
          ? this.profileError
          : profileError as AppException?,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientError: identical(recipientError, _keep)
          ? this.recipientError
          : recipientError as String?,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      draftVersion: draftVersion ?? this.draftVersion,
      usedAi: usedAi ?? this.usedAi,
      generate: generate ?? this.generate,
      send: send ?? this.send,
      openingEmail: openingEmail ?? this.openingEmail,
      emailOpened: emailOpened ?? this.emailOpened,
      openError: identical(openError, _keep)
          ? this.openError
          : openError as AppException?,
    );
  }
}

final applyComposeViewModelProvider = NotifierProvider.autoDispose
    .family<ApplyComposeViewModel, ApplyComposeState, ApplyComposeArgs>(
      ApplyComposeViewModel.new,
    );

class ApplyComposeViewModel extends Notifier<ApplyComposeState> {
  ApplyComposeViewModel(this.args);

  final ApplyComposeArgs args;

  StreamSubscription<Internship?>? _listingSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;

  Internship? _listing;
  UserProfile? _profile;
  String? _accountEmail;
  String? _displayName;

  /// The student typed in the To field, so a regeneration must not replace
  /// the address with the one found in the job post.
  bool _recipientEdited = false;

  /// Kept across `build()` re-runs (the auth stream emits null → signed-in),
  /// so a later rebuild neither drops the draft nor cancels a subscription
  /// whose error is already in flight.
  bool _listingStarted = false;
  String? _profileUid;
  bool _profileLoaded = false;
  AppException? _lastProfileError;
  AppException? _listingError;

  bool _autoGenerateStarted = false;
  bool _startLogged = false;
  final DateTime _startedAt = DateTime.now();

  @override
  ApplyComposeState build() {
    final service = ref.watch(internshipServiceProvider);
    final profiles = ref.read(userProfileServiceProvider);
    // User-scoped (AGENTS.md rule 11): another account drops this draft.
    final uid = ref.watch(currentUserIdProvider);
    final account = ref.read(authStateChangesProvider).value;

    _accountEmail = account?.email;
    _displayName = account?.displayName;

    ref.onDispose(() {
      unawaited(_listingSubscription?.cancel());
      unawaited(_profileSubscription?.cancel());
    });

    if (!_listingStarted) {
      _listingStarted = true;
      _subscribeListing(service);
    }
    if (uid != null && _profileUid != uid) {
      _profileUid = uid;
      _profile = null;
      _profileLoaded = false;
      _lastProfileError = null;
      _autoGenerateStarted = false;
      _subscribeProfile(profiles, uid);
    }

    _logStart();
    return ApplyComposeState(
      internship: _listingError != null
          ? ViewError(_listingError!)
          : _listing != null
          ? ViewData(_listing!)
          : const ViewLoading(),
      profileLoaded: _profileLoaded,
      profile: _profile,
      profileError: _lastProfileError,
    );
  }

  /// Retry after the listing failed to load.
  void retry() {
    if (state.internship.isLoading) return;
    _listing = null;
    _listingError = null;
    state = state.copyWith(internship: const ViewLoading());
    _subscribeListing(ref.read(internshipServiceProvider));
  }

  /// Retry after the profile failed to load.
  void retryProfile() {
    if (state.profileError == null) return;
    _profileLoaded = false;
    _lastProfileError = null;
    state = state.copyWith(profileLoaded: false, profileError: null);
    _subscribeProfile(
      ref.read(userProfileServiceProvider),
      ref.read(currentUserIdProvider),
    );
  }

  void setRecipient(String value) {
    _recipientEdited = true;
    state = state.copyWith(recipientEmail: value, recipientError: null);
  }

  void setSubject(String value) => state = state.copyWith(subject: value);

  void setBody(String value) => state = state.copyWith(body: value);

  /// Drafts (or redrafts) the subject and letter. The recipient is prefilled
  /// from the job post only while the student has not typed one.
  Future<void> regenerate() async {
    if (state.generate.isLoading) return;
    final listing = _listing;
    if (listing == null) return;

    final service = ref.read(coverLetterServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final found = findApplicationEmail(_jobText(listing));
    final recipient = _recipientEdited
        ? state.recipientEmail
        : (found ?? state.recipientEmail);
    final studentName = _studentName;

    state = state.copyWith(
      generate: const AsyncLoading(),
      recipientEmail: recipient,
      recipientError: null,
    );
    try {
      final draft = await service.compose(
        internshipKey: listing.key,
        storagePath: _profile?.cv?.storagePath,
        studentName: studentName,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        subject: draft.subject,
        body: draft.body,
        usedAi: draft.usedAi,
        draftVersion: state.draftVersion + 1,
        generate: const AsyncData(null),
      );
      unawaited(
        analytics.logEvent('cover_letter_generate', <String, Object>{
          'internship_id': listing.key,
          'source': draft.usedAi ? 'ai' : 'template',
        }),
      );
    } on AppException catch (error, stack) {
      if (ref.mounted) {
        state = state.copyWith(generate: AsyncError(error, stack));
      }
    }
  }

  /// Opens the draft in the device's email app.
  Future<void> openEmail() async {
    if (state.openingEmail) return;
    final recipient = state.recipientEmail.trim();
    if (recipient.isNotEmpty) {
      final error = Validators.email(
        recipient,
        message: 'Enter a valid email address.',
      );
      if (error != null) {
        state = state.copyWith(recipientError: error);
        return;
      }
    }

    final links = ref.read(externalLinkServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final listing = _listing;
    final uri = buildMailtoUri(
      to: recipient,
      subject: state.subject,
      body: state.body,
    );

    state = state.copyWith(
      openingEmail: true,
      recipientError: null,
      openError: null,
    );
    try {
      await links.openEmail(uri);
      if (!ref.mounted) return;
      state = state.copyWith(openingEmail: false, emailOpened: true);
      if (listing != null) {
        unawaited(
          analytics.logEvent('cover_letter_open_email', <String, Object>{
            'internship_id': listing.key,
            'has_recipient': recipient.isEmpty ? 'no' : 'yes',
          }),
        );
      }
    } on AppException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(openingEmail: false, openError: error);
      }
    }
  }

  /// Records the application once the student says the email was sent.
  Future<ApplicationSent?> markSent() async {
    if (state.isSending) return null;
    final listing = _listing;
    if (listing == null) return null;

    // Read every provider before the first await (AGENTS.md).
    final applications = ref.read(applicationServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    final account = ref.read(authStateChangesProvider).value;
    final profile = _profile;

    if (uid == null) {
      state = state.copyWith(send: _error(_signedOut));
      return null;
    }

    final fullName = (profile?.details.fullName?.trim().isNotEmpty ?? false)
        ? profile!.details.fullName!.trim()
        : (account?.displayName?.trim() ?? '');
    if (fullName.isEmpty) {
      state = state.copyWith(
        send: _error(
          const AppException(
            AppErrorKind.invalidInput,
            'Add your name in Profile to record this application.',
          ),
        ),
      );
      return null;
    }

    final cv = profile?.cv;
    final email = account?.email?.trim();
    final recipient = state.recipientEmail.trim();
    state = state.copyWith(send: const AsyncLoading());
    try {
      await applications.createApplication(
        internshipKey: listing.key,
        title: listing.title,
        companyName: listing.companyName,
        cvStoragePath: cv?.storagePath,
        cvFileName: cv?.fileName,
        cvUrl: cv?.url,
        cvSizeBytes: cv?.sizeBytes,
        applicant: ApplicationApplicant(
          fullName: fullName,
          email: email == null || email.isEmpty ? null : email,
          phone: profile?.details.phone,
          university: profile?.details.university,
          yearOfStudy: profile?.details.yearOfStudy,
          skills: profile?.skills ?? const <String>[],
          introduction: state.body.trim().isEmpty ? null : state.body.trim(),
        ),
        recipientEmail: recipient.isEmpty ? null : recipient,
        appliedVia: ApplicationChannel.email,
      );
      final submittedAt = DateTime.now();
      unawaited(
        analytics.logEvent('application_create', <String, Object>{
          'internship_id': listing.key,
          'channel': 'email',
          'cv_source': cv == null ? 'none' : 'profile',
          'duration_sec': _elapsedSeconds(_startedAt),
        }),
      );
      if (ref.mounted) {
        state = state.copyWith(send: const AsyncData(null), emailOpened: true);
      }
      return (submittedAt: submittedAt, internship: listing);
    } on AppException catch (error, stack) {
      if (ref.mounted) state = state.copyWith(send: AsyncError(error, stack));
      return null;
    } on Exception catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          send: _error(
            AppException(
              AppErrorKind.unknown,
              'We could not save this application. Try again in a moment.',
              cause: error,
            ),
          ),
        );
      }
      return null;
    }
  }

  /// What the optional CV Match / Validate steps need; `null` when the
  /// student has no CV in their Profile.
  ApplySession? buildSession() {
    final listing = _listing;
    final profile = _profile;
    final cv = profile?.cv;
    if (listing == null || profile == null || cv == null) return null;
    return ApplySession(
      cv: ApplyCv(cv, CvSource.profile),
      startedAt: _startedAt,
      email: _accountEmail ?? '',
      details: profile.details,
      skills: profile.skills,
      introduction: state.body,
    );
  }

  String? get _studentName {
    final name = _profile?.details.fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final display = _displayName?.trim();
    return display == null || display.isEmpty ? null : display;
  }

  static String _jobText(Internship internship) => [
    ?internship.description,
    for (final highlight in internship.highlights) ...highlight.items,
  ].join('\n');

  void _subscribeListing(InternshipService service) {
    unawaited(_listingSubscription?.cancel());
    _listingSubscription = service
        .watchByKey(args.internshipKey)
        .listen(
          (listing) {
            if (!ref.mounted) return;
            _listing = listing;
            _listingError = null;
            state = state.copyWith(
              internship: listing == null
                  ? const ViewEmpty()
                  : ViewData(listing),
            );
            _maybeGenerate();
          },
          onError: (Object error, StackTrace _) {
            if (!ref.mounted) return;
            final failure = error is AppException
                ? error
                : AppException(
                    AppErrorKind.unknown,
                    'We could not load this internship. Try again in a moment.',
                    cause: error,
                  );
            _listingError = failure;
            state = state.copyWith(internship: ViewError(failure));
          },
        );
  }

  void _subscribeProfile(UserProfileService profiles, String? uid) {
    unawaited(_profileSubscription?.cancel());
    if (uid == null) return;
    _profileSubscription = profiles
        .watchProfile(uid)
        .listen(
          (profile) {
            if (!ref.mounted) return;
            _profile = profile;
            _profileLoaded = true;
            _lastProfileError = null;
            state = state.copyWith(
              profileLoaded: true,
              profile: profile,
              profileError: null,
            );
            _maybeGenerate();
          },
          onError: (Object error, StackTrace _) {
            if (!ref.mounted) return;
            final failure = error is AppException
                ? error
                : AppException(
                    AppErrorKind.unknown,
                    'We could not load your Profile. Try again.',
                    cause: error,
                  );
            _profileLoaded = true;
            _lastProfileError = failure;
            state = state.copyWith(profileLoaded: true, profileError: failure);
            _maybeGenerate();
          },
        );
  }

  /// Drafts once when both the listing and the profile have resolved, so a
  /// rebuild or a later snapshot does not spend another model call.
  void _maybeGenerate() {
    if (_autoGenerateStarted || _listing == null || !state.profileLoaded) {
      return;
    }
    _autoGenerateStarted = true;
    scheduleMicrotask(() {
      if (ref.mounted) unawaited(regenerate());
    });
  }

  void _logStart() {
    if (_startLogged) return;
    _startLogged = true;
    unawaited(
      ref.read(analyticsServiceProvider).logEvent(
        'apply_start',
        <String, Object>{
          'internship_id': args.internshipKey,
          'source': args.source,
        },
      ),
    );
  }

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
