import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../models/app_notification.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

final notificationCenterViewModelProvider =
    NotifierProvider.autoDispose<
      NotificationCenterViewModel,
      ViewState<List<AppNotification>>
    >(NotificationCenterViewModel.new);

/// Notification Center (G-04): the messages the client stored under
/// `users/{uid}/notifications` from every FCM delivery state, newest first.
class NotificationCenterViewModel
    extends Notifier<ViewState<List<AppNotification>>> {
  StreamSubscription<List<AppNotification>>? _subscription;
  bool _openLogged = false;

  /// IDs already written as read from this screen, so a double tap does not
  /// send a second write before the stream catches up.
  final Set<String> _markedRead = <String>{};

  @override
  ViewState<List<AppNotification>> build() {
    // User-scoped (AGENTS.md rule 11).
    final uid = ref.watch(currentUserIdProvider);
    final service = ref.watch(notificationServiceProvider);
    ref.onDispose(() => unawaited(_subscription?.cancel()));
    _openLogged = false;
    if (uid == null) return const ViewEmpty();
    _subscribe(service, uid);
    return const ViewLoading();
  }

  /// `Retry` after the history failed to load.
  void retry() {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    state = const ViewLoading();
    _subscribe(ref.read(notificationServiceProvider), uid);
  }

  /// Marks a tapped notification as read. The stream updates the list, so a
  /// failure only leaves the dot in place; it never blocks opening the item.
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead || !_markedRead.add(notification.id)) return;
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    try {
      await ref
          .read(notificationServiceProvider)
          .markRead(uid, notification.id);
    } on AppException catch (error) {
      // Allow a later tap to try again.
      _markedRead.remove(notification.id);
      debugPrint('Could not mark the notification read: ${error.message}');
    }
  }

  /// `Mark all as read`: clears every unread dot in one batch. The stream
  /// brings the read state back; a failure leaves the dots and lets a later
  /// tap try again.
  Future<void> markAllRead() async {
    final items = switch (state) {
      ViewData(:final data) => data,
      _ => const <AppNotification>[],
    };
    final ids = [
      for (final item in items)
        if (item.isUnread && !_markedRead.contains(item.id)) item.id,
    ];
    if (ids.isEmpty) return;
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    _markedRead.addAll(ids);
    try {
      await ref.read(notificationServiceProvider).markAllRead(uid, ids);
    } on AppException catch (error) {
      _markedRead.removeAll(ids);
      debugPrint('Could not mark the notifications read: ${error.message}');
    }
  }

  void _subscribe(NotificationService service, String uid) {
    unawaited(_subscription?.cancel());
    _subscription = service
        .watchNotifications(uid)
        .listen(
          (items) {
            if (!ref.mounted) return;
            _logOpen(items);
            state = ViewState.fromData(items, isEmpty: items.isEmpty);
          },
          onError: (Object error, StackTrace _) {
            if (!ref.mounted) return;
            state = ViewError(
              error is AppException
                  ? error
                  : AppException(
                      AppErrorKind.unknown,
                      'We could not load your notifications. Try again in a '
                      'moment.',
                      cause: error,
                    ),
            );
          },
        );
  }

  /// Logs `notification_center_open` once per opened screen
  /// (docs/analytics-plan.md row 15).
  void _logOpen(List<AppNotification> items) {
    if (_openLogged) return;
    _openLogged = true;
    unawaited(
      ref.read(analyticsServiceProvider).logEvent('notification_center_open', {
        'unread_count': items.where((item) => item.isUnread).length,
      }),
    );
  }
}
