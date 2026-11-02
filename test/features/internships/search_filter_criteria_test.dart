import 'package:flutter_test/flutter_test.dart';
import 'package:internly/features/internships/models/search_filter_criteria.dart';
import 'package:internly/models/internship.dart';

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

  group('work mode filter', () {
    bool matches(WorkMode? mode, Set<WorkMode> filter) =>
        SearchFilterCriteria(workModes: filter)
            .matches(testInternship('1', workMode: mode));

    test('keeps only the selected arrangements', () {
      expect(matches(WorkMode.remote, {WorkMode.remote}), isTrue);
      expect(matches(WorkMode.onSite, {WorkMode.remote}), isFalse);
      expect(
        matches(WorkMode.hybrid, {WorkMode.remote, WorkMode.hybrid}),
        isTrue,
      );
      expect(
        matches(WorkMode.onSite, {WorkMode.remote, WorkMode.hybrid}),
        isFalse,
      );
    });

    test('a listing that does not state its arrangement is left out', () {
      expect(matches(null, {WorkMode.remote}), isFalse);
    });

    test('no arrangement selected keeps every listing', () {
      expect(matches(null, const {}), isTrue);
      expect(matches(WorkMode.remote, const {}), isTrue);
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

  group('query', () {
    bool matches(String query, {String? title, String? location}) =>
        const SearchFilterCriteria().matches(
          testInternship('1', title: title, location: location),
          query: query,
        );

    test('matches without Vietnamese accents (CR-09)', () {
      expect(matches('thuc tap', title: 'Thực tập sinh Flutter'), isTrue);
      expect(matches('ha noi', location: 'Hà Nội'), isTrue);
      expect(matches('Hanoi', location: 'Hà Nội'), isTrue);
      expect(matches('Thực tập', title: 'Thuc tap sinh Backend'), isTrue);
    });

    test('keeps symbols, so C# does not match every C', () {
      expect(matches('c#', title: 'C# .NET Intern'), isTrue);
      expect(matches('c#', title: 'Crypto Intern'), isFalse);
      expect(matches('c++', title: 'C Developer'), isFalse);
    });
  });

  group('allowance filter (CR-12)', () {
    bool matches(String? salary, String option) =>
        SearchFilterCriteria(allowanceRange: option)
            .matches(testInternship('1', salary: salary));

    test('Above 5M VND/mo keeps listings that state at least 5,000,000', () {
      expect(
        matches('About 5,000,000–7,000,000 VND / mo', 'Above 5M VND/mo'),
        isTrue,
      );
      expect(matches('8M–12M VND a month', 'Above 5M VND/mo'), isTrue);
      expect(matches('3,000,000 VND / mo', 'Above 5M VND/mo'), isFalse);
      expect(matches('Negotiable', 'Above 5M VND/mo'), isFalse);
      expect(matches(null, 'Above 5M VND/mo'), isFalse);
      expect(matches(r'$500 / mo', 'Above 5M VND/mo'), isFalse);
    });

    test('Negotiable keeps only negotiable pay', () {
      expect(matches('Negotiable', 'Negotiable'), isTrue);
      expect(matches('Thỏa thuận', 'Negotiable'), isTrue);
      expect(matches('5,000,000 VND / mo', 'Negotiable'), isFalse);
      expect(matches(null, 'Negotiable'), isFalse);
    });
  });
}
