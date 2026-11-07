import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/cv_upload_sheet.dart';
import '../viewmodels/apply_form_viewmodel.dart';

/// The CV sheet of the Apply Form (DC-26, G-33): the student's CV library
/// first (`from your library`, one tap), then the file picker. The chosen CV
/// is used for this internship only and the Profile default stays as it is.
class ApplyCvSheet extends ConsumerWidget {
  const ApplyCvSheet({super.key, required this.args});

  final ApplyFormArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(applyFormViewModelProvider(args));
    final viewModel = ref.read(applyFormViewModelProvider(args).notifier);
    final current = state.cv;
    return CvUploadSheet(
      subtitle: current != null
          ? 'Use a different CV for this internship'
          : 'Add the CV you want to send for this internship',
      current: current?.file,
      currentBadge: current?.source == CvSource.profile
          ? (state.chosenCv != null ? 'From your library' : 'From your Profile')
          : 'For this internship',
      library: state.library,
      selectedPath: current?.file.storagePath,
      onSelectLibrary: (cv) {
        viewModel.selectLibraryCv(cv);
        Navigator.of(context).pop();
      },
      selectedName: state.pending?.name,
      selectedSizeBytes: state.pending?.sizeBytes,
      progress: state.progress,
      error: state.uploadError,
      onChoose: viewModel.chooseCv,
      onRemove: viewModel.removeSelected,
      onPrimary: () async {
        if (await viewModel.uploadSelected() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
