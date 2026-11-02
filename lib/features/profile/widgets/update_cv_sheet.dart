import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/cv_upload_sheet.dart';
import '../../../models/user_profile.dart';
import '../viewmodels/update_cv_viewmodel.dart';

/// Update CV sheet of Profile: replaces the default CV in `users/{uid}`.
class UpdateCvSheet extends ConsumerWidget {
  const UpdateCvSheet({super.key, required this.current});

  /// The default CV being replaced; `null` for a first upload.
  final CvFile? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateCvViewModelProvider);
    final viewModel = ref.read(updateCvViewModelProvider.notifier);
    return CvUploadSheet(
      subtitle: current != null
          ? 'Replace your default internship resume'
          : 'Add the CV you want to use for applications',
      current: current,
      currentBadge: 'Active default',
      selectedName: state.selected?.name,
      selectedSizeBytes: state.selected?.sizeBytes,
      progress: state.progress,
      error: state.error,
      onChoose: viewModel.choose,
      onRemove: viewModel.remove,
      onPrimary: () async {
        if (await viewModel.upload() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
