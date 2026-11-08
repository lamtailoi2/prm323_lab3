import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../models/user_profile.dart';
import '../../../services/analytics_service.dart';
import '../../../services/application_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/document_picker_service.dart';
import '../../../services/file_storage_service.dart';
import '../../../services/user_profile_service.dart';
import 'profile_viewmodel.dart';

enum CvLibraryAction { add, setDefault, remove }

/// State of the Profile CV library actions (G-33).
@immutable
class CvLibraryState {
  const CvLibraryState({
    this.pending,
    this.progress,
    this.error,
    this.action,
    this.notice,
  });

  /// The PDF chosen in the Add CV sheet, until it is stored or removed.
  final PickedDocument? pending;

  /// Upload progress from 0 to 1; non-null only while uploading.
  final double? progress;

  /// Why the last action failed; a cancelled upload is information, not a
  /// failure ([AppException.isCancelled]).
  final AppException? error;

  /// The action in flight, so the row shows its own spinner.
  final CvLibraryAction? action;

  /// A message to show after success, e.g. that a submitted application kept
  /// its copy of the removed file.
  final String? notice;

  bool get isUploading => progress != null;
  bool get isBusy => action != null || progress != null;
}

final cvLibraryViewModelProvider =
    NotifierProvider.autoDispose<CvLibraryViewModel, CvLibraryState>(
      CvLibraryViewModel.new,
    );

/// Profile CV library: add a CV, mark one as default, remove one.
class CvLibraryViewModel extends Notifier<CvLibraryState> {
  bool _picking = false;
  String? _notice;

  @override
  CvLibraryState build() => const CvLibraryState();

  Future<void> choose() async {
    if (_picking || state.isBusy) return;
    final picker = ref.read(documentPickerServiceProvider);

    _picking = true;
    try {
      final document = await picker.pickPdf();
      if (!ref.mounted || document == null) return;
      // Checked before uploading so the student can pick another file
      // straight away; FileStorageService and storage.rules check it again.
      state = document.sizeBytes > maxUploadBytes
          ? CvLibraryState(pending: state.pending, error: _tooLarge)
          : CvLibraryState(pending: document);
    } on AppException catch (error) {
      if (ref.mounted) {
        state = CvLibraryState(pending: state.pending, error: error);
      }
    } finally {
      _picking = false;
    }
  }

  void removeSelected() {
    if (state.isBusy) return;
    state = const CvLibraryState();
  }

  /// Uploads the selected PDF and adds it to the library. Returns `true`
  /// once it is stored, so the View can close the sheet.
  Future<bool> upload() async {
    final document = state.pending;
    if (document == null || state.isBusy) return false;
    final storage = ref.read(fileStorageServiceProvider);
    final profiles = ref.read(userProfileServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return false;
    final previousCount = _cvCount;

    state = CvLibraryState(
      pending: document,
      progress: 0,
      action: CvLibraryAction.add,
    );
    try {
      final uploaded = await storage.uploadPdf(
        folder: StorageFolder.cvs,
        fileName: document.name,
        bytes: document.bytes,
        onProgress: (progress) {
          if (ref.mounted && state.isUploading) {
            state = CvLibraryState(
              pending: document,
              progress: progress,
              action: CvLibraryAction.add,
            );
          }
        },
      );
      await profiles.addCv(
        uid,
        CvFile(
          fileName: uploaded.fileName,
          url: uploaded.url,
          storagePath: uploaded.storagePath,
          sizeBytes: uploaded.sizeBytes,
          uploadedAt: uploaded.uploadedAt,
        ),
      );
      await analytics.logEvent('cv_upload', {
        'source': 'profile',
        'file_size_kb': (uploaded.sizeBytes / 1024).ceil(),
      });
      await analytics.logEvent('cv_library_change', {
        'action': 'add',
        'cv_count': previousCount + 1,
        'kept_file': 0,
      });
      if (ref.mounted) state = const CvLibraryState();
      return true;
    } on AppException catch (error) {
      if (ref.mounted) {
        state = CvLibraryState(pending: document, error: error);
      }
      return false;
    }
  }

  /// Marks [cv] as the default for applications.
  Future<bool> setDefault(CvFile cv) async {
    if (state.isBusy) return false;
    final id = cv.id;
    final profiles = ref.read(userProfileServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    if (id == null || uid == null) return false;

    state = const CvLibraryState(action: CvLibraryAction.setDefault);
    try {
      await profiles.setDefaultCv(uid, id);
      await analytics.logEvent('cv_library_change', {
        'action': 'set_default',
        'cv_count': _cvCount,
        'kept_file': 0,
      });
      if (ref.mounted) state = const CvLibraryState();
      return true;
    } on AppException catch (error) {
      if (ref.mounted) {
        state = CvLibraryState(error: error, action: null);
      }
      return false;
    }
  }

  /// Removes [cv] from the library. A file attached to a submitted
  /// application stays in Cloud Storage, because the application preview
  /// links to it.
  Future<bool> remove(CvFile cv) async {
    if (state.isBusy) return false;
    final id = cv.id;
    final profiles = ref.read(userProfileServiceProvider);
    final applications = ref.read(applicationServiceProvider);
    final storage = ref.read(fileStorageServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    if (id == null || uid == null) return false;
    final previousCount = _cvCount;

    state = const CvLibraryState(action: CvLibraryAction.remove);
    try {
      final referenced = (await applications.cvStoragePaths()).contains(
        cv.storagePath,
      );
      await profiles.removeCv(uid, id);
      if (!referenced) {
        try {
          await storage.deletePdf(cv.storagePath);
        } on AppException {
          // The entry is already gone; an orphaned file is reported by the
          // retention gap (CR-17) instead of failing the removal.
        }
      }
      await analytics.logEvent('cv_library_change', {
        'action': 'remove',
        'cv_count': previousCount > 0 ? previousCount - 1 : 0,
        'kept_file': referenced ? 1 : 0,
      });
      if (ref.mounted) {
        _notice = referenced ? _keptForApplication : null;
        state = CvLibraryState(notice: _notice);
      }
      return true;
    } on AppException catch (error) {
      if (ref.mounted) {
        state = CvLibraryState(error: error, action: null);
      }
      return false;
    }
  }

  /// The success notice shown once, or `null`.
  String? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  int get _cvCount => switch (ref.read(profileViewModelProvider)) {
    ViewData<ProfileOverview>(:final data) => data.library.length,
    _ => 0,
  };

  static const String _keptForApplication =
      'This CV is attached to a submitted application. It was removed from '
      'your library but kept for that application.';

  static const AppException _tooLarge = AppException(
    AppErrorKind.invalidInput,
    'The file must be a PDF of at most 10 MB.',
  );
}
