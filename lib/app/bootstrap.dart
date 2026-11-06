import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';
import 'app.dart';
import 'notification_coordinator.dart';

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

  if (Firebase.apps.isNotEmpty) {
    // Registers the isolate that runs when a message arrives while the app
    // is in the background or terminated. Must happen before runApp.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final container = ProviderContainer();
  final crashlytics = container.read(crashlyticsServiceProvider);
  crashlytics.registerGlobalErrorHandlers();
  await container.read(remoteConfigServiceProvider).initialize();

  // Cloud Messaging needs a Firebase app; without one the app still starts.
  final notifications = Firebase.apps.isEmpty
      ? null
      : (NotificationCoordinator(container)..start());

  // Tag reports with the pseudonymous UID only (no email or name).
  final analytics = container.read(analyticsServiceProvider);
  container.listen(authStateChangesProvider, (_, next) {
    final uid = next.value?.uid;
    analytics.setUserId(uid);
    crashlytics.setUserId(uid);
    // Permission prompt, token upload and a message that launched the app.
    if (uid != null && notifications != null) {
      unawaited(notifications.signedIn(uid));
    }
  });

  runApp(
    UncontrolledProviderScope(container: container, child: const InternlyApp()),
  );
}
