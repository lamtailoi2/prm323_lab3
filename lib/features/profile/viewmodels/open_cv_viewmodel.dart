import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/user_profile.dart';
import '../../../services/external_link_service.dart';

/// Opens the default CV in the device's PDF viewer or browser. The View
/// shows a failure as a SnackBar.
final openCvViewModelProvider =
    NotifierProvider.autoDispose<OpenCvViewModel, AsyncValue<void>>(
      OpenCvViewModel.new,
    );

class OpenCvViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> open(CvFile cv) async {
    if (state.isLoading) return;
    final links = ref.read(externalLinkServiceProvider);

    state = const AsyncLoading();
    try {
      await links.open(Uri.parse(cv.url));
      if (ref.mounted) state = const AsyncData(null);
    } on AppException catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
    }
  }
}
