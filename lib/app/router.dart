import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/notification_target.dart' show notificationCenterPath;
import '../features/applications/screens/application_detail_screen.dart';
import '../features/applications/screens/cv_match_screen.dart';
import '../features/applications/screens/cv_validation_screen.dart';
import '../features/applications/screens/my_applications_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/internships/models/apply_session.dart';
import '../features/internships/models/search_filter_criteria.dart';
import '../features/internships/screens/application_success_screen.dart';
import '../features/internships/screens/apply_compose_screen.dart';
import '../features/internships/screens/internship_detail_screen.dart';
import '../features/internships/screens/search_results_screen.dart';
import '../features/internships/screens/search_screen.dart';
import '../features/notifications/screens/notification_center_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/firebase_demo_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/report_export/screens/report_export_screen.dart';
import '../features/saved/screens/saved_screen.dart';
import '../models/app_user.dart';
import '../models/internship.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';
import 'app_shell.dart';

/// Route paths. Feature owners add nested routes under their tab branch
/// (e.g. `/search/results`, `/home/internships/:id`) and give every
/// [GoRoute] a `name`, which is logged as the analytics `screen_view`.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String search = '/search';
  static const String searchResults = '/search/results';
  static const String saved = '/saved';
  static const String applications = '/applications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String firebaseDemo = '/profile/firebase';
  static const String reportExport = '/profile/export';
  static const String notificationCenter = notificationCenterPath;

  /// Internship Detail opened from the [tab] it belongs to, e.g.
  /// `/home/internships/<key>`, so Back returns to that tab.
  static String internshipDetail(String tab, String internshipKey) =>
      '$tab/internships/$internshipKey';

  /// Apply Form above that Detail, e.g. `/home/internships/<key>/apply`, so
  /// Back (and Cancel in the next step) returns to the Detail.
  static String applyForm(String tab, String internshipKey) =>
      '${internshipDetail(tab, internshipKey)}/apply';

  /// Flow 2 after the form: CV Match → Validate CV → Review → Success, all
  /// above the Apply Form so Back walks the application back one step.
  static String applyMatch(String tab, String internshipKey) =>
      '${applyForm(tab, internshipKey)}/match';

  static String applyValidation(String tab, String internshipKey) =>
      '${applyForm(tab, internshipKey)}/validation';

  static String applicationSuccess(String tab, String internshipKey) =>
      '${applyForm(tab, internshipKey)}/success';

  /// One application, from My Applications or `View application`.
  static String applicationDetail(String internshipKey) =>
      '$applications/$internshipKey';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final routerProvider = Provider<GoRouter>((ref) {
  // Re-runs the redirect whenever the auth state changes, without
  // rebuilding the router.
  final authRefresh = ValueNotifier<int>(0);
  ref.listen(authStateChangesProvider, (_, _) => authRefresh.value++);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: authRefresh,
    redirect: (context, state) => authRedirect(
      auth: ref.read(authStateChangesProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          _tab(
            AppRoutes.home,
            'home',
            const HomeScreen(),
            routes: [_internshipDetail('home')],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: 'search',
                builder: (context, state) => const SearchScreen(),
                routes: [
                  GoRoute(
                    path: 'results',
                    name: 'search_results',
                    builder: (context, state) {
                      final query = state.uri.queryParameters['q'] ?? '';
                      final modeStr = state.uri.queryParameters['mode'];
                      final workMode = modeStr != null
                          ? WorkMode.values
                                .where((m) => m.name == modeStr)
                                .firstOrNull
                          : null;
                      final criteria = state.extra;
                      return SearchResultsScreen(
                        initialQuery: query,
                        initialWorkMode: workMode,
                        // Set by the Search tab's filter sheet.
                        initialCriteria: criteria is SearchFilterCriteria
                            ? criteria
                            : null,
                      );
                    },
                  ),
                  _internshipDetail('search'),
                ],
              ),
            ],
          ),
          _tab(
            AppRoutes.saved,
            'saved',
            const SavedScreen(),
            routes: [_internshipDetail('saved')],
          ),
          _tab(
            AppRoutes.applications,
            'my_applications',
            const MyApplicationsScreen(),
            routes: [
              GoRoute(
                path: ':jobKey',
                name: 'application_detail',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => ApplicationDetailScreen(
                  internshipKey: state.pathParameters['jobKey']!,
                ),
              ),
            ],
          ),
          _tab(
            AppRoutes.profile,
            'profile',
            const ProfileScreen(),
            routes: [
              // A form: shown above the shell, without bottom navigation.
              GoRoute(
                path: 'edit',
                name: 'edit_profile',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const EditProfileScreen(),
              ),
              // Lab 3 demo controls: Remote Config values and Crashlytics
              // tests (G-06). Above the shell like the other Profile tools.
              GoRoute(
                path: 'firebase',
                name: 'firebase_demo',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const FirebaseDemoScreen(),
              ),
              // Lab 3 "export and upload" (G-05): a PDF of the student's own
              // applications, above the shell like the other Profile tools.
              GoRoute(
                path: 'export',
                name: 'report_export',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const ReportExportScreen(),
              ),
              // The Notification Center opens above the shell, so Back
              // returns to the tab the bell was tapped on (G-04).
              GoRoute(
                path: 'notifications',
                name: 'notification_center',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const NotificationCenterScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  final analytics = ref.read(analyticsServiceProvider);
  final crashlytics = ref.read(crashlyticsServiceProvider);
  String? lastScreen;
  void trackScreen() {
    final config = router.routerDelegate.currentConfiguration;
    if (config.isEmpty) return;
    final name = config.last.route.name;
    if (name == null || name == 'splash' || name == lastScreen) return;
    lastScreen = name;
    analytics.logScreenView(screenName: name);
    // Custom key on every crash / non-fatal report (Lab 3 §6 Crashlytics).
    crashlytics.setCustomKey('last_screen', name);
  }

  router.routerDelegate.addListener(trackScreen);
  ref.onDispose(() {
    router.routerDelegate.removeListener(trackScreen);
    router.dispose();
    authRefresh.dispose();
  });
  return router;
});

StatefulShellBranch _tab(
  String path,
  String name,
  Widget screen, {
  List<RouteBase> routes = const <RouteBase>[],
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        name: name,
        builder: (context, state) => screen,
        routes: routes,
      ),
    ],
  );
}

/// Internship Detail under the [source] tab. Shown above the shell like the
/// Figma frame (bottom action bar, no bottom navigation); route names must be
/// unique, so each tab gets its own (`home_internship_detail`, …).
GoRoute _internshipDetail(String source) {
  return GoRoute(
    path: 'internships/:jobKey',
    name: '${source}_internship_detail',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => InternshipDetailScreen(
      internshipKey: state.pathParameters['jobKey']!,
      source: source,
    ),
    routes: [
      GoRoute(
        path: 'apply',
        name: '${source}_apply_email',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ApplyComposeScreen(
          internshipKey: state.pathParameters['jobKey']!,
          source: source,
        ),
        routes: [
          // Optional, advisory CV checks: they pop back to the compose
          // screen and never block sending the email.
          GoRoute(
            path: 'match',
            name: '${source}_cv_match',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => CvMatchScreen(
              internshipKey: state.pathParameters['jobKey']!,
              source: source,
              session: _applySession(state),
            ),
          ),
          GoRoute(
            path: 'validation',
            name: '${source}_cv_validation',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => CvValidationScreen(
              internshipKey: state.pathParameters['jobKey']!,
              source: source,
              session: _applySession(state),
            ),
          ),
          GoRoute(
            path: 'success',
            name: '${source}_application_success',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => ApplicationSuccessScreen(
              internshipTitle: _successArgs(state)?.internshipTitle,
              companyName: _successArgs(state)?.companyName,
              workMode: _successArgs(state)?.workMode,
              logoUrl: _successArgs(state)?.logoUrl,
              submittedAt: _successArgs(state)?.submittedAt,
            ),
          ),
        ],
      ),
    ],
  );
}

/// The CV and `apply_start` time handed from the compose screen to the
/// optional CV Match / Validate steps; `null` when opened directly.
ApplySession? _applySession(GoRouterState state) {
  final extra = state.extra;
  return extra is ApplySession ? extra : null;
}

/// The recap handed from the compose screen to Success.
ApplicationSuccessArgs? _successArgs(GoRouterState state) {
  final extra = state.extra;
  return extra is ApplicationSuccessArgs ? extra : null;
}

/// Authenticated routing: signed-out users can reach only Login; signed-in
/// users never see Login or Splash. Pure function so it is unit-testable.
@visibleForTesting
String? authRedirect({
  required AsyncValue<AppUser?> auth,
  required String location,
}) {
  final onSplash = location == AppRoutes.splash;
  final onLogin = location == AppRoutes.login;

  // First auth event not received yet.
  if (auth.isLoading && !auth.hasValue) {
    return onSplash ? null : AppRoutes.splash;
  }

  // An auth stream error is treated as signed out.
  final signedIn = !auth.hasError && auth.value != null;
  if (!signedIn) return onLogin ? null : AppRoutes.login;
  if (onLogin || onSplash) return AppRoutes.home;
  return null;
}
