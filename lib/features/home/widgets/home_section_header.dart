import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';

/// Home section heading (`type/heading/medium`) with an optional text action
/// on the right, e.g. "Recommended for you" · "View all".
///
/// Kept in the Home feature: the Lab 2 "Section Header" component has no
/// Figma spec yet (G-16), so it is not a shared component.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
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
