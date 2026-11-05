import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/state/view_state.dart';
import '../../../core/utils/skill_match.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/cv_match_result.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/cv_match_viewmodel.dart';

/// The advisory CV Match Check step: the score, matched / missing requirements
/// and one suggestion per gap.
///
/// Unlike the Validate CV gate this never blocks: `Continue` is enabled in
/// every state, including while the check runs and after it fails (G-24).
class CvMatchStep extends ConsumerStatefulWidget {
  const CvMatchStep({
    super.key,
    required this.storagePath,
    required this.internshipKey,
    required this.onContinue,
    this.onEdit,
  });

  /// `cvs/{uid}/…` object path of the CV selected on the Apply Form.
  final String storagePath;

  /// The internship the student is applying to.
  final String internshipKey;

  /// Always available: moves on to the next Apply step.
  final VoidCallback onContinue;

  /// Returns to the Apply Form, which owns the Edit skills / Replace CV
  /// sheets, so the session is rebuilt with the changes.
  final VoidCallback? onEdit;

  @override
  ConsumerState<CvMatchStep> createState() => _CvMatchStepState();
}

class _CvMatchStepState extends ConsumerState<CvMatchStep> {
  ProviderSubscription<String?>? _authSubscription;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // The Apply flow is signed-in only; run once the uid is known instead of
    // racing the first auth event (same pattern as CvValidationStep).
    _authSubscription = ref.listenManual<String?>(currentUserIdProvider, (
      previous,
      next,
    ) {
      if (next != null && !_started) _start();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  void _start() {
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_run());
    });
  }

  Future<void> _run() {
    return ref
        .read(cvMatchViewModelProvider.notifier)
        .run(
          storagePath: widget.storagePath,
          internshipKey: widget.internshipKey,
        );
  }

  void _retry() => unawaited(_run());

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cvMatchViewModelProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (state) {
            ViewLoading<CvMatchResult>() ||
            ViewEmpty<CvMatchResult>() => const StateView.loading(
              message: 'Checking your CV against this internship…',
            ),
            ViewData<CvMatchResult>(:final data) => _MatchBody(result: data),
            ViewError<CvMatchResult>(:final error) => _ErrorPanel(
              message: error.message,
            ),
          },
          const SizedBox(height: AppSpacing.s24),
          if (state is ViewError<CvMatchResult>) ...[
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.secondary,
              icon: Symbols.refresh_rounded,
              expand: true,
              onPressed: _retry,
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          if (state is ViewData<CvMatchResult> && widget.onEdit != null) ...[
            AppButton(
              label: 'Edit skills',
              variant: AppButtonVariant.secondary,
              icon: Symbols.edit_rounded,
              expand: true,
              onPressed: widget.onEdit,
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          AppButton(
            label: 'Continue',
            expand: true,
            onPressed: widget.onContinue,
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'For this check, text from your CV is sent to our server.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MatchBody extends StatelessWidget {
  const _MatchBody({required this.result});

  final CvMatchResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(result.internshipTitle, style: textTheme.titleLarge),
          if (result.companyName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              result.companyName,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          if (!result.hasRequirements)
            _InfoPanel(
              icon: Symbols.info_rounded,
              title: 'Nothing to compare yet',
              message: result.summary,
            )
          else if (result.allMatched)
            _AllMatchedPanel(result: result)
          else ...[
            _SummaryCard(result: result),
            if (result.matched.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              Text('Matched', style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.s8),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final skill in result.matched)
                    _SkillChip(label: skill, matched: true),
                ],
              ),
            ],
            if (result.missing.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              Text('Gaps to review', style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.s8),
              for (final skill in result.missing) ...[
                _GapRow(skill: skill, suggestion: _suggestionFor(skill)),
                const SizedBox(height: AppSpacing.s12),
              ],
            ],
          ],
          if (result.niceToHave.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            Text('Nice to have', style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Optional: these are not gaps.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final skill in result.niceToHave)
                  AppTag(label: skill, size: AppTagSize.large),
              ],
            ),
          ],
          if (!result.cvReadable) ...[
            const SizedBox(height: AppSpacing.s16),
            _InfoPanel(
              icon: Symbols.description_rounded,
              title: 'We could not read your CV',
              message:
                  'This compares your Profile skills only. Continue, or go '
                  'back and replace the file with a text-based PDF.',
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          Text(
            'This check is a guide. You can continue even if something is '
            'missing.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String? _suggestionFor(String skill) {
    for (final suggestion in result.suggestions) {
      if (suggestion.skill.toLowerCase() == skill.toLowerCase()) {
        return suggestion.text;
      }
    }
    return null;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});

  final CvMatchResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppRadii.largeAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${result.percent}% match',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              _LevelBadge(level: result.level),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            '${result.matchedCount} of ${result.totalRequired} requirements '
            'matched',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.s8),
          LinearProgressIndicator(
            value: result.percent / 100,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            semanticsLabel: 'CV match',
            semanticsValue: '${result.percent}%',
          ),
          if (result.summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(result.summary, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _AllMatchedPanel extends StatelessWidget {
  const _AllMatchedPanel({required this.result});

  final CvMatchResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppRadii.largeAll,
      ),
      child: Column(
        children: [
          const Icon(
            Symbols.check_circle_rounded,
            size: AppSizes.icon,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Your CV covers every requirement',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            result.summary,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({required this.skill, this.suggestion});

  final String skill;
  final String? suggestion;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final suggestion = this.suggestion;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: ['$skill, missing', ?suggestion].join('. '),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Symbols.cancel_rounded,
            size: AppSizes.iconSmall,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill, style: textTheme.titleSmall),
                if (suggestion != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    suggestion,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.largeAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Symbols.error_rounded,
            size: AppSizes.icon,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('We could not check your CV', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.s4),
                Text(message, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadii.largeAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.s4),
                Text(message, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.matched});

  final String label;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final color = matched ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: matched ? '$label, you have this skill' : '$label, missing',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.smallAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              matched ? Symbols.check_rounded : Symbols.cancel_rounded,
              size: AppSizes.iconSmall,
              color: color,
            ),
            const SizedBox(width: AppSpacing.s4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final MatchLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.fullAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        level.label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.primary),
      ),
    );
  }
}
