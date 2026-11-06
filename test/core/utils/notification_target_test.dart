import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/notification_target.dart';

void main() {
  test('accepts a path under a known tab', () {
    expect(notificationTarget('/home'), '/home');
    expect(
      notificationTarget('/home/internships/job-1'),
      '/home/internships/job-1',
    );
    expect(notificationTarget('/applications/job-1'), '/applications/job-1');
    expect(
      notificationTarget('/search/results?q=flutter'),
      '/search/results?q=flutter',
    );
  });

  test('rejects nothing, relative and external targets', () {
    expect(notificationTarget(null), isNull);
    expect(notificationTarget(''), isNull);
    expect(notificationTarget('   '), isNull);
    expect(notificationTarget('home/internships/job-1'), isNull);
    expect(notificationTarget('https://example.com/home'), isNull);
    expect(notificationTarget('//example.com/home'), isNull);
  });

  test('rejects routes outside the app tabs', () {
    expect(notificationTarget('/login'), isNull);
    expect(notificationTarget('/splash'), isNull);
    expect(notificationTarget('/homework'), isNull);
  });

  test('the Notification Center is not a target of itself', () {
    expect(notificationTarget(notificationCenterPath), isNull);
  });
}
