import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/notifications/viewmodels/notification_center_viewmodel.dart';
import 'package:internly/models/app_notification.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/notification_service.dart';

import '../../helpers/fakes.dart';
import '../../helpers/notification_fakes.dart';

void main() {
  late FakeNotificationService notifications;
  late FakeAnalyticsService analytics;

  setUp(() {
    notifications = FakeNotificationService();
    analytics = FakeAnalyticsService();
  });

  tearDown(() async {
    await notifications.dispose();
  });

  ProviderContainer build({String? uid = 'uid-123'}) {
    final container = ProviderContainer.test(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifications),
        analyticsServiceProvider.overrideWithValue(analytics),
        currentUserIdProvider.overrideWithValue(uid),
      ],
    );
    container.listen(notificationCenterViewModelProvider, (_, _) {});
    return container;
  }

  ViewState<List<AppNotification>> read(ProviderContainer container) =>
      container.read(notificationCenterViewModelProvider);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('loads the history and logs unread_count once', () async {
    notifications.results = [
      testNotification('1', title: 'New application'),
      testNotification('2', isRead: true),
    ];
    final container = build();
    expect(read(container), isA<ViewLoading<List<AppNotification>>>());

    await settle();
    await settle();

    final data = read(container) as ViewData<List<AppNotification>>;
    expect(data.data.map((item) => item.id), ['1', '2']);
    expect(analytics.parameters['notification_center_open'], {
      'unread_count': 1,
    });
    expect(
      analytics.events.where((event) => event == 'notification_center_open'),
      hasLength(1),
    );

    // A later snapshot updates the list but does not log the open again.
    notifications.emit([testNotification('3')]);
    await settle();
    await settle();
    expect(read(container), isA<ViewData<List<AppNotification>>>());
    expect(
      analytics.events.where((event) => event == 'notification_center_open'),
      hasLength(1),
    );
  });

  test('an empty history is ViewEmpty and logs unread_count 0', () async {
    final container = build();
    await settle();
    await settle();

    expect(read(container), isA<ViewEmpty<List<AppNotification>>>());
    expect(analytics.parameters['notification_center_open'], {
      'unread_count': 0,
    });
  });

  test('a failed load explains why and Retry subscribes again', () async {
    final error = const AppException(
      AppErrorKind.network,
      'We could not load your notifications.',
    );
    notifications.watchError = error;
    final container = build();
    await settle();
    await settle();

    final failed = read(container) as ViewError<List<AppNotification>>;
    expect(failed.error.message, error.message);
    expect(analytics.events, isNot(contains('notification_center_open')));

    notifications
      ..watchError = null
      ..results = [testNotification('1')];
    container.read(notificationCenterViewModelProvider.notifier).retry();
    await settle();
    await settle();

    expect(read(container), isA<ViewData<List<AppNotification>>>());
    expect(notifications.watchCalls, 2);
  });

  test('signed out shows ViewEmpty and reads nothing', () async {
    notifications.results = [testNotification('1')];
    final container = build(uid: null);
    await settle();

    expect(read(container), isA<ViewEmpty<List<AppNotification>>>());
    expect(notifications.watchCalls, 0);
    expect(analytics.events, isEmpty);
  });

  test('markRead writes through the service, once', () async {
    notifications.results = [testNotification('1')];
    final container = build();
    await settle();
    await settle();

    final viewModel = container.read(
      notificationCenterViewModelProvider.notifier,
    );
    final unread =
        (read(container) as ViewData<List<AppNotification>>).data.first;
    await viewModel.markRead(unread);
    await viewModel.markRead(unread);

    expect(notifications.readIds, ['1']);
  });
}
