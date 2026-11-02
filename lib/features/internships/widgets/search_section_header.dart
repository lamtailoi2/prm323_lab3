import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';

/// Search section heading (`type/heading/medium`) with an optional text
/// action on the right, e.g. "Recent searches" · "Clear".
///
/// Kept in the Search feature: the Lab 2 "Section Header" component has no
/// Figma spec yet (G-16), so it is not a shared component (mirrors
/// `HomeSectionHeader`, which is scoped to Home for the same reason).
class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// e.g. "1 selected".
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(child: Text(title, style: textTheme.titleLarge)),
                if (subtitle case final subtitle?) ...[
                  const SizedBox(width: 8),
                  Text(subtitle, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
        if (actionLabel case final label?)
          AppButton(
            label: label,
            onPressed: onAction,
            variant: AppButtonVariant.text,
          ),
      ],
    );
  }
}
