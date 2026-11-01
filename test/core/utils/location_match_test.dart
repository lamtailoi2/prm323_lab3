import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/location_match.dart';
import 'package:internly/core/utils/text_fold.dart';

void main() {
  group('foldText', () {
    test('removes Vietnamese diacritics and punctuation', () {
      expect(
        foldText('Thành phố Hồ Chí Minh, Hồ Chí Minh'),
        'thanh pho ho chi minh ho chi minh',
      );
      expect(foldText('Đà Nẵng (+1 vị trí khác)'), 'da nang 1 vi tri khac');
    });
  });

  group('matchesPreferredLocation (locations from the real pool)', () {
    const hcm = 'Ho Chi Minh City';

    test('Ho Chi Minh City matches every Google spelling of the city', () {
      for (final location in [
        'Thành phố Hồ Chí Minh, Hồ Chí Minh',
        'Hồ Chí Minh',
        'Thành phố Hồ Chí Minh, Hồ Chí Minh (+2 vị trí khác)',
        'District 3, Ho Chi Minh City',
        'Quận 1, TP. HCM',
        'Sài Gòn',
      ]) {
        expect(
          matchesPreferredLocation(location, hcm),
          isTrue,
          reason: location,
        );
      }
    });

    test('other cities, "Việt Nam" only and no location do not match', () {
      for (final location in ['Hà Nội', 'Đà Nẵng', 'Việt Nam', 'Đồng Nai']) {
        expect(
          matchesPreferredLocation(location, hcm),
          isFalse,
          reason: location,
        );
      }
      expect(matchesPreferredLocation(null, hcm), isFalse);
    });

    test('Hanoi and Da Nang quick picks', () {
      expect(matchesPreferredLocation('Hà Nội', 'Hanoi'), isTrue);
      expect(matchesPreferredLocation('Hưng Yên', 'Hanoi'), isFalse);
      expect(
        matchesPreferredLocation('Đà Nẵng, Hải Châu, Đà Nẵng', 'Da Nang'),
        isTrue,
      );
      expect(
        matchesPreferredLocation('Đà Nẵng (+1 vị trí khác)', 'Da Nang'),
        isTrue,
      );
    });

    test('no preference or "All Vietnam" matches everything', () {
      for (final preferred in [null, '', '  ', 'All Vietnam', 'Việt Nam']) {
        expect(matchesPreferredLocation('Hà Nội', preferred), isTrue);
        expect(matchesPreferredLocation(null, preferred), isTrue);
      }
    });

    test('a typed place is compared without diacritics, as whole words', () {
      expect(matchesPreferredLocation('Hải Phòng', 'hai phong'), isTrue);
      expect(
        matchesPreferredLocation('Thủ Đức, Hồ Chí Minh', 'Thu Duc'),
        isTrue,
      );
      expect(matchesPreferredLocation('Quảng Nam', 'Nam'), isTrue);
      // Part of a word is not enough.
      expect(matchesPreferredLocation('Bến Tre, Vĩnh Long', 'Ben Tr'), isFalse);
    });
  });
}
