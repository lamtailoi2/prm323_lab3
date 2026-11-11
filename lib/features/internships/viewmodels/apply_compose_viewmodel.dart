import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/contact_email.dart';
import '../../../core/utils/cv_library.dart';
import '../../../core/utils/mailto.dart';
import '../../../core/utils/validators.dart';
import '../../../models/cv_selection.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../models/user_profile.dart';
import '../../../services/analytics_service.dart';
import '../../../services/application_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/cover_letter_service.dart';
import '../../../services/cv_select_service.dart';
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
    this.library = const <CvFile>[],
    this.defaultCvFile,
    this.chosenCv,
    this.autoSelection,
    this.autoSelecting = false,
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

  /// Every CV in the Profile library, with the legacy mirror merged in.
  final List<CvFile> library;

  /// The Profile default, resolved from the library (G-33).
  final CvFile? defaultCvFile;

  /// A library CV chosen for this application only; never written back.
  final CvFile? chosenCv;

  /// The automatic choice from `selectCv`; `null` until it resolves or when
  /// the library has fewer than two CVs.
  final CvSelection? autoSelection;
  final bool autoSelecting;

  /// The CV this application uses: the student's choice, else the default.
  CvFile? get cv => chosenCv ?? defaultCvFile;

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
    List<CvFile>? library,
    Object? defaultCvFile = _keep,
    Object? chosenCv = _keep,
    Object? autoSelection = _keep,
    bool? autoSelecting,
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
      library: library ?? this.library,
      defaultCvFile: identical(defaultCvFile, _keep)
          ? this.defaultCvFile
          : defaultCvFile as CvFile?,
      chosenCv: identical(chosenCv, _keep)
          ? this.chosenCv
          : chosenCv as CvFile?,
      autoSelection: identical(autoSelection, _keep)
          ? this.autoSelection
          : autoSelection as CvSelection?,
      autoSelecting: autoSelecting ?? this.autoSelecting,
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
  StreamSubscription<List<CvFile>>? _cvsSubscription;

  Internship? _listing;
  UserProfile? _profile;
  String? _accountEmail;
  String? _displayName;

  /// The library without the legacy mirror; merged in [ApplyComposeState]
  /// (G-33).
  List<CvFile> _cvs = const <CvFile>[];
  CvFile? _legacyCv;
  String? _defaultCvId;
  bool _cvsLoaded = false;

  /// `selectCv` runs once per screen; a later snapshot must not override a
  /// choice the student has already made.
  bool _autoSelectRequested = false;
  bool _autoSelectResolved = false;
  bool _cvChosenByStudent = false;

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
      unawaited(_cvsSubscription?.cancel());
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
      _cvs = const <CvFile>[];
      _legacyCv = null;
      _defaultCvId = null;
      _cvsLoaded = false;
      _autoSelectRequested = false;
      _autoSelectResolved = false;
      _cvChosenByStudent = false;
      _subscribeProfile(profiles, uid);
      _subscribeCvs(profiles, uid);
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
      library: _mergedLibrary,
      defaultCvFile: _resolveDefaultCv(),
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

  /// `Change CV` in the CV sheet: use a library entry for this application
  /// only. The Profile default is never changed (DC-26).
  void selectLibraryCv(CvFile cv) {
    _cvChosenByStudent = true;
    _autoSelectResolved = true;
    state = state.copyWith(chosenCv: cv);
    _maybeGenerate();
  }

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
        storagePath: state.cv?.storagePath,
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

    final cv = state.cv;
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
    final cv = state.cv;
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
            _maybeAutoSelect();
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
            _legacyCv = profile?.cv;
            _defaultCvId = profile?.defaultCvId;
            _profileLoaded = true;
            _lastProfileError = null;
            state = state.copyWith(
              profileLoaded: true,
              profile: profile,
              profileError: null,
            );
            _applyLibrary();
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
            _applyLibrary();
          },
        );
  }

  /// Watches the Profile CV library (G-33). A failure is silent: the default
  /// CV from the profile still applies, so the student is never blocked by a
  /// failed comparison.
  void _subscribeCvs(UserProfileService profiles, String? uid) {
    unawaited(_cvsSubscription?.cancel());
    if (uid == null) return;
    _cvsSubscription = profiles
        .watchCvs(uid)
        .listen(
          (cvs) {
            if (!ref.mounted) return;
            _cvs = cvs;
            _cvsLoaded = true;
            _applyLibrary();
          },
          onError: (Object error, StackTrace _) {
            if (!ref.mounted) return;
            _cvsLoaded = true;
            _applyLibrary();
          },
        );
  }

  List<CvFile> get _mergedLibrary => mergeLegacyCv(_cvs, _legacyCv);

  /// Merges the library with the legacy mirror whenever either source
  /// changes; automatic selection waits until both have arrived.
  void _applyLibrary() {
    if (!ref.mounted) return;
    final library = _mergedLibrary;
    final selected = state.chosenCv;
    state = state.copyWith(
      library: library,
      defaultCvFile: _resolveDefaultCv(),
      // A CV removed from Profile while the screen is open falls back to the
      // default instead of sending a file that is no longer in the library.
      chosenCv: selected != null && library.any((cv) => isSameCv(cv, selected))
          ? selected
          : null,
    );
    _maybeAutoSelect();
    _maybeGenerate();
  }

  /// The default CV without the display-only `legacy` id: `defaultCvId`, then
  /// the legacy mirror, then the newest library entry.
  CvFile? _resolveDefaultCv() {
    if (_defaultCvId != null) {
      for (final cv in _cvs) {
        if (cv.id == _defaultCvId) return cv;
      }
    }
    if (_legacyCv != null) return _legacyCv;
    if (_cvs.isNotEmpty) {
      return _cvs.reduce(
        (newest, cv) => cv.uploadedAt.isAfter(newest.uploadedAt) ? cv : newest,
      );
    }
    return null;
  }

  /// Runs `selectCv` once when there are at least two CVs to compare, so the
  /// application starts with the best match (G-33 item 8).
  void _maybeAutoSelect() {
    final listing = _listing;
    if (_autoSelectRequested ||
        _autoSelectResolved ||
        _cvChosenByStudent ||
        !_cvsLoaded ||
        !state.profileLoaded ||
        listing == null) {
      return;
    }
    final library = _mergedLibrary;
    if (library.length < 2) {
      _autoSelectResolved = true;
      _maybeGenerate();
      return;
    }
    _autoSelectRequested = true;
    unawaited(_autoSelect(listing, library));
  }

  /// `selectCv` in the background: the default stays selected until the
  /// server answers, and a failure never blocks applying.
  Future<void> _autoSelect(Internship listing, List<CvFile> library) async {
    final service = ref.read(cvSelectServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final internshipKey = listing.key;
    final defaultPath = _resolveDefaultCv()?.storagePath;

    if (!ref.mounted) return;
    state = state.copyWith(autoSelecting: true);
    try {
      final selection = await service.select(
        internshipKey: internshipKey,
        storagePaths: [for (final cv in library) cv.storagePath],
        defaultPath: defaultPath,
      );
      if (!ref.mounted) return;

      _autoSelectResolved = true;
      final changed = _cvChosenByStudent;
      CvFile? match;
      for (final cv in library) {
        if (cv.storagePath == selection.storagePath) {
          match = cv;
          break;
        }
      }
      final usesDefault =
          defaultPath != null && selection.storagePath == defaultPath;
      state = state.copyWith(
        autoSelecting: false,
        autoSelection: selection,
        chosenCv: changed || match == null ? state.chosenCv : match,
      );
      unawaited(
        analytics.logEvent('cv_auto_select', <String, Object>{
          'internship_id': internshipKey,
          'cv_count': library.length,
          'best_percent': selection.percent,
          'used_default': usesDefault ? 1 : 0,
          'user_changed': changed ? 1 : 0,
          'result': changed || match == null
              ? (match == null ? 'failed' : 'default')
              : 'selected',
        }),
      );
    } on AppException {
      if (!ref.mounted) return;
      _autoSelectResolved = true;
      // The default CV stays; applying still works.
      state = state.copyWith(autoSelecting: false);
      unawaited(
        analytics.logEvent('cv_auto_select', <String, Object>{
          'internship_id': internshipKey,
          'cv_count': library.length,
          'best_percent': 0,
          'used_default': 1,
          'user_changed': _cvChosenByStudent ? 1 : 0,
          'result': 'failed',
        }),
      );
    }
    _maybeGenerate();
  }

  /// Drafts once when the listing, the profile and automatic CV selection
  /// have resolved, so a rebuild or a later snapshot does not spend another
  /// model call.
  void _maybeGenerate() {
    if (_autoGenerateStarted ||
        _listing == null ||
        !state.profileLoaded ||
        !_autoSelectResolved) {
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
