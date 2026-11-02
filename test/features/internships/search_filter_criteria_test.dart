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
}
