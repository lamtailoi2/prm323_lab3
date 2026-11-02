import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/display_format.dart';

void main() {
  group('formatShortDate', () {
    test('matches the CV card format of the Profile design', () {
      expect(formatShortDate(DateTime(2024, 10, 14)), 'Oct 14, 2024');
      expect(formatShortDate(DateTime(2026, 1, 3)), 'Jan 3, 2026');
    });
  });

  group('formatFileSize', () {
    test('kilobytes round up and never read as empty', () {
      expect(formatFileSize(1), '1 KB');
      expect(formatFileSize(430080), '420 KB');
      expect(formatFileSize(430081), '421 KB');
    });

    test('megabytes keep one decimal under 10 MB', () {
      expect(formatFileSize(1024 * 1024), '1 MB');
      expect(formatFileSize((1.25 * 1024 * 1024).round()), '1.3 MB');
      expect(formatFileSize(12 * 1024 * 1024), '12 MB');
    });
  });

  group('application dates', () {
    test('applied date is day and month, as on the card', () {
      expect(formatDayMonth(DateTime(2026, 10, 1)), '1 Oct');
      expect(formatDayMonth(DateTime(2026, 9, 24)), '24 Sep');
    });

    test('an interview slot reads as month, day and 12-hour time', () {
      expect(formatMonthDayTime(DateTime(2026, 10, 24, 14)), 'Oct 24, 2:00 PM');
      expect(
        formatMonthDayTime(DateTime(2026, 10, 24, 9, 5)),
        'Oct 24, 9:05 AM',
      );
      // Midnight and noon are 12 AM / 12 PM, never 0 AM / 0 PM.
      expect(formatMonthDayTime(DateTime(2026, 10, 24)), 'Oct 24, 12:00 AM');
      expect(
        formatMonthDayTime(DateTime(2026, 10, 24, 12)),
        'Oct 24, 12:00 PM',
      );
    });

    test('a reply deadline within the week is relative', () {
      final now = DateTime(2026, 10, 13);
      expect(
        formatReplyBy(DateTime(2026, 10, 18), now: now),
        'Reply within 5 days',
      );
      expect(
        formatReplyBy(DateTime(2026, 10, 14), now: now),
        'Reply within 1 day',
      );
      expect(
        formatReplyBy(DateTime(2026, 10, 20), now: now),
        'Reply by 20 Oct',
      );
      expect(
        formatReplyBy(DateTime(2026, 10, 10), now: now),
        'Reply by 10 Oct',
      );
    });
  });
}
