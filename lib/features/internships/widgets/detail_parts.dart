import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// Figma "Bullet Item": a primary bullet and wrapping body text.
class DetailBulletItem extends StatelessWidget {
  const DetailBulletItem(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            '•',
            style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(child: Text(text, style: textTheme.bodyMedium)),
      ],
    );
  }
}

/// Figma "Benefit Item": a check icon and a label.
class DetailBenefitItem extends StatelessWidget {
  const DetailBenefitItem(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Symbols.check_circle_rounded,
          size: AppSizes.iconSmall,
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    );
  }
}

/// Body text cut to [collapsedLines] with a `Show more` / `Show less`
/// toggle (Figma "Internship Detail" and "Internship Detail – Expanded").
///
/// The expanded flag is UI-only state, so it stays in the widget.
class DetailExpandableText extends StatefulWidget {
  const DetailExpandableText(this.text, {super.key, this.collapsedLines = 4});

  final String text;
  final int collapsedLines;

  @override
  State<DetailExpandableText> createState() => _DetailExpandableTextState();
}

class _DetailExpandableTextState extends State<DetailExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : widget.collapsedLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (overflows)
              AppButton(
                label: _expanded ? 'Show less' : 'Show more',
                variant: AppButtonVariant.text,
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
          ],
        );
      },
    );
  }
}

/// Benefit items, the first [visibleCount] by default, with
/// `Show all N benefits` / `Show fewer` (Figma "What you will get").
class DetailBenefitList extends StatefulWidget {
  const DetailBenefitList(this.items, {super.key, this.visibleCount = 3});

  final List<String> items;
  final int visibleCount;

  @override
  State<DetailBenefitList> createState() => _DetailBenefitListState();
}

class _DetailBenefitListState extends State<DetailBenefitList> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final items = _showAll
        ? widget.items
        : widget.items.take(widget.visibleCount).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s8),
          DetailBenefitItem(items[i]),
        ],
        if (widget.items.length > widget.visibleCount) ...[
          const SizedBox(height: AppSpacing.s4),
          AppButton(
            label: _showAll
                ? 'Show fewer'
                : 'Show all ${widget.items.length} benefits',
            variant: AppButtonVariant.text,
            onPressed: () => setState(() => _showAll = !_showAll),
          ),
        ],
      ],
    );
  }
}
