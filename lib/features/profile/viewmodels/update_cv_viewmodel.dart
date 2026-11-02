import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/user_profile.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/document_picker_service.dart';
import '../../../services/file_storage_service.dart';
import '../../../services/user_profile_service.dart';

@immutable
class UpdateCvState {
  const UpdateCvState({this.selected, this.progress, this.error});

  /// The PDF chosen for upload, until it is stored or removed.
  final PickedDocument? selected;

  /// Upload progress from 0 to 1; non-null only while uploading.
  final double? progress;

  /// Why the last pick or upload failed. A cancelled upload is information,
  /// not a failure ([AppException.isCancelled]).
  final AppException? error;

  bool get isUploading => progress != null;
}

final updateCvViewModelProvider =
    NotifierProvider.autoDispose<UpdateCvViewModel, UpdateCvState>(
      UpdateCvViewModel.new,
    );

/// Update CV sheet: choose a PDF, upload it to `cvs/{uid}/…` and make it
/// the default CV in `users/{uid}`.
class UpdateCvViewModel extends Notifier<UpdateCvState> {
  bool _picking = false;

  @override
  UpdateCvState build() => const UpdateCvState();

  Future<void> choose() async {
    if (_picking || state.isUploading) return;
    final picker = ref.read(documentPickerServiceProvider);

    _picking = true;
    try {
      final document = await picker.pickPdf();
      if (!ref.mounted || document == null) return;
      // Checked before uploading so the student can pick another file
      // straight away; FileStorageService and storage.rules check it again.
      state = document.sizeBytes > maxUploadBytes
          ? UpdateCvState(selected: state.selected, error: _tooLarge)
          : UpdateCvState(selected: document);
    } on AppException catch (error) {
      if (ref.mounted) {
        state = UpdateCvState(selected: state.selected, error: error);
      }
    } finally {
      _picking = false;
    }
  }

  void remove() {
    if (state.isUploading) return;
    state = const UpdateCvState();
  }

  /// Uploads the selected PDF and saves it as the default CV. Returns `true`
  /// once both steps succeed, so the View can close the sheet.
  Future<bool> upload() async {
    final document = state.selected;
    if (document == null || state.isUploading) return false;
    final storage = ref.read(fileStorageServiceProvider);
    final profiles = ref.read(userProfileServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return false;

    state = UpdateCvState(selected: document, progress: 0);
    try {
      final uploaded = await storage.uploadPdf(
        folder: StorageFolder.cvs,
        fileName: document.name,
        bytes: document.bytes,
        onProgress: (progress) {
          if (ref.mounted && state.isUploading) {
            state = UpdateCvState(selected: document, progress: progress);
          }
        },
      );
      await profiles.updateCv(
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
      if (ref.mounted) state = const UpdateCvState();
      return true;
    } on AppException catch (error) {
      if (ref.mounted) state = UpdateCvState(selected: document, error: error);
      return false;
    }
  }

  static const AppException _tooLarge = AppException(
    AppErrorKind.invalidInput,
    'The file must be a PDF of at most 10 MB.',
  );
}
