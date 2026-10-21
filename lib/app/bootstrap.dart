import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';
import '../services/remote_config_service.dart';
import 'app.dart';
import 'firebase_setup_required_app.dart';

/// Starts the app: Firebase first, then error reporting and Remote Config
/// defaults, then the widget tree. Feature code never initializes Firebase.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (error) {
    // Placeholder firebase_options.dart: show setup instructions instead of
    // pretending to be connected.
    runApp(FirebaseSetupRequiredApp(details: error.message));
    return;
  } on FirebaseException catch (error) {
    runApp(FirebaseSetupRequiredApp(details: error.message));
    return;
  }

  final container = ProviderContainer();
  final crashlytics = container.read(crashlyticsServiceProvider);
  crashlytics.registerGlobalErrorHandlers();
  await container.read(remoteConfigServiceProvider).initialize();

  // Tag reports with the pseudonymous UID only (no email or name).
  final analytics = container.read(analyticsServiceProvider);
  container.listen(authStateChangesProvider, (_, next) {
    final uid = next.value?.uid;
    analytics.setUserId(uid);
    crashlytics.setUserId(uid);
  });

  runApp(
    UncontrolledProviderScope(container: container, child: const InternlyApp()),
  );
}
