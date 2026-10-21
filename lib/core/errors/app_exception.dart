/// Failure categories that ViewModels turn into loading / error states.
enum AppErrorKind {
  /// The user dismissed the flow (e.g. closed the Google account picker).
  /// Not an error state: the screen returns to idle.
  cancelled,

  /// No connection or a timeout. Recoverable with Retry.
  network,

  /// The signed-in user is not allowed to perform the action.
  permissionDenied,

  /// The requested document does not exist (any more).
  notFound,

  /// The app or a backend service is misconfigured (developer action needed).
  configuration,

  /// An external API refused the call because a usage limit was reached
  /// (e.g. the SerpAPI monthly search quota).
  rateLimited,

  /// Anything else.
  unknown,
}

/// The only exception type services expose to ViewModels.
///
/// Services translate SDK-specific exceptions (FirebaseAuthException,
/// FirebaseException, GoogleSignInException, …) into [AppException] so that
/// ViewModels and Views never depend on Firebase types.
class AppException implements Exception {
  const AppException(this.kind, this.message, {this.cause});

  final AppErrorKind kind;

  /// Plain-language message that is safe to show to the user.
  final String message;

  /// The original error, for logging only. Never shown in the UI.
  final Object? cause;

  bool get isCancelled => kind == AppErrorKind.cancelled;

  @override
  String toString() => 'AppException(${kind.name}): $message';
}
