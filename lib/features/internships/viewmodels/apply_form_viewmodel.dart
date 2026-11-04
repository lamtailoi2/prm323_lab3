import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/skill_match.dart';
import '../../../core/utils/validators.dart';
import '../../../models/internship.dart';
import '../../../models/user_profile.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/document_picker_service.dart';
import '../../../services/external_link_service.dart';
import '../../../services/file_storage_service.dart';
import '../../../services/internship_service.dart';
import '../../../services/remote_config_service.dart';
import '../../../services/user_profile_service.dart';
import '../../saved/viewmodels/saved_providers.dart';

/// Which listing the student applies to and the tab its Detail was opened
/// from (`home`, `search` or `saved`), sent with `apply_start`
/// (docs/analytics-plan.md row 8).
typedef ApplyFormArgs = ({String internshipKey, String source});

/// Where the CV for this application comes from; becomes `cv_source` of
/// `application_create` in the next step.
enum CvSource { profile, uploaded }

/// The CV the student will apply with.
@immutable
class ApplyCv {
  const ApplyCv(this.file, this.source);

  final CvFile file;
  final CvSource source;
}

/// Text the student types on the Apply Form; university, year of study and
/// the CV live in [ApplyFormState] because they come from pickers.
typedef ApplyFormValues = ({
  String fullName,
  String email,
  String phone,
  String introduction,
});

/// Validation messages shown under the personal information fields; `null`
/// when the value is valid.
@immutable
class ApplyFieldErrors {
  const ApplyFieldErrors({
    this.fullName,
    this.phone,
    this.university,
    this.yearOfStudy,
  });

  final String? fullName;
  final String? phone;
  final String? university;
  final String? yearOfStudy;

  bool get isEmpty =>
      fullName == null &&
      phone == null &&
      university == null &&
      yearOfStudy == null;
}

/// What the Apply Form hands to Validate CV and Review: the CV, the details
/// and introduction the student is sending, and when the form opened
/// (`apply_start`), so Review can log `application_create.duration_sec`
/// (docs/analytics-plan.md row 10).
@immutable
class ApplySession {
  const ApplySession({
    required this.cv,
    required this.startedAt,
    required this.email,
    required this.details,
    required this.skills,
    required this.introduction,
  });

  final ApplyCv cv;
  final DateTime startedAt;

  /// The Google address shown on the form; stored with the application.
  final String email;

  /// `fullName`, `phone`, `university` and `yearOfStudy` as shown on the
  /// form.
  final ProfileDetails details;

  /// Skills sent with the application (the Profile skills at submit time).
  final List<String> skills;

  /// `Short introduction`, written for this application only.
  final String introduction;
}

/// Apply Form (Flow 1 pre-submit: Check CV → Upload / Select CV → Pre-submit
/// Complete).
@immutable
class ApplyFormState {
  const ApplyFormState({
    required this.startedAt,
    this.internship = const ViewLoading(),
    this.profileLoaded = false,
    this.profileCv,
    this.uploadedCv,
    this.pending,
    this.progress,
    this.uploadError,
    this.missingCv = false,
    this.skillMatch,
    this.profileError,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.university,
    this.yearOfStudy,
    this.introduction = '',
    this.profileSkills = const <String>[],
    this.errors = const ApplyFieldErrors(),
  });

  /// When the form opened, i.e. when `apply_start` was logged, so the review
  /// step can report `application_create.duration_sec`
  /// (docs/analytics-plan.md row 10).
  final DateTime startedAt;

  final ViewState<Internship> internship;

  /// `false` until the profile arrives (or fails), so the CV section waits
  /// instead of asking a student who has a CV to upload one.
  final bool profileLoaded;

  /// The default CV in `users/{uid}`.
  final CvFile? profileCv;

  /// A CV uploaded for this internship only; the Profile default is left as
  /// it is, so each application can use a different CV (DC-26).
  final CvFile? uploadedCv;

  /// The PDF being uploaded, kept after a failure so `Retry` sends it again.
  final PickedDocument? pending;

  /// Upload progress from 0 to 1; non-null only while uploading.
  final double? progress;
  final AppException? uploadError;

  /// `Continue to review` was tapped without a CV.
  final bool missingCv;

  /// Profile skills against the listing's, as on Internship Detail, so the
  /// student can check the CV covers them before sending it; `null` hides
  /// the line (Remote Config `cv_match_enabled` off, no known skill in the
  /// listing, or the profile not loaded).
  final SkillMatch? skillMatch;

  /// The profile (and so its CV) could not be loaded; the CV section says
  /// so with `Retry` instead of looking like "no CV yet" (CR-18).
  final AppException? profileError;

  /// Personal information, prefilled once from the Profile and then edited
  /// on the form.
  final String fullName;

  /// The Google address (read-only on the form), sent with the application.
  final String email;
  final String phone;
  final String? university;

  /// 1 for first-year students; `null` until the student picks one.
  final int? yearOfStudy;

  /// `Short introduction`, kept for this application only.
  final String introduction;

  /// Profile skills shown in the Skills section; the sheet edits the
  /// Profile, so this follows the live stream.
  final List<String> profileSkills;

  /// Messages under the personal information fields, after `Continue`.
  final ApplyFieldErrors errors;

  bool get isUploading => progress != null;

  ApplyCv? get cv {
    if (uploadedCv case final file?) return ApplyCv(file, CvSource.uploaded);
    if (profileCv case final file?) return ApplyCv(file, CvSource.profile);
    return null;
  }

  /// Sending the same file again helps after a dropped connection, not for
  /// a file that is not a PDF or is too large.
  bool get canRetry =>
      pending != null && uploadError?.kind != AppErrorKind.invalidInput;

  static const Object _keep = Object();

  ApplyFormState copyWith({
    DateTime? startedAt,
    ViewState<Internship>? internship,
    bool? profileLoaded,
    Object? profileCv = _keep,
    Object? uploadedCv = _keep,
    Object? pending = _keep,
    Object? progress = _keep,
    Object? uploadError = _keep,
    bool? missingCv,
    Object? skillMatch = _keep,
    Object? profileError = _keep,
    String? fullName,
    String? email,
    String? phone,
    Object? university = _keep,
    Object? yearOfStudy = _keep,
    String? introduction,
    List<String>? profileSkills,
    ApplyFieldErrors? errors,
  }) {
    return ApplyFormState(
      startedAt: startedAt ?? this.startedAt,
      internship: internship ?? this.internship,
      profileLoaded: profileLoaded ?? this.profileLoaded,
      profileCv: identical(profileCv, _keep)
          ? this.profileCv
          : profileCv as CvFile?,
      uploadedCv: identical(uploadedCv, _keep)
          ? this.uploadedCv
          : uploadedCv as CvFile?,
      pending: identical(pending, _keep)
          ? this.pending
          : pending as PickedDocument?,
      progress: identical(progress, _keep)
          ? this.progress
          : progress as double?,
      uploadError: identical(uploadError, _keep)
          ? this.uploadError
          : uploadError as AppException?,
      missingCv: missingCv ?? this.missingCv,
      skillMatch: identical(skillMatch, _keep)
          ? this.skillMatch
          : skillMatch as SkillMatch?,
      profileError: identical(profileError, _keep)
          ? this.profileError
          : profileError as AppException?,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      university: identical(university, _keep)
          ? this.university
          : university as String?,
      yearOfStudy: identical(yearOfStudy, _keep)
          ? this.yearOfStudy
          : yearOfStudy as int?,
      introduction: introduction ?? this.introduction,
      profileSkills: profileSkills ?? this.profileSkills,
      errors: errors ?? this.errors,
    );
  }
}

final applyFormViewModelProvider = NotifierProvider.autoDispose
    .family<ApplyFormViewModel, ApplyFormState, ApplyFormArgs>(
      ApplyFormViewModel.new,
    );

class ApplyFormViewModel extends Notifier<ApplyFormState> {
  ApplyFormViewModel(this.args);

  /// Longest accepted full name, as on Edit profile.
  static const int maxFullNameLength = 80;

  final ApplyFormArgs args;

  StreamSubscription<Internship?>? _subscription;
  StreamSubscription<UserProfile?>? _profileSubscription;

  /// `false` until the first snapshot of the listing arrives.
  bool _resolved = false;
  Internship? _listing;

  /// A saved listing that left the shared pool still opens, as on Detail
  /// (G-25 #5).
  Map<String, Internship> _savedCopies = const <String, Internship>{};

  /// `null` until the profile loads (or when it fails).
  List<String>? _profileSkills;
  bool _picking = false;
  bool _startLogged = false;

  /// The Profile prefill happened, so a later snapshot cannot overwrite what
  /// the student typed on the form.
  bool _fieldsSeeded = false;

  /// When the form opened, which is when `apply_start` is logged. Kept on
  /// the ViewModel, not in the state, so a rebuild for another account does
  /// not restart the clock.
  final DateTime _startedAt = DateTime.now();

  @override
  ApplyFormState build() {
    final service = ref.watch(internshipServiceProvider);
    // User-scoped (AGENTS.md rule 11): another account drops this CV.
    final uid = ref.watch(currentUserIdProvider);
    final profiles = ref.watch(userProfileServiceProvider);
    ref.watch(remoteConfigServiceProvider);
    _resolved = false;
    _listing = null;
    _profileSkills = null;

    ref.listen(savedInternshipsProvider, (previous, next) {
      _savedCopies = {
        for (final internship in next.asData?.value ?? const <Internship>[])
          internship.key: internship,
      };
      if (_resolved && _listing == null) _emitListing();
    }, fireImmediately: true);

    _subscribeProfile(profiles, uid);
    ref.onDispose(() {
      unawaited(_profileSubscription?.cancel());
      unawaited(_subscription?.cancel());
    });

    _subscribe(service);
    _logStart();
    return ApplyFormState(startedAt: _startedAt, profileLoaded: uid == null);
  }

  /// Listens to the listing again after a load error.
  void retry() {
    if (state.internship.isLoading) return;
    final service = ref.read(internshipServiceProvider);
    _resolved = false;
    state = state.copyWith(internship: const ViewLoading());
    _subscribe(service);
  }

  /// `Retry` after the profile failed to load.
  void retryProfile() {
    if (state.profileError == null) return;
    state = state.copyWith(profileLoaded: false, profileError: null);
    _subscribeProfile(
      ref.read(userProfileServiceProvider),
      ref.read(currentUserIdProvider),
    );
  }

  void _subscribeProfile(UserProfileService profiles, String? uid) {
    unawaited(_profileSubscription?.cancel());
    if (uid == null) return;
    _profileSubscription = profiles
        .watchProfile(uid)
        .listen(
          _onProfile,
          // The student can still upload a CV; the section shows the error
          // with Retry (CR-18).
          onError: (Object error, StackTrace _) {
            if (!ref.mounted) return;
            state = state.copyWith(
              profileLoaded: true,
              profileError: error is AppException
                  ? error
                  : AppException(
                      AppErrorKind.unknown,
                      'We could not load your Profile CV. Try again.',
                      cause: error,
                    ),
            );
          },
        );
  }

  /// `Choose file` in the CV sheet: picks a PDF to upload for this
  /// internship, as the Profile Update CV sheet does.
  Future<void> chooseCv() async {
    if (_picking || state.isUploading) return;
    final picker = ref.read(documentPickerServiceProvider);

    _picking = true;
    try {
      final document = await picker.pickPdf();
      if (!ref.mounted || document == null) return;
      // Checked before uploading so the student can pick another file
      // straight away; FileStorageService and storage.rules check it again.
      state = document.sizeBytes > maxUploadBytes
          ? state.copyWith(uploadError: _tooLarge)
          : state.copyWith(pending: document, uploadError: null);
    } on AppException catch (error) {
      if (ref.mounted && !error.isCancelled) {
        state = state.copyWith(uploadError: error);
      }
    } finally {
      _picking = false;
    }
  }

  /// `Remove` in the CV sheet.
  void removeSelected() {
    if (state.isUploading) return;
    state = state.copyWith(pending: null, uploadError: null);
  }

  /// `Upload CV` / `Update CV` in the CV sheet, and `Retry` on the form:
  /// uploads the selected PDF for this internship. Returns `true` once it is
  /// stored, so the View can close the sheet.
  Future<bool> uploadSelected() async {
    final document = state.pending;
    if (document == null || state.isUploading) return false;
    return _upload(
      document,
      ref.read(fileStorageServiceProvider),
      ref.read(analyticsServiceProvider),
    );
  }

  /// The CV sheet closed: a chosen file that was not uploaded, or a
  /// failure, is dropped, as closing the Profile sheet does. An upload that
  /// is still running finishes on the form.
  void closeCvSheet() {
    if (state.isUploading) return;
    state = state.copyWith(pending: null, uploadError: null);
  }

  /// `Use CV from Profile`: drops the failed or uploaded file.
  void useProfileCv() {
    if (state.isUploading) return;
    state = state.copyWith(uploadedCv: null, pending: null, uploadError: null);
  }

  /// `Preview`: opens the CV in the device's PDF viewer or browser. Returns
  /// the failure for the View to show.
  Future<AppException?> previewCv() async {
    final cv = state.cv;
    if (cv == null) return null;
    final links = ref.read(externalLinkServiceProvider);
    try {
      await links.open(Uri.parse(cv.file.url));
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  /// `Continue to review`: what Validate CV and Review need, or `null` when
  /// the form cannot continue (a CV is still uploading, a failed upload is
  /// unresolved, or there is no CV yet — the CV section then says so).
  ApplySession? continueToReview() {
    // A failed upload is resolved first (`Retry` or `Use CV from Profile`),
    // so the Profile CV is never sent in place of the chosen file (CR-15).
    if (state.isUploading || state.uploadError != null) return null;
    final cv = state.cv;
    if (cv == null) {
      state = state.copyWith(missingCv: true);
      return null;
    }
    return ApplySession(
      cv: cv,
      startedAt: _startedAt,
      email: state.email,
      details: ProfileDetails(
        fullName: state.fullName,
        phone: state.phone,
        university: state.university,
        yearOfStudy: state.yearOfStudy,
      ),
      skills: state.profileSkills,
      introduction: state.introduction,
    );
  }

  /// Checks the personal information the View passes from its text fields.
  /// `false` puts the messages in `state.errors`, so the fields show them.
  bool validateFields(ApplyFormValues values) {
    final fullName = values.fullName.trim();
    final email = values.email.trim();
    final phone = values.phone.trim();
    final introduction = values.introduction.trim();
    final errors = ApplyFieldErrors(
      fullName:
          Validators.required(
            fullName,
            message: 'Enter a full name to continue.',
          ) ??
          Validators.maxLength(
            fullName,
            maxFullNameLength,
            message: 'Use $maxFullNameLength characters or fewer.',
          ),
      phone:
          Validators.required(
            phone,
            message: 'Enter a phone number to continue.',
          ) ??
          Validators.phone(
            phone,
            message: 'Enter a valid phone number (10-11 digits).',
          ),
      university: state.university == null
          ? 'Select your university to continue.'
          : null,
      yearOfStudy: state.yearOfStudy == null
          ? 'Select your year of study to continue.'
          : null,
    );
    if (!errors.isEmpty) {
      state = state.copyWith(errors: errors);
      return false;
    }
    state = state.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      introduction: introduction,
      errors: const ApplyFieldErrors(),
    );
    return true;
  }

  /// `Select your university` in the picker sheet.
  void selectUniversity(String university) {
    state = state.copyWith(
      university: university,
      errors: ApplyFieldErrors(
        fullName: state.errors.fullName,
        phone: state.errors.phone,
        yearOfStudy: state.errors.yearOfStudy,
      ),
    );
  }

  /// `Year of study` in the picker sheet.
  void selectYearOfStudy(int year) {
    state = state.copyWith(
      yearOfStudy: year,
      errors: ApplyFieldErrors(
        fullName: state.errors.fullName,
        phone: state.errors.phone,
        university: state.errors.university,
      ),
    );
  }

  Future<bool> _upload(
    PickedDocument document,
    FileStorageService storage,
    AnalyticsService analytics,
  ) async {
    state = state.copyWith(pending: document, progress: 0.0, uploadError: null);
    try {
      final uploaded = await storage.uploadPdf(
        folder: StorageFolder.cvs,
        fileName: document.name,
        bytes: document.bytes,
        onProgress: (progress) {
          if (ref.mounted && state.isUploading) {
            state = state.copyWith(progress: progress);
          }
        },
      );
      await analytics.logEvent('cv_upload', {
        'source': 'apply_form',
        'file_size_kb': (uploaded.sizeBytes / 1024).ceil(),
      });
      if (!ref.mounted) return true;
      state = state.copyWith(
        uploadedCv: CvFile(
          fileName: uploaded.fileName,
          url: uploaded.url,
          storagePath: uploaded.storagePath,
          sizeBytes: uploaded.sizeBytes,
          uploadedAt: uploaded.uploadedAt,
        ),
        pending: null,
        progress: null,
        missingCv: false,
      );
      return true;
    } on AppException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(progress: null, uploadError: error);
      }
      return false;
    }
  }

  void _subscribe(InternshipService service) {
    unawaited(_subscription?.cancel());
    _subscription = service
        .watchByKey(args.internshipKey)
        .listen(_onListing, onError: _onListingError);
  }

  void _onListing(Internship? listing) {
    if (!ref.mounted) return;
    _resolved = true;
    _listing = listing;
    _emitListing();
  }

  void _onListingError(Object error, StackTrace stack) {
    if (!ref.mounted) return;
    state = state.copyWith(
      internship: ViewError(
        error is AppException
            ? error
            : AppException(
                AppErrorKind.unknown,
                'We could not load this internship. Try again in a moment.',
                cause: error,
              ),
      ),
    );
  }

  void _emitListing() {
    final internship = _listing ?? _savedCopies[args.internshipKey];
    state = state.copyWith(
      internship: internship == null ? const ViewEmpty() : ViewData(internship),
      skillMatch: _matchFor(internship),
    );
  }

  SkillMatch? _matchFor(Internship? internship) {
    final skills = _profileSkills;
    if (internship == null || skills == null) return null;
    final enabled = ref
        .read(remoteConfigServiceProvider)
        .getBool(RemoteConfigKeys.cvMatchEnabled);
    return enabled
        ? skillMatchFor(listingSkills: internship.skills, profileSkills: skills)
        : null;
  }

  void _onProfile(UserProfile? profile) {
    if (!ref.mounted) return;
    _profileSkills = profile?.skills ?? const <String>[];
    final details = profile?.details;
    var next = state.copyWith(
      profileLoaded: true,
      profileError: null,
      profileCv: profile?.cv,
      missingCv: profile?.cv == null && state.missingCv,
      skillMatch: _matchFor(switch (state.internship) {
        ViewData(:final data) => data,
        _ => null,
      }),
      profileSkills: _profileSkills,
    );
    // Prefill once from the Profile: later snapshots (or a sheet that edits
    // the Profile) must not overwrite what the student typed here.
    if (!_fieldsSeeded) {
      _fieldsSeeded = true;
      next = next.copyWith(
        fullName: details?.fullName ?? '',
        phone: details?.phone ?? '',
        university: details?.university,
        yearOfStudy: details?.yearOfStudy,
      );
    }
    state = next;
  }

  /// `apply_start`: once per opened form (`Apply now` tapped).
  void _logStart() {
    if (_startLogged) return;
    _startLogged = true;
    unawaited(
      ref.read(analyticsServiceProvider).logEvent('apply_start', {
        'internship_id': args.internshipKey,
        'source': args.source,
      }),
    );
  }

  static const AppException _tooLarge = AppException(
    AppErrorKind.invalidInput,
    'The file must be a PDF of at most 10 MB.',
  );
}
