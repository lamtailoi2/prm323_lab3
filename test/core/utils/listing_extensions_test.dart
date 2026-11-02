import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/listing_extensions.dart';
import 'package:internly/core/utils/posted_age.dart';

void main() {
  group('scheduleTypeFromExtensions', () {
    test('reads the Vietnamese chips of the hl=vi sync, in English', () {
      expect(scheduleTypeFromExtensions(['Toàn thời gian']), 'Full-time');
      expect(scheduleTypeFromExtensions(['Thực tập']), 'Internship');
      expect(scheduleTypeFromExtensions(['Bán thời gian']), 'Part-time');
      expect(
        scheduleTypeFromExtensions(['Toàn thời gian và Thực tập']),
        'Full-time and Internship',
      );
    });

    test('skips the posted age and the pay chips', () {
      expect(
        scheduleTypeFromExtensions([
          '20 ngày trước',
          '3 Tr ₫–5 Tr ₫ một tháng',
          'Toàn thời gian',
        ]),
        'Full-time',
      );
    });

    test('reads English chips too', () {
      expect(
        scheduleTypeFromExtensions(['2 days ago', 'Part-time']),
        'Part-time',
      );
    });

    test('no schedule chip is null', () {
      expect(scheduleTypeFromExtensions(['3 ngày trước']), isNull);
      expect(scheduleTypeFromExtensions(const []), isNull);
    });
  });

  group('postedTextFromExtensions', () {
    test('finds the posted age in Vietnamese or English', () {
      expect(
        postedTextFromExtensions(['3 ngày trước', 'Toàn thời gian']),
        '3 ngày trước',
      );
      expect(
        postedTextFromExtensions(['Full-time', '2 days ago']),
        '2 days ago',
      );
      expect(postedTextFromExtensions(['Toàn thời gian']), isNull);
    });
  });

  group('parsePostedAge in Vietnamese', () {
    test('minutes, hours, days, weeks and months', () {
      expect(parsePostedAge('15 phút trước'), const Duration(minutes: 15));
      expect(parsePostedAge('17 giờ trước'), const Duration(hours: 17));
      expect(parsePostedAge('3 ngày trước'), const Duration(days: 3));
      expect(parsePostedAge('30+ ngày trước'), const Duration(days: 30));
      expect(parsePostedAge('2 tuần trước'), const Duration(days: 14));
      expect(parsePostedAge('1 tháng trước'), const Duration(days: 30));
    });

    test('other text is not an age', () {
      expect(parsePostedAge('Toàn thời gian'), isNull);
    });
  });

  group('formatPostedAgeLong', () {
    final now = DateTime(2026, 11, 2, 12);

    test('reads like the Figma meta row', () {
      expect(
        formatPostedAgeLong(now.subtract(const Duration(days: 2)), now: now),
        '2 days ago',
      );
      expect(
        formatPostedAgeLong(now.subtract(const Duration(days: 1)), now: now),
        '1 day ago',
      );
      expect(
        formatPostedAgeLong(now.subtract(const Duration(hours: 5)), now: now),
        '5 hours ago',
      );
      expect(
        formatPostedAgeLong(now.subtract(const Duration(days: 21)), now: now),
        '3 weeks ago',
      );
      expect(formatPostedAgeLong(now, now: now), 'just now');
    });
  });
}
