import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// One Profile section: a heading row (icon, `type/title`, optional text
/// action) above a card. DESIGN.md §11 Profile: "Group content into clear
/// cards or sections" so students can update one area at a time.
///
/// Kept in the Profile feature: the Lab 2 "Section Header" component has no
/// Figma spec yet (G-16).
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailingText,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.padded = true,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// Short note on the right, e.g. "1 active file".
  final String? trailingText;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// `false` for content that brings its own padding (list rows).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizes.iconSmall,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: textTheme.titleMedium),
                ),
              ),
              if (trailingText case final text?)
                Text(text, style: textTheme.bodyMedium),
              if (actionLabel case final label?)
                AppButton(
                  label: label,
                  icon: actionIcon,
                  variant: AppButtonVariant.text,
                  onPressed: onAction,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: padded
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}

/// Secondary-text line used for "not set yet" content inside a section.
class ProfileHint extends StatelessWidget {
  const ProfileHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}
