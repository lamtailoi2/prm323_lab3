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
}
