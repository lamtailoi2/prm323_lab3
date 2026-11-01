import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/app_user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import 'app_top_bar.dart';

/// Top bar of a bottom-navigation destination (Figma page 05, App Bar `.main`).
///
/// Every tab shows the same bar, so switching tabs only changes the title:
/// screen title → notification bell → profile avatar. The title repeats the
/// destination label from the bottom navigation.
///
/// There is no brand mark in the leading slot: the logo was dropped from the
  /// tab headers so the title starts at the normal 16 dp text margin (DC-20).
///
/// The bell is the interim entry point to the Notification Center (G-04,
/// G-13). That screen does not exist yet, so the bell says so instead of
/// pretending to open it.
class MainTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainTabAppBar({
    super.key,
    required this.title,
    required this.onProfile,
    this.user,
  });

  /// Screen title, identical to the bottom navigation label.
  final String title;

  /// Opens Profile; the avatar is the same entry point as the Profile tab.
  final VoidCallback onProfile;

  /// Signed-in student, for the avatar photo. Falls back to the person glyph.
  final AppUser? user;

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppTopBar.main(
      title: title,
      actions: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Symbols.notifications_rounded),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications are coming soon.')),
          ),
        ),
        _ProfileAction(user: user, onPressed: onProfile),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.user, required this.onPressed});

  final AppUser? user;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl;
    return IconButton(
      tooltip: 'Profile',
      onPressed: onPressed,
      icon: ClipOval(
        child: SizedBox.square(
          dimension: AppSizes.profileAvatar,
          child: ColoredBox(
            color: AppColors.primaryContainer,
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
      size: AppSizes.iconSmall,
      color: AppColors.primary,
    );
  }
}
