import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';

/// Authentication boundary. Views and ViewModels never touch Firebase Auth or
/// Google Sign-In directly.
abstract interface class AuthService {
  /// Emits the current user immediately, then on every sign-in / sign-out.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  /// Throws [AppException]; `kind == cancelled` when the user closes the
  /// account picker.
  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(),
);

/// Auth state for the router guard and any screen that needs the user.
final authStateChangesProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// UID of the signed-in user, or `null`.
///
/// Every user-scoped provider (Firestore listeners, caches, profile state)
/// must `ref.watch` this, so its data is dropped and rebuilt when the user
/// signs out or switches account (Lab 3 §6: "sign-out clears local user
/// data").
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateChangesProvider).value?.uid,
);

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInit;

  /// `GoogleSignIn.initialize` must run exactly once. On iOS the client ID
  /// comes from the FlutterFire-generated options; on Android it is read from
  /// `google-services.json` (web OAuth client), so `null` is correct there.
  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= _googleSignIn.initialize(
      clientId: Firebase.app().options.iosClientId,
    );
  }

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toUser);

  @override
  AppUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AppException(
          AppErrorKind.configuration,
          'Google Sign-In is not available on this device.',
        );
      }
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AppException(
          AppErrorKind.configuration,
          'Google did not return a sign-in token. Please try again.',
        );
      }
      final result = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      final user = _toUser(result.user);
      if (user == null) {
        throw const AppException(
          AppErrorKind.unknown,
          'We could not sign you in. Please try again.',
        );
      }
      // The Google profile (with `given_name`) is only available here.
      final given = result.additionalUserInfo?.profile?['given_name'];
      return given is String && given.trim().isNotEmpty
          ? AppUser(
              uid: user.uid,
              email: user.email,
              displayName: user.displayName,
              photoUrl: user.photoUrl,
              givenName: given.trim(),
            )
          : user;
    } on GoogleSignInException catch (e) {
      throw _fromGoogle(e);
    } on FirebaseAuthException catch (e) {
      throw _fromFirebase(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _fromFirebase(e);
    }
    // Also clear the Google session so the account picker shows next time.
    // Firebase is already signed out, so a failure here is not surfaced.
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } on GoogleSignInException {
      // Ignored: see comment above.
    }
  }

  static AppUser? _toUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  static AppException _fromGoogle(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled ||
      GoogleSignInExceptionCode.interrupted => AppException(
        AppErrorKind.cancelled,
        'Sign-in was cancelled. Tap Continue with Google to try again.',
        cause: e,
      ),
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError => AppException(
        AppErrorKind.configuration,
        'Google Sign-In is not set up for this build. '
        'Check the SHA-1 and OAuth client (docs/guides/firebase-setup.md).',
        cause: e,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'We could not sign you in with Google. Please try again.',
        cause: e,
      ),
    };
  }

  static AppException _fromFirebase(FirebaseAuthException e) {
    return switch (e.code) {
      'network-request-failed' => AppException(
        AppErrorKind.network,
        'We could not sign you in. Check your connection and try again.',
        cause: e,
      ),
      'user-disabled' => AppException(
        AppErrorKind.permissionDenied,
        'This account has been disabled.',
        cause: e,
      ),
      'operation-not-allowed' || 'invalid-credential' => AppException(
        AppErrorKind.configuration,
        'Google sign-in is not enabled for this Firebase project.',
        cause: e,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'We could not sign you in. Please try again.',
        cause: e,
      ),
    };
  }
}
