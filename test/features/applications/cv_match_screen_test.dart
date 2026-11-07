import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/features/applications/screens/cv_match_screen.dart';
import 'package:internly/features/internships/models/apply_session.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/cv_match_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

const _job = 'job-1';

ApplySession _session() {
  return ApplySession(
    cv: ApplyCv(
      CvFile(
        fileName: 'Profile_CV.pdf',
        url: 'https://storage.example/cvs/profile.pdf',
        storagePath: 'cvs/uid-123/profile.pdf',
        sizeBytes: 420 * 1024,
        uploadedAt: DateTime(2026, 10, 14),
      ),
      CvSource.profile,
    ),
    startedAt: DateTime(2026, 11, 6, 9),
    email: 'student@example.com',
    details: const ProfileDetails(fullName: 'Minh Nguyen'),
    skills: const <String>['Flutter'],
    introduction: 'I build Flutter apps.',
  );
}

Future<GoRouter> _pumpScreen(
  WidgetTester tester, {
  required FakeCvMatchService match,
  ApplySession? session,
}) async {
  setScreenSize(tester);
  final router = GoRouter(
    initialLocation: '/home/internships/$_job/apply',
    routes: [
      GoRoute(
        path: '/home/internships/:jobKey/apply',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push(
                '/home/internships/$_job/apply/match',
                extra: session,
              ),
              child: const Text('Compose application'),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'match',
            builder: (context, state) => CvMatchScreen(
              internshipKey: state.pathParameters['jobKey']!,
              source: 'home',
              session: state.extra is ApplySession
                  ? state.extra as ApplySession
                  : null,
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(testUser.uid),
        cvMatchServiceProvider.overrideWithValue(match),
        analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Compose application'));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('without a session it explains where to start', (tester) async {
    await _pumpScreen(tester, match: FakeCvMatchService());
    await tester.pumpAndSettle();

    expect(find.text('CV match'), findsOneWidget);
    expect(find.text('Choose a CV first'), findsOneWidget);
    expect(find.text('Back to apply'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('Continue returns to the compose screen', (tester) async {
    final match = FakeCvMatchService();
    await _pumpScreen(tester, match: match, session: _session());
    await tester.pumpAndSettle();

    expect(find.text('50% match'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Compose application'), findsOneWidget);
    expect(find.text('CV match'), findsNothing);
  });

  testWidgets('the App Bar back button is present', (tester) async {
    await _pumpScreen(tester, match: FakeCvMatchService(), session: _session());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
  });
}
