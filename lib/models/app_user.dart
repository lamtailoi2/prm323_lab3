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
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(uid, email, displayName, photoUrl);

  @override
  String toString() => 'AppUser($uid)';
}
