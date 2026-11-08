import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/cv_upload_sheet.dart';
import '../viewmodels/cv_library_viewmodel.dart';

/// Add CV sheet of Profile: uploads a PDF and adds it to the library
/// (G-33). Unlike the old Update CV sheet, it does not replace anything.
class AddCvSheet extends ConsumerWidget {
  const AddCvSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cvLibraryViewModelProvider);
    final viewModel = ref.read(cvLibraryViewModelProvider.notifier);
    return CvUploadSheet(
      title: 'Add CV',
      subtitle: 'Add a CV to your library',
      current: null,
      currentBadge: 'Default',
      primaryLabel: 'Add CV',
      selectedName: state.pending?.name,
      selectedSizeBytes: state.pending?.sizeBytes,
      progress: state.progress,
      error: state.error,
      onChoose: viewModel.choose,
      onRemove: viewModel.removeSelected,
      onPrimary: () async {
        if (await viewModel.upload() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
