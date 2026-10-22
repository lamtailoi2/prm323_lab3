import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Local [AuthService] implementation that does not depend on Firebase Auth.
/// Uses an in-memory [AppUser] that can be set/sign-out from tests or the
/// app itself. Sign-in with Google is a no-op that returns the current user
/// so the router can proceed; the real redirect is handled by the platform layer.
class LocalAuthService implements AuthService {
  LocalAuthService({AppUser? initialUser}) : _user = initialUser;

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() {
    _controller.add(_user);
    return _controller.stream;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    // No-op: return the current user or a test user. The platform redirect
    // is handled externally; the router proceeds when authStateChanges emits.
    final effectiveUser =
        _user ??
        AppUser(
          uid: 'local-uid',
          email: 'local@test',
          displayName: 'Local User',
          photoUrl: null,
        );
    _emit(effectiveUser);
    return effectiveUser;
  }

  @override
  Future<void> signOut() async {
    _emit(null);
  }

  void _emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  Future<void> dispose() => _controller.close();
}

/// Provides a [LocalAuthService] instance.
final localAuthServiceProvider = Provider<AuthService>(
  (ref) => LocalAuthService(),
);
