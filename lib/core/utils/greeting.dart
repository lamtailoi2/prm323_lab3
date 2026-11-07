/// Time-of-day greeting shown above the student's name in the Home header
/// (Figma "Tab Header v2", DC-31).
String greetingFor(DateTime time) {
  final hour = time.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}
