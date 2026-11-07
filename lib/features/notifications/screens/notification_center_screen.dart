import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/state/view_state.dart';
import '../../../core/utils/notification_target.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/app_notification.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/notification_center_viewmodel.dart';
import '../widgets/notification_tile.dart';

/// Notification Center (Lab 3 §7, G-04): the messages stored in
/// `users/{uid}/notifications`, with a read/unread state and a deep link per
/// message.
///
/// Opened from the bell in every app bar; Back returns to the tab the bell
/// was tapped on (the route sits above the shell).
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationCenterViewModelProvider);
    final viewModel = ref.read(notificationCenterViewModelProvider.notifier);

    return Scaffold(
      appBar: AppTopBar.back(
        title: 'Notifications',
        actions: [
          // Only while something is unread, so the action never does nothing.
          if (state case ViewData<List<AppNotification>>(:final data)
              when data.any((item) => item.isUnread))
            TextButton(
              onPressed: () => unawaited(viewModel.markAllRead()),
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: switch (state) {
        ViewLoading<List<AppNotification>>() => const _NotificationsSkeleton(),
        ViewEmpty<List<AppNotification>>() => StateView.empty(
          icon: Symbols.notifications_off_rounded,
          title: 'No notifications yet',
          message:
              'Updates about your internships and applications will appear '
              'here.',
        ),
        ViewError<List<AppNotification>>(:final error) => StateView.error(
          message: error.message,
          onRetry: viewModel.retry,
        ),
        ViewData<List<AppNotification>>(:final data) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.s16,
            AppSpacing.screenHorizontal,
            AppSpacing.s24,
          ),
          itemCount: data.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.s12),
          itemBuilder: (context, index) {
            final notification = data[index];
            return NotificationTile(
              notification: notification,
              onTap: () {
                unawaited(viewModel.markRead(notification));
                final target = notificationTarget(notification.route);
                if (target != null) context.push(target);
              },
            );
          },
        ),
      },
    );
  }
}

/// Rows with the shape of a notification, never a spinner or a blank screen
/// (design-system.md §2.9).
class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  static const int _count = 4;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Loading notifications',
      child: ExcludeSemantics(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.s16,
            AppSpacing.screenHorizontal,
            AppSpacing.s24,
          ),
          itemCount: _count,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s12),
            child: _NotificationSkeletonRow(),
          ),
        ),
      ),
    );
  }
}

class _NotificationSkeletonRow extends StatelessWidget {
  const _NotificationSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 40, height: 40),
            SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 16),
                  SizedBox(height: AppSpacing.s8),
                  FractionallySizedBox(
                    widthFactor: 0.85,
                    child: SkeletonBox(height: 14),
                  ),
                  SizedBox(height: AppSpacing.s8),
                  FractionallySizedBox(
                    widthFactor: 0.3,
                    child: SkeletonBox(height: 12),
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
