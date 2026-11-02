import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/distinct_listings.dart';

import '../../helpers/fakes.dart';

void main() {
  group('distinctListings', () {
    test('keeps the best-ranked copy of the same title and company', () {
      final listings = distinctListings([
        testInternship(
          '1',
          title: 'Flutter Intern',
          companyName: 'MoMo',
          searchRank: 4,
        ),
        testInternship(
          '2',
          title: 'Flutter Intern',
          companyName: 'MoMo',
          searchRank: 1,
        ),
        // Same title at another company is a different job.
        testInternship(
          '3',
          title: 'Flutter Intern',
          companyName: 'VNG',
          searchRank: 2,
        ),
      ]);

      expect(listings.map((i) => i.jobId), ['job-2', 'job-3']);
    });

    test('folds case and Vietnamese accents before comparing', () {
      final listings = distinctListings([
        testInternship(
          '1',
          title: 'Thực tập sinh Flutter',
          companyName: 'FPT Software',
          searchRank: 3,
        ),
        testInternship(
          '2',
          title: 'THUC TAP SINH FLUTTER',
          companyName: 'fpt software',
          searchRank: 1,
        ),
        testInternship('3', title: 'Java Intern', companyName: 'FPT Software'),
      ]);

      expect(listings.map((i) => i.jobId), ['job-2', 'job-3']);
    });

    test('without a rank, the newest copy is kept', () {
      final now = DateTime(2026, 11, 2);
      final listings = distinctListings([
        testInternship(
          '1',
          title: 'Flutter Intern',
          companyName: 'VNG',
          postedAt: now.subtract(const Duration(days: 3)),
        ),
        testInternship(
          '2',
          title: 'Flutter Intern',
          companyName: 'VNG',
          postedAt: now,
        ),
      ]);

      expect(listings.single.jobId, 'job-2');
    });
  });
}
