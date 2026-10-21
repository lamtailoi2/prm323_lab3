// DEVELOPMENT PLACEHOLDER: contains no Firebase configuration or credentials.
//
// Replace this file by running, from the repository root:
//
//   flutterfire configure --project=<your-firebase-project-id> \
//     --platforms=android,ios --out=lib/firebase_options.dart
//
// Until then the app starts on a "Firebase is not configured" screen instead
// of pretending to be connected. See docs/firebase-setup.md.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured for this build. Run `flutterfire configure` '
      '(see docs/firebase-setup.md).',
    );
  }
}
