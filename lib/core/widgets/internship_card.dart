import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import 'app_tag.dart';
import 'status_badge.dart';

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
    this.logoUrl,
    this.tags = const <String>[],
    this.allowanceText,
    this.postedText,
    this.isSaved = false,
    this.badge,
    this.isApplied = false,
    this.onTap,
    this.onSaveToggle,
    this.semanticsLabel,
  });

  /// Shown instead of the allowance when the listing does not state one
  /// (G-17, DC-10).
  static const String allowanceNotDisclosed = 'Not disclosed';

  /// Badge of a listing the student tracks in My Applications (Flow 2c:
  /// "In Search Results the card shows an `Applied` badge"), with the check
  /// icon so it does not rely on color alone.
  static const Widget _appliedBadge = StatusBadge(
    label: 'Applied',
    icon: Symbols.check_circle_rounded,
    color: AppColors.success,
  );

  final String title;
  final String companyName;
  final String? location;

  /// Company logo from SerpAPI's `thumbnail`; a neutral tile is shown when
  /// missing or when the image fails to load.
  final String? logoUrl;

  /// Display label, e.g. "Hybrid"; `null` when the listing does not say
  /// (DC-10) and the work-mode row is hidden.
  final String? workMode;
  final List<String> tags;

  /// e.g. a monthly allowance. Formatting is decided by the feature (G-17).
  final String? allowanceText;

  /// e.g. "2d ago".
  final String? postedText;
  final bool isSaved;

  /// Optional badge; [isApplied] shows the `Applied` one.
  final Widget? badge;

  /// The student tracks this listing in My Applications (Flow 2c): shows the
  /// `Applied` badge and says "Applied" in the card summary, which screen
  /// readers and ARTEMIS read (the visible details are excluded).
  final bool isApplied;
  final VoidCallback? onTap;

  /// Hides the save action when null.
  final VoidCallback? onSaveToggle;

  /// Overrides the generated accessibility summary of the card.
  final String? semanticsLabel;

  @override
  State<InternshipCard> createState() => _InternshipCardState();
}

class _InternshipCardState extends State<InternshipCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // One labeled node per card for screen readers and ARTEMIS (Lab 3 §7);
    // the visible texts are excluded so they are not announced twice. The
    // save button stays a separate, tappable node.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        button: widget.onTap != null,
        label: widget.semanticsLabel ?? _summary(),
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
                      ExcludeSemantics(
                        child: _CompanyLogo(url: widget.logoUrl),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExcludeSemantics(
                              child: Text(
                                widget.title,
                                style: textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            ExcludeSemantics(
                              child: Text(
                                widget.companyName,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onSaveToggle != null) _saveButton(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _details(textTheme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _details(TextTheme textTheme) {
    final badge =
        widget.badge ??
        (widget.isApplied ? InternshipCard._appliedBadge : null);
    return [
      Wrap(
        spacing: AppSpacing.s16,
        runSpacing: AppSpacing.s4,
        children: [
          if (widget.workMode case final workMode?)
            _Meta(icon: Symbols.work_rounded, text: workMode),
          if (widget.location case final location?)
            _Meta(icon: Symbols.location_on_rounded, text: location),
        ],
      ),
      if (widget.tags.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [for (final tag in widget.tags) AppTag(label: tag)],
        ),
      ],
      if (widget.allowanceText != null ||
          widget.postedText != null ||
          badge != null) ...[
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            if (widget.allowanceText case final allowance?)
              Expanded(
                child: Text(
                  allowance,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              const Spacer(),
            if (widget.postedText case final posted?) ...[
              Text(posted, style: textTheme.bodySmall),
            ],
            if (badge case final badge?) ...[
              const SizedBox(width: AppSpacing.s8),
              badge,
            ],
          ],
        ),
      ],
    ];
  }

  String _summary() {
    return [
      '${widget.title} at ${widget.companyName}',
      [widget.location, widget.workMode].whereType<String>().join(', '),
      if (widget.tags.isNotEmpty) 'Skills: ${widget.tags.join(', ')}',
      ?widget.allowanceText,
      ?widget.postedText,
      if (widget.isSaved) 'Saved',
      if (widget.isApplied) 'Applied',
    ].join('. ');
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

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSizes.companyLogo,
      child: ClipRRect(
        borderRadius: AppRadii.mediumAll,
        child: ColoredBox(
          color: AppColors.surfaceVariant,
          child: url == null
              ? const _LogoFallback()
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _LogoFallback(),
                ),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Symbols.business_center_rounded,
        size: AppSizes.iconSmall,
        color: AppColors.primary,
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
