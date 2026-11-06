import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/display_format.dart';
import '../../../models/app_notification.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// One row of the Notification Center: icon, title, up to two lines of body,
/// arrival time and an unread dot.
///
/// The dot is never the only unread signal: the tile's Semantics label also
/// says "Unread", and the title uses the stronger weight.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final body = notification.body;
    return Semantics(
      button: true,
      label: [
        notification.title,
        if (body.isNotEmpty) body,
        notification.isUnread ? 'Unread' : 'Read',
        formatRelativeTime(notification.receivedAt),
      ].join('. '),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSizes.minTouchTarget - AppSpacing.s8,
                  height: AppSizes.minTouchTarget - AppSpacing.s8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppRadii.mediumAll,
                  ),
                  child: const Icon(
                    Symbols.notifications_rounded,
                    size: AppSizes.iconSmall,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: notification.isUnread
                                  ? textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    )
                                  : textTheme.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (notification.isUnread) ...[
                            const SizedBox(width: AppSpacing.s8),
                            Container(
                              margin: const EdgeInsets.only(top: AppSpacing.s4),
                              width: AppSpacing.s8,
                              height: AppSpacing.s8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          body,
                          style: textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        formatRelativeTime(notification.receivedAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
