import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// White bordered section of Internship Detail ("About the role",
/// "Requirements", …) and the Apply Form ("CV / Resume") with the Figma
/// Section Header on top.
class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.spacing = AppSpacing.s12,
    this.isRequired = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  /// Adds the red ` *` of the Apply Form, read as "required".
  final bool isRequired;

  /// Optional action at the end of the header row, e.g. `Edit` on Application
  /// Review or `Add skill` on the Apply Form.
  final Widget? action;

  /// Gap between the header and each child (Figma: 8 for "About the role",
  /// 12 for the other sections).
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.largeAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppSizes.iconSmall,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: title,
                      children: [
                        if (isRequired)
                          const TextSpan(
                            text: ' *',
                            semanticsLabel: ', required',
                            style: TextStyle(color: AppColors.error),
                          ),
                      ],
                    ),
                    style: textTheme.titleMedium,
                  ),
                ),
                ?action,
              ],
            ),
          ),
          for (final child in children) ...[SizedBox(height: spacing), child],
        ],
      ),
    );
  }
}

/// Figma "Meta Tile": icon + caption label + value (Key facts grid).
class DetailMetaTile extends StatelessWidget {
  const DetailMetaTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadii.smallAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSizes.iconSmall, color: AppColors.primary),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              value,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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

/// Square company logo with the initials as fallback (Figma "Logo").
class DetailCompanyLogo extends StatelessWidget {
  const DetailCompanyLogo({
    super.key,
    required this.companyName,
    required this.size,
    this.url,
  });

  final String companyName;
  final double size;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.primaryContainer,
      child: Text(
        initialsOf(companyName),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.primary),
      ),
    );
    final link = url;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadii.mediumAll,
        child: link == null
            ? fallback
            : Image.network(
                link,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => fallback,
              ),
      ),
    );
  }

  /// First letters of the first two words, e.g. "FPT Software" → "FS".
  static String initialsOf(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final initials = words.map((word) => word.characters.first).join();
    return initials.toUpperCase();
  }
}

/// Figma "Info Banner / Applied" (`Tone=Success`) at the top of Internship
/// Detail when the student already tracks an application for the listing.
class DetailAppliedBanner extends StatelessWidget {
  const DetailAppliedBanner({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.mediumAll,
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Symbols.check_circle_rounded,
              size: AppSizes.icon,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
