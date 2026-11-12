import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/greeting.dart';

void main() {
  test('greets by time of day', () {
    expect(greetingFor(DateTime(2026, 11, 6, 0)), 'Good morning');
    expect(greetingFor(DateTime(2026, 11, 6, 11, 59)), 'Good morning');
    expect(greetingFor(DateTime(2026, 11, 6, 12)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 11, 6, 17, 59)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 11, 6, 18)), 'Good evening');
    expect(greetingFor(DateTime(2026, 11, 6, 23, 59)), 'Good evening');
  });
}
