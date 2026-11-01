import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// App Bar component (Figma page 05 "App Bar / 2 specimens").
///
/// - [AppTopBar.main]: top-level destinations; large title, optional actions.
/// - [AppTopBar.back]: nested screens; back button, title, optional action.
///
/// Clean surface, no shadow. Back and actions each keep a 48 dp target.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar.main({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.leadingWidth,
  }) : _isMain = true,
       onBack = null;

  const AppTopBar.back({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
  }) : _isMain = false,
       leading = null,
       leadingWidth = null;

  final String title;
  final List<Widget>? actions;

  /// Optional leading slot for the main variant (e.g. a brand mark); the tab
  /// headers leave it empty and start at the normal text margin (DC-20).
  final Widget? leading;
  final double? leadingWidth;

  /// Overrides the default `Navigator.maybePop` for the back button.
  final VoidCallback? onBack;
  final bool _isMain;

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: leadingWidth,
      leading: _isMain
          ? leading
          : IconButton(
              icon: const Icon(Symbols.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: onBack ?? () => Navigator.maybePop(context),
            ),
      title: Text(title),
      titleSpacing: _isMain && leading != null
          ? AppSpacing.s8
          : NavigationToolbar.kMiddleSpacing,
      // Main titles use type/heading/large ("screen titles", Figma page 04);
      // verify against the Figma App Bar component (G-07).
      titleTextStyle: _isMain ? AppTypography.headingLarge : null,
      actions: [
        ...?actions,
        const SizedBox(width: AppSpacing.s4),
      ],
    );
  }
}
