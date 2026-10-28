import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import 'cv_file_tile.dart';

/// Opens a Profile bottom sheet above the bottom navigation, as in the Lab 2
/// Edit Skills, Update Preferences and Update CV frames.
Future<void> showProfileSheet(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: builder,
  );
}

/// Shared layout of the Profile sheets: header (icon, title, subtitle,
/// close), scrolling content, and a sticky footer with one primary action
/// and `Cancel`.
class ProfileSheet extends StatelessWidget {
  const ProfileSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    required this.children,
    this.icon,
    this.primaryIcon,
    this.isLoading = false,
    this.error,
    this.showCancel = true,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final String primaryLabel;
  final IconData? primaryIcon;

  /// `null` disables the primary action (e.g. no file chosen yet).
  final VoidCallback? onPrimary;
  final bool isLoading;

  /// Shown above the footer buttons, next to the action that failed.
  final AppException? error;

  /// `false` for pickers that apply each choice at once and only need
  /// `Done`.
  final bool showCancel;
  final List<Widget> children;

  /// Share of the screen height a sheet may cover (Lab 2 sheets: ~85–90 %).
  static const double _maxHeightFactor = 0.9;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;
    final keyboard = media.viewInsets.bottom;
    void close() => Navigator.of(context).pop();

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (media.size.height * _maxHeightFactor - keyboard).clamp(
            0,
            double.infinity,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.s4,
                AppSpacing.s12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon case final icon?) ...[
                    ExcludeSemantics(child: FileTileIcon(icon: icon)),
                    const SizedBox(width: AppSpacing.s12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title, style: textTheme.titleLarge),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(subtitle, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Symbols.close_rounded),
                    onPressed: close,
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.s12,
                AppSpacing.screenHorizontal,
                AppSpacing.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error case final error?) ...[
                    FormMessage(
                      message: error.message,
                      isInfo: error.isCancelled,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                  AppButton(
                    label: primaryLabel,
                    icon: primaryIcon,
                    isLoading: isLoading,
                    expand: true,
                    onPressed: onPrimary,
                  ),
                  if (showCancel) ...[
                    const SizedBox(height: AppSpacing.s4),
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.text,
                      expand: true,
                      onPressed: close,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline message row: error (error icon and color) or information
/// (info icon, secondary text). Meaning never relies on color alone.
class FormMessage extends StatelessWidget {
  const FormMessage({super.key, required this.message, this.isInfo = false});

  final String message;
  final bool isInfo;

  @override
  Widget build(BuildContext context) {
    final color = isInfo ? AppColors.textSecondary : AppColors.error;
    return Semantics(
      liveRegion: true,
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
    );
  }
}

/// Filter Chip as drawn in the Lab 2 Profile sheets: 44 dp tall like the
/// Profile tags (design owner, 2026-10-28); a selected chip keeps the check
/// and adds a primary outline; [showAddIcon] puts a "+" on unselected chips
/// (Edit Skills suggestions).
class SheetChip extends StatelessWidget {
  const SheetChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.showAddIcon = false,
    this.compact = false,
    this.showCheckmark = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final bool showAddIcon;

  /// 36 dp tall instead of 44 dp (Update preferences "Quick select").
  final bool compact;

  /// `false` where the outline alone marks the choice and the selected
  /// value is also shown in a field (Quick select fills Location).
  final bool showCheckmark;

  /// Outline of selected and removable chips. Material adds it to the chip
  /// height, so [padding] takes it back off.
  static const double outlineWidth = 1;

  /// Padding that makes an outlined chip 44 dp tall (20 dp label + 12 dp
  /// above and below, outline included), matching `AppSizes.tagLarge`; the
  /// tap target stays 48 dp.
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
    vertical: AppSpacing.s12 - outlineWidth,
  );

  /// Same, for a 36 dp chip (8 dp above and below the label).
  static const EdgeInsets compactPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
    vertical: AppSpacing.s8 - outlineWidth,
  );

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: showCheckmark,
      avatar: showAddIcon && !selected
          ? const Icon(
              Symbols.add_rounded,
              size: AppSizes.iconSmall,
              color: AppColors.textSecondary,
            )
          : null,
      // Unselected chips keep a transparent outline, so selecting a chip
      // does not change its height.
      side: BorderSide(
        color: selected ? AppColors.primary : Colors.transparent,
        width: outlineWidth,
      ),
      padding: compact ? compactPadding : padding,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Section heading inside a sheet, as in the Lab 2 sheets: an uppercase
/// label with a helper line below it.
class SheetGroupHeader extends StatelessWidget {
  const SheetGroupHeader({super.key, required this.title, this.helper});

  final String title;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              semanticsLabel: title,
              style: textTheme.labelLarge,
            ),
          ),
          if (helper case final helper?)
            Text(helper, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
