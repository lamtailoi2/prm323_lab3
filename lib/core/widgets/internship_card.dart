import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import 'app_tag.dart';

/// Internship Card component (Figma page 05 "Internship Card / 3 specimens").
///
/// The same card is reused on Home, Search Results and Saved. It takes
/// display-ready strings so it stays independent of the data model; the
/// feature ViewModel formats allowance and dates.
///
/// States: default, pressed (reduced emphasis), saved (filled bookmark).
class InternshipCard extends StatefulWidget {
  const InternshipCard({
    super.key,
    required this.title,
    required this.companyName,
    required this.location,
    required this.workMode,
    this.tags = const <String>[],
    this.allowanceText,
    this.postedText,
    this.isSaved = false,
    this.badge,
    this.onTap,
    this.onSaveToggle,
  });

  final String title;
  final String companyName;
  final String location;

  /// Display label, e.g. "Hybrid".
  final String workMode;
  final List<String> tags;

  /// e.g. a monthly allowance. Formatting is decided by the feature (G-17).
  final String? allowanceText;

  /// e.g. "Posted 2 days ago".
  final String? postedText;
  final bool isSaved;

  /// Optional badge such as "Applied" (Flow 2c).
  final Widget? badge;
  final VoidCallback? onTap;

  /// Hides the save action when null.
  final VoidCallback? onSaveToggle;

  @override
  State<InternshipCard> createState() => _InternshipCardState();
}

class _InternshipCardState extends State<InternshipCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: AppRadii.largeAll,
        child: Opacity(
          opacity: _pressed ? AppTheme.pressedOpacity : 1,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onSaveToggle != null) _saveButton(),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(widget.companyName, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.s8),
                Wrap(
                  spacing: AppSpacing.s16,
                  runSpacing: AppSpacing.s4,
                  children: [
                    _Meta(
                      icon: Symbols.location_on_rounded,
                      text: widget.location,
                    ),
                    _Meta(icon: Symbols.work_rounded, text: widget.workMode),
                  ],
                ),
                if (widget.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (final tag in widget.tags) AppTag(label: tag),
                    ],
                  ),
                ],
                if (widget.allowanceText != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Text(widget.allowanceText!, style: textTheme.labelLarge),
                ],
                if (widget.postedText != null || widget.badge != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    children: [
                      if (widget.postedText != null)
                        Expanded(
                          child: Text(
                            widget.postedText!,
                            style: textTheme.bodySmall,
                          ),
                        )
                      else
                        const Spacer(),
                      ?widget.badge,
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    final saved = widget.isSaved;
    return SizedBox.square(
      dimension: AppSizes.minTouchTarget,
      child: IconButton(
        onPressed: widget.onSaveToggle,
        tooltip: saved ? 'Remove from saved' : 'Save',
        isSelected: saved,
        icon: Icon(
          Symbols.bookmark_rounded,
          fill: saved ? 1 : 0,
          color: saved ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.s4),
        Flexible(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
