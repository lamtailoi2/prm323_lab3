/// Deep link of the Notification Center, also used as the fallback target
/// when a message names none.
const String notificationCenterPath = '/profile/notifications';

const List<String> _allowedPrefixes = <String>[
  '/home',
  '/search',
  '/saved',
  '/applications',
  '/profile',
];

/// The in-app route a notification should open, or `null` when the payload
/// names nothing, names the Notification Center itself, or points outside
/// the app.
///
/// Payloads come from the console / a backend, so they are never trusted
/// blindly: only absolute paths under a known tab are accepted.
String? notificationTarget(String? route) {
  final raw = route?.trim();
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/') ||
      uri.path.startsWith('//')) {
    return null;
  }
  final path = uri.path;
  final allowed = _allowedPrefixes.any(
    (prefix) => path == prefix || path.startsWith('$prefix/'),
  );
  if (!allowed || path == notificationCenterPath) return null;
  return raw;
}
