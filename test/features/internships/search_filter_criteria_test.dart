import 'package:flutter_test/flutter_test.dart';
import 'package:internly/features/internships/models/search_filter_criteria.dart';

import '../../helpers/fakes.dart';

void main() {
  group('location filter', () {
    bool matches(String? jobLocation, String? filter) =>
        SearchFilterCriteria(location: filter)
            .matches(testInternship('1', location: jobLocation));

    test('English city names match the Vietnamese Google Jobs spellings', () {
      expect(
        matches('Thành phố Hồ Chí Minh, Hồ Chí Minh', 'Ho Chi Minh City'),
        isTrue,
      );
      expect(matches('Hồ Chí Minh', 'Ho Chi Minh City'), isTrue);
      expect(matches('Ho Chi Minh City, Vietnam', 'Ho Chi Minh City'), isTrue);
      expect(matches('Hà Nội', 'Ha Noi'), isTrue);
      expect(matches('Hanoi, Vietnam', 'Ha Noi'), isTrue);
      expect(matches('Đà Nẵng (+1 vị trí khác)', 'Da Nang'), isTrue);
    });

    test('a listing in another city or only "Việt Nam" does not match', () {
      expect(matches('Hà Nội', 'Ho Chi Minh City'), isFalse);
      expect(matches('Việt Nam', 'Da Nang'), isFalse);
    });

    test('Any location (or none) keeps every listing', () {
      expect(matches('Việt Nam', 'Any location'), isTrue);
      expect(matches('Hà Nội', null), isTrue);
    });
  });

  group('job type filter', () {
    bool matches(String? scheduleType, String? jobType) =>
        SearchFilterCriteria(jobType: jobType)
            .matches(testInternship('1', scheduleType: scheduleType));

    test('matches the schedule type in English and in Vietnamese', () {
      expect(matches('Internship', 'Internship'), isTrue);
      expect(matches('Thực tập', 'Internship'), isTrue);
      expect(matches('Full-time', 'Full-time'), isTrue);
      expect(matches('Toàn thời gian', 'Full-time'), isTrue);
      expect(matches('Part-time', 'Part-time'), isTrue);
      expect(matches('Bán thời gian', 'Part-time'), isTrue);
      expect(matches('Full-time and Internship', 'Internship'), isTrue);
    });

    test('another job type does not match', () {
      expect(matches('Full-time', 'Internship'), isFalse);
      expect(matches('Toàn thời gian', 'Part-time'), isFalse);
      expect(matches('Bán thời gian', 'Full-time'), isFalse);
    });

    test('a listing that does not state its job type is left out', () {
      expect(matches(null, 'Internship'), isFalse);
    });

    test('Any job type (or none) keeps every listing', () {
      expect(matches(null, 'Any job type'), isTrue);
      expect(matches('Full-time', null), isTrue);
    });
  });
}
