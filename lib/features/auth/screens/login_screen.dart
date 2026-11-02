import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/login_viewmodel.dart';
import '../widgets/google_sign_in_button.dart';

/// Login, from the Login frame (G-03) with the differences in DC-18:
/// English copy (G-28), coming-soon Terms / Privacy links (G-31) and a
/// message box for sign-in errors.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static const String backgroundAsset = 'assets/images/login_background.jpg';

  /// Dark scrim over the photo, estimated from the frame (verify in Figma:
  /// G-07). It never drops below 65 %, which keeps the white text ≥ 4.5:1
  /// even over the white buildings.
  static final LinearGradient _scrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.textPrimary.withValues(alpha: 0.8),
      AppColors.textPrimary.withValues(alpha: 0.65),
      AppColors.textPrimary.withValues(alpha: 0.95),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final textTheme = Theme.of(context).textTheme;
    final error = state.error;

    // Headline, pitch, message and button sit 32 dp from the edges, as in
    // the frame; the legal line keeps the standard 16 dp so the longer
    // English sentence still fits on one line at 360 dp (DC-18).
    final signIn = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Start your IT career',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.related),
          Text(
            'Connecting tech students with hundreds of top internships.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: _OnScrim.muted),
          ),
          const SizedBox(height: AppSpacing.s32),
          if (error != null) ...[
            _SignInMessage(
              message: error is AppException
                  ? error.message
                  : 'We could not sign you in. Please try again.',
              // A cancelled picker is information, not a failure.
              isInfo: error is AppException && error.isCancelled,
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          GoogleSignInButton(
            isLoading: state.isLoading,
            onPressed: () =>
                ref.read(loginViewModelProvider.notifier).signInWithGoogle(),
          ),
        ],
      ),
    );

    // Light status-bar icons: the screen has no app bar and a dark photo.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.textPrimary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            DecoratedBox(decoration: BoxDecoration(gradient: _scrim)),
            SafeArea(
              child: LayoutBuilder(
                // Scrolls only when the screen is too short (small phones,
                // large font sizes); otherwise the Spacers place the content
                // as in the frame.
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.s32),
                          const _Wordmark(),
                          const Spacer(),
                          signIn,
                          const Spacer(),
                          const SizedBox(height: AppSpacing.s24),
                          const _LegalNotice(),
                          const SizedBox(height: AppSpacing.s8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text colors on the photo scrim: white, with the pitch and the legal line
/// dimmed as in the frame (verify in Figma: G-07). Both stay ≥ 4.5:1 on the
/// scrim behind them.
abstract final class _OnScrim {
  static final Color muted = AppColors.onPrimary.withValues(alpha: 0.9);
  static final Color subtle = AppColors.onPrimary.withValues(alpha: 0.7);
}

/// `Internly.` with the dot in `primary`, as in the frame.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall
        ?.copyWith(color: AppColors.onPrimary);
    return Semantics(
      label: 'Internly',
      header: true,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: 'Internly',
          children: [
            TextSpan(
              text: '.',
              style: style?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

/// Sign-in error or cancelled-picker info (Lab 3 §6). Shown on a white box
/// because `error` text straight on the scrim is below 4.5:1 (DC-18).
class _SignInMessage extends StatelessWidget {
  const _SignInMessage({required this.message, required this.isInfo});

  final String message;
  final bool isInfo;

  @override
  Widget build(BuildContext context) {
    final color = isInfo ? AppColors.textSecondary : AppColors.error;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.mediumAll,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isInfo ? Symbols.info_rounded : Symbols.error_rounded,
                color: color,
                size: AppSizes.iconSmall,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "By continuing, you agree to our Terms & Privacy." Neither document
/// exists yet, so both links say so instead of opening an empty page (G-31).
class _LegalNotice extends StatelessWidget {
  const _LegalNotice();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: _OnScrim.subtle);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('By continuing, you agree to our', style: style),
        // Kept together so a narrow screen wraps before "Terms", never
        // inside the links.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LegalLink(
              label: 'Terms',
              message: 'The terms of use are coming soon.',
            ),
            Text('& ', style: style),
            const _LegalLink(
              label: 'Privacy',
              message: 'The privacy policy is coming soon.',
              trailing: '.',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.message,
    this.trailing = '',
  });

  final String label;
  final String message;

  /// Punctuation drawn inside the button, not underlined, so the 48 dp
  /// target does not push it away from the word.
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.onPrimary,
    );
    // The 48 dp minimum width also gives the spaces around the words.
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onPrimary,
        textStyle: style,
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(AppSizes.minTouchTarget),
      ),
      onPressed: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message))),
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            if (trailing.isNotEmpty)
              TextSpan(
                text: trailing,
                style: const TextStyle(decoration: TextDecoration.none),
              ),
          ],
        ),
        semanticsLabel: label,
      ),
    );
  }
}
