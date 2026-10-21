import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import 'app_button.dart';

/// The shared loading / empty / error view (Lab 2 handoff "a shared state
/// view widget"; Figma page 05 "Loading", "Empty State", "Error State").
///
/// - [StateView.loading]: labeled spinner for short waits. Content lists
///   should prefer card-shaped skeletons built in the feature.
/// - [StateView.empty]: 24 dp icon, short title and explanation, one useful
///   full-width action.
/// - [StateView.error]: meaningful icon, plain-language message that names
///   the likely cause, full-width `Retry`.
class StateView extends StatelessWidget {
  const StateView.loading({super.key, required String this.message})
    : _kind = _StateKind.loading,
      icon = null,
      title = null,
      actionLabel = null,
      onAction = null;

  const StateView.empty({
    super.key,
    required IconData this.icon,
    required String this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : _kind = _StateKind.empty;

  const StateView.error({
    super.key,
    required String this.message,
    this.icon = Symbols.error_rounded,
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
  }) : _kind = _StateKind.error,
       title = null,
       onAction = onRetry,
       actionLabel = onRetry == null ? null : retryLabel;

  final _StateKind _kind;
  final IconData? icon;
  final String? title;

  /// Loading label, empty-state explanation, or error message.
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Error icon size. Figma only fixes the empty-state icon (24 dp); the
  /// error specimen is visibly larger. Verify in Figma (G-07).
  static const double _errorIconSize = 32;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_kind == _StateKind.loading) {
      return Center(
        child: Semantics(
          liveRegion: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: AppSizes.iconSmall,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.s8),
              Flexible(child: Text(message!, style: textTheme.bodyMedium)),
            ],
          ),
        ),
      );
    }

    final isError = _kind == _StateKind.error;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isError ? _errorIconSize : AppSizes.icon,
              color: isError ? AppColors.error : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.s16),
            if (title != null) ...[
              Text(
                title!,
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
            if (message != null)
              Text(
                message!,
                style: isError ? textTheme.bodyLarge : textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.s24),
              AppButton(label: actionLabel!, onPressed: onAction, expand: true),
            ],
          ],
        ),
      ),
    );
  }
}

enum _StateKind { loading, empty, error }
