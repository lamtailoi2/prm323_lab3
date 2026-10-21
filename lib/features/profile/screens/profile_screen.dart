import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';
import '../../../theme/app_spacing.dart';
import '../../auth/viewmodels/sign_out_viewmodel.dart';

/// Placeholder for the Profile tab. The feature owner replaces it following
/// docs/design/screen-spec.md (Profile). Sign out lives in the
/// "Settings & Support" section of the final design; it is exposed here so
/// the auth flow can be exercised from day one.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signOut = ref.watch(signOutViewModelProvider);

    ref.listen(signOutViewModelProvider, (_, next) {
      final error = next.error;
      if (error == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AppException
                ? error.message
                : 'We could not sign you out. Please try again.',
          ),
        ),
      );
    });

    return Scaffold(
      appBar: const AppTopBar.main(title: 'Profile'),
      body: Column(
        children: [
          const Expanded(
            child: StateView.empty(
              icon: Symbols.construction_rounded,
              title: 'Profile is not built yet',
              message: 'See screen-spec.md › Profile.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: AppButton(
              label: 'Sign out',
              icon: Symbols.logout_rounded,
              variant: AppButtonVariant.secondary,
              isLoading: signOut.isLoading,
              expand: true,
              onPressed: () =>
                  ref.read(signOutViewModelProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
    );
  }
}
