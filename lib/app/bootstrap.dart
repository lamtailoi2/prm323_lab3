import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';
import '../services/remote_config_service.dart';
import 'app.dart';

/// Starts the app with local services (no Firebase required).
/// Feature code never depends on Firebase SDK types; all state flows through
/// Riverpod providers that wrap local or remote implementations.
///
/// If Firebase is available, it will be used through the service interfaces;
/// otherwise local implementations are used automatically. This allows the
/// app to run without Firebase configuration for testing or offline development.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (_) {
    // Firebase not configured: proceed with local services instead of
    // showing a setup wall. The app will use local implementations.
  } on FirebaseException catch (_) {
    // Firebase error: proceed with local services.
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