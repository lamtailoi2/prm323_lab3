import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/applications/screens/my_applications_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/internships/models/search_filter_criteria.dart';
import '../features/internships/screens/apply_confirm_screen.dart';
import '../features/internships/screens/apply_form_screen.dart';
import '../features/internships/screens/apply_validate_screen.dart';
import '../features/internships/screens/internship_detail_screen.dart';
import '../features/internships/screens/search_results_screen.dart';
import '../features/internships/screens/search_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
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

  /// Internship Detail opened from the [tab] it belongs to, e.g.
  /// `/home/internships/<key>`, so Back returns to that tab.
  static String internshipDetail(String tab, String internshipKey) =>
      '$tab/internships/$internshipKey';

  /// Apply Form above that Detail, e.g. `/home/internships/<key>/apply`, so
  /// Back (and Cancel in the next step) returns to the Detail.
  static String applyForm(String tab, String internshipKey) =>
      '${internshipDetail(tab, internshipKey)}/apply';

  /// Validate CV step above the Apply Form (Flow 4).
  static String applyValidate(String tab, String internshipKey) =>
      '${applyForm(tab, internshipKey)}/validate';

  /// Confirm Application step, reached only after the CV passed.
  static String applyConfirm(String tab, String internshipKey) =>
      '${applyForm(tab, internshipKey)}/confirm';
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
        name: '${source}_apply_form',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ApplyFormScreen(
          internshipKey: state.pathParameters['jobKey']!,
          source: source,
        ),
        routes: [
          GoRoute(
            path: 'validate',
            name: '${source}_apply_validate_cv',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => ApplyValidateScreen(
              internshipKey: state.pathParameters['jobKey']!,
              source: source,
            ),
          ),
          GoRoute(
            path: 'confirm',
            name: '${source}_apply_confirm',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => ApplyConfirmScreen(
              internshipKey: state.pathParameters['jobKey']!,
              source: source,
            ),
          ),
        ],
      ),
    ],
  );
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
