import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

/// How many stored notifications are unread, for the badge on the bell in
/// every tab header. It reads the same history stream as the Notification
/// Center (the newest 50), so the badge and the list always agree, and it
/// drops to 0 on sign-out (AGENTS.md rule 11). A load error shows no badge:
/// the Notification Center itself shows the error with Retry.
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream<int>.value(0);
  return ref
      .watch(notificationServiceProvider)
      .watchNotifications(uid)
      .map((items) => items.where((item) => item.isUnread).length);
});
