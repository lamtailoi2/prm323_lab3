import 'package:flutter/foundation.dart';

/// The signed-in account, independent of the auth SDK.
///
/// Views and ViewModels use this instead of `firebase_auth.User`.
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.givenName,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// Google's `given_name`, the name the student is called by. Only the
  /// user returned by `AuthService.signInWithGoogle` carries it: Firebase
  /// gives the Google profile at sign-in only, so it is saved to
  /// `users/{uid}.givenName` for later sessions (DC-31).
  final String? givenName;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl &&
      other.givenName == givenName;

  @override
  int get hashCode => Object.hash(uid, email, displayName, photoUrl, givenName);

  @override
  String toString() => 'AppUser($uid)';
}
