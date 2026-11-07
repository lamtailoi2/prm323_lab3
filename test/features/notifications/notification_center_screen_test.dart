import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/utils/notification_target.dart';
import 'package:internly/features/notifications/screens/notification_center_screen.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/notification_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/notification_fakes.dart';
import '../../helpers/pump.dart';

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

  Future<void> pumpCenter(WidgetTester tester, {double width = 360}) async {
    setScreenSize(tester, width: width, height: 900);
    final router = GoRouter(
      initialLocation: notificationCenterPath,
      routes: [
        GoRoute(
          path: notificationCenterPath,
          builder: (context, state) => const NotificationCenterScreen(),
        ),
        GoRoute(
          path: '/applications/:jobKey',
          builder: (context, state) =>
              Text('Application ${state.pathParameters['jobKey']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(notifications),
          analyticsServiceProvider.overrideWithValue(analytics),
          currentUserIdProvider.overrideWithValue(testUser.uid),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }

  final page = [
    testNotification(
      '1',
      title: 'Application received',
      body: 'FPT Software received your application.',
      receivedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      route: '/applications/job-1',
    ),
    testNotification(
      '2',
      title: 'Interview scheduled',
      body: 'Your interview is on 24 Oct at 2:00 PM.',
      receivedAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  for (final width in checkWidths) {
    testWidgets('lists the history at $width dp', (tester) async {
      final semantics = tester.ensureSemantics();
      notifications.results = page;
      await pumpCenter(tester, width: width);
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Application received'), findsOneWidget);
      expect(
        find.text('FPT Software received your application.'),
        findsOneWidget,
      );
      expect(find.text('Interview scheduled'), findsOneWidget);
      expect(find.text('5 min ago'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);

      // Unread is never carried by the dot alone.
      expect(
        find.bySemanticsLabel(RegExp('Application received.*Unread')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Interview scheduled.*Read')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });
  }

  testWidgets('shows skeleton rows while loading', (tester) async {
    notifications.gate = Completer<void>();
    await pumpCenter(tester);
    await tester.pump();

    expect(find.bySemanticsLabel('Loading notifications'), findsOneWidget);
    expect(find.text('No notifications yet'), findsNothing);

    notifications.gate!.complete();
    notifications.gate = null;
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Loading notifications'), findsNothing);
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('an empty history explains what will appear', (tester) async {
    await pumpCenter(tester);
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(
      find.text(
        'Updates about your internships and applications will appear here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a failed load explains why and Retry recovers', (tester) async {
    notifications.watchError = const AppException(
      AppErrorKind.network,
      'We could not load your notifications. Try again in a moment.',
    );
    await pumpCenter(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('We could not load your notifications. Try again in a moment.'),
      findsOneWidget,
    );

    notifications
      ..watchError = null
      ..results = page;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Application received'), findsOneWidget);
    expect(notifications.watchCalls, 2);
  });

  testWidgets('tapping a notification marks it read and deep links', (
    tester,
  ) async {
    notifications.results = page;
    await pumpCenter(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Application received'));
    await tester.pumpAndSettle();

    expect(notifications.readIds, ['1']);
    expect(find.text('Application job-1'), findsOneWidget);
  });

  testWidgets('Mark all as read clears every unread notification', (
    tester,
  ) async {
    notifications.results = page;
    await pumpCenter(tester);
    await tester.pumpAndSettle();

    expect(find.text('Mark all as read'), findsOneWidget);
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();

    final unread = [
      for (final item in page)
        if (item.isUnread) item.id,
    ];
    expect(notifications.readIds, unread);
    expect(tester.takeException(), isNull);

    // The stream brings the read state back and the action disappears.
    notifications.emit([
      for (final item in page) testNotification(item.id, isRead: true),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Mark all as read'), findsNothing);
  });

  testWidgets('no unread notifications: no Mark all as read', (tester) async {
    notifications.results = [testNotification('1', isRead: true)];
    await pumpCenter(tester);
    await tester.pumpAndSettle();

    expect(find.text('Mark all as read'), findsNothing);
  });

  testWidgets('a notification without a route stays on the list', (
    tester,
  ) async {
    notifications.results = page;
    await pumpCenter(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interview scheduled'));
    await tester.pumpAndSettle();

    // Already read, so no write; no route, so no navigation.
    expect(notifications.readIds, isEmpty);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Application received'), findsOneWidget);
  });

  testWidgets('logs notification_center_open with the unread count', (
    tester,
  ) async {
    notifications.results = page;
    await pumpCenter(tester);
    await tester.pumpAndSettle();

    expect(analytics.parameters['notification_center_open'], {
      'unread_count': 1,
    });
  });
}
