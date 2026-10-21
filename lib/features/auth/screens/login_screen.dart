import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/login_viewmodel.dart';

/// Interim Login screen. Lab 2 has no Login design (docs/handoff-gaps.md
/// G-03); this layout only uses existing tokens and components and is
/// logged in docs/design-change-log.md (DC-01). The auth owner finalises it.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final textTheme = Theme.of(context).textTheme;
    final error = state.error;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('Internly', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Find, save and track internships that match your skills.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (error != null) ...[
                _ErrorMessage(
                  message: error is AppException
                      ? error.message
                      : 'We could not sign you in. Please try again.',
                ),
                const SizedBox(height: AppSpacing.s16),
              ],
              AppButton(
                label: 'Continue with Google',
                isLoading: state.isLoading,
                expand: true,
                onPressed: () => ref
                    .read(loginViewModelProvider.notifier)
                    .signInWithGoogle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Symbols.error_rounded,
            color: AppColors.error,
            size: AppSizes.iconSmall,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
