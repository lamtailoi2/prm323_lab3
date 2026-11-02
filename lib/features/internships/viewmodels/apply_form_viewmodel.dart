import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/skill_match.dart';
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

/// Apply Form (Flow 1 pre-submit: Check CV → Upload / Select CV → Pre-submit
/// Complete).
@immutable
class ApplyFormState {
  const ApplyFormState({
    this.internship = const ViewLoading(),
    this.profileLoaded = false,
    this.profileCv,
    this.uploadedCv,
    this.pending,
    this.progress,
    this.uploadError,
    this.missingCv = false,
    this.skillMatch,
  });

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
    ViewState<Internship>? internship,
    bool? profileLoaded,
    Object? profileCv = _keep,
    Object? uploadedCv = _keep,
    Object? pending = _keep,
    Object? progress = _keep,
    Object? uploadError = _keep,
    bool? missingCv,
    Object? skillMatch = _keep,
  }) {
    return ApplyFormState(
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
    );
  }
}

final applyFormViewModelProvider = NotifierProvider.autoDispose
    .family<ApplyFormViewModel, ApplyFormState, ApplyFormArgs>(
      ApplyFormViewModel.new,
    );

class ApplyFormViewModel extends Notifier<ApplyFormState> {
  ApplyFormViewModel(this.args);

  final ApplyFormArgs args;

  StreamSubscription<Internship?>? _subscription;

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

    final profile = uid == null
        ? null
        : profiles
              .watchProfile(uid)
              .listen(
                _onProfile,
                // Without the profile the student can still upload a CV.
                onError: (Object _, StackTrace _) {
                  if (ref.mounted) {
                    state = state.copyWith(profileLoaded: true);
                  }
                },
              );
    ref.onDispose(() {
      unawaited(profile?.cancel());
      unawaited(_subscription?.cancel());
    });

    _subscribe(service);
    _logStart();
    return ApplyFormState(profileLoaded: uid == null);
  }

  /// Listens to the listing again after a load error.
  void retry() {
    if (state.internship.isLoading) return;
    final service = ref.read(internshipServiceProvider);
    _resolved = false;
    state = state.copyWith(internship: const ViewLoading());
    _subscribe(service);
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

  /// `Continue to review`: the CV to hand to the review step (Pre-submit
  /// Complete), or `null` when there is none yet and the CV section must say
  /// so.
  ApplyCv? continueToReview() {
    if (state.isUploading) return null;
    final cv = state.cv;
    if (cv == null) state = state.copyWith(missingCv: true);
    return cv;
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
    state = state.copyWith(
      profileLoaded: true,
      profileCv: profile?.cv,
      missingCv: profile?.cv == null && state.missingCv,
      skillMatch: _matchFor(switch (state.internship) {
        ViewData(:final data) => data,
        _ => null,
      }),
    );
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
