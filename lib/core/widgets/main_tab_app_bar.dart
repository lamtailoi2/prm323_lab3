import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/app_user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Top bar of a bottom-navigation destination (Figma "Tab Header v2",
/// section "Final UI v2 · All screens", DC-31).
///
/// A photo hero that runs behind the status bar, with a dark scrim so the
/// white text stays readable (banking-app reference: ACB / Sacombank). Home
/// passes [greeting] and shows the avatar, the greeting and the student's
/// name; the other tabs show their title, an optional one-line [summary],
/// and the avatar after the bell. The bottom [sheetOverlap] is painted as the rounded top of the
/// body, so the screen reads as a sheet laid over the photo.
///
/// The bell opens the Notification Center (G-04, G-13); every tab passes the
/// same callback so the entry point behaves identically.
class MainTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainTabAppBar({
    super.key,
    required this.title,
    required this.onNotifications,
    this.onProfile,
    this.user,
    this.greeting,
    this.summary,
  });

  /// The header photo. It is decoration only: replace the file to change it.
  static const String headerAsset = 'assets/images/tab_header.jpg';

  /// Height of the body sheet's rounded top, drawn inside the header.
  static const double sheetOverlap = AppSpacing.s24;

  /// Tab title; on Home, the student's name.
  final String title;

  /// Opens Profile from the Home avatar.
  final VoidCallback? onProfile;

  /// Opens the Notification Center.
  final VoidCallback onNotifications;

  /// Signed-in student, for the avatar photo. Falls back to the person glyph.
  final AppUser? user;

  /// Home only: time-of-day greeting above [title]; also shows the avatar.
  final String? greeting;

  /// Optional line under the title, built from data the tab already has.
  final String? summary;

  static double _lineHeight(TextStyle style) => style.fontSize! * style.height!;

  @override
  Size get preferredSize => Size.fromHeight(
    AppSpacing.s16 +
        AppSizes.minTouchTarget +
        (summary == null
            ? 0
            : AppSpacing.s4 + _lineHeight(AppTypography.bodySmall)) +
        AppSpacing.s24 +
        sheetOverlap,
  );

  @override
  Widget build(BuildContext context) {
    final summaryText = summary;
    final greetingText = greeting;
    // Content is pinned to the bottom, so larger system text grows upwards
    // into the top padding instead of overflowing the sheet.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Image.asset(
            headerAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: AppColors.primary),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.inverseSurface.withValues(alpha: 0.55),
                  AppColors.inverseSurface.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.s12,
            bottom: AppSpacing.s24 + sheetOverlap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (greetingText != null) ...[
                      _Avatar(user: user, onPressed: onProfile),
                      const SizedBox(width: AppSpacing.s12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (greetingText != null)
                            Text(
                              greetingText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          Semantics(header: true, child: _FittedTitle(title)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Notifications',
                      icon: const Icon(Symbols.notifications_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.onPrimary.withValues(
                          alpha: 0.2,
                        ),
                        foregroundColor: AppColors.onPrimary,
                      ),
                      onPressed: onNotifications,
                    ),
                    // The other tabs keep the avatar as their Profile entry
                    // point (DC-20); Profile itself passes no callback.
                    if (greetingText == null && onProfile != null) ...[
                      const SizedBox(width: AppSpacing.s4),
                      _Avatar(user: user, onPressed: onProfile),
                    ],
                  ],
                ),
                if (summaryText != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    summaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: sheetOverlap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.large),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.onPressed});

  final AppUser? user;
  final VoidCallback? onPressed;

  static const double _size = AppSizes.minTouchTarget - AppSpacing.s4;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl;
    return IconButton(
      tooltip: 'Profile',
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.onPrimary, width: 2),
        ),
        child: ClipOval(
          child: ColoredBox(
            color: AppColors.primary,
            child: photoUrl == null
                ? const _AvatarFallback()
                : Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _AvatarFallback(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Symbols.person_rounded,
      size: AppSizes.icon,
      color: AppColors.onPrimary,
    );
  }
}

/// [text] in the largest heading style that fits on one line:
/// `type/heading/large` (24) → `type/heading/medium` (20) → `type/title`
/// (18), and only then an ellipsis, so a long full name is not cut early
/// (DC-31).
class _FittedTitle extends StatelessWidget {
  const _FittedTitle(this.text);

  final String text;

  static const List<TextStyle> _steps = [
    AppTypography.headingLarge,
    AppTypography.headingMedium,
    AppTypography.title,
  ];

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        var style = _steps.last;
        for (final candidate in _steps) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: candidate),
            maxLines: 1,
            textDirection: direction,
            textScaler: scaler,
          )..layout(maxWidth: constraints.maxWidth);
          final fits = !painter.didExceedMaxLines;
          painter.dispose();
          if (fits) {
            style = candidate;
            break;
          }
        }
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(color: AppColors.onPrimary),
        );
      },
    );
  }
}
