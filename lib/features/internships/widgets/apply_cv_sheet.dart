import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/cv_upload_sheet.dart';
import '../viewmodels/apply_form_viewmodel.dart';

/// The Profile Upload / Update CV sheet on the Apply Form (DC-26): the same
/// layout and actions, but the uploaded CV is used for this internship only
/// and the Profile default stays as it is.
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
          ? 'From your Profile'
          : 'For this internship',
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
