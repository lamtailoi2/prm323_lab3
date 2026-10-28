import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/allowance.dart';
import 'package:internly/core/utils/job_key.dart';
import 'package:internly/core/utils/posted_age.dart';
import 'package:internly/core/utils/skill_matcher.dart';

void main() {
  group('jobKeyFor', () {
    test('is short, URL-safe and stable', () {
      const jobId =
          'eyJqb2JfdGl0bGUiOiJGbHV0dGVyIEludGVybiIsImh0aWRvY2lkIjoiYS9i'
          'K2MvZD0ifQ==';
      final key = jobKeyFor(jobId);
      expect(key, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(jobKeyFor(jobId), key);
    });

    test('differs for different IDs', () {
      expect(jobKeyFor('job-1'), isNot(jobKeyFor('job-2')));
    });

    test('matches the FNV-1a 64 reference values', () {
      expect(jobKeyFor(''), 'cbf29ce484222325');
      expect(jobKeyFor('a'), 'af63dc4c8601ec8c');
    });
  });

  group('parsePostedAge', () {
    test('parses Google Jobs relative dates', () {
      expect(parsePostedAge('17 hours ago'), const Duration(hours: 17));
      expect(parsePostedAge('2 days ago'), const Duration(days: 2));
      expect(parsePostedAge('1 day ago'), const Duration(days: 1));
      expect(parsePostedAge('30+ days ago'), const Duration(days: 30));
      expect(parsePostedAge('a week ago'), const Duration(days: 7));
      expect(parsePostedAge('an hour ago'), const Duration(hours: 1));
      expect(parsePostedAge('Just posted'), Duration.zero);
    });

    test('returns null for missing or unknown text', () {
      expect(parsePostedAge(null), isNull);
      expect(parsePostedAge('Full-time'), isNull);
      expect(parsePostedAge(''), isNull);
    });
  });

  group('formatPostedAge', () {
    final now = DateTime.utc(2026, 10, 22, 12);

    test('uses the compact Home wording', () {
      expect(formatPostedAge(null), '');
      expect(formatPostedAge(now, now: now), 'Just now');
      expect(
        formatPostedAge(now.subtract(const Duration(minutes: 17)), now: now),
        '17m ago',
      );
      expect(
        formatPostedAge(now.subtract(const Duration(hours: 3)), now: now),
        '3h ago',
      );
      expect(
        formatPostedAge(now.subtract(const Duration(days: 2)), now: now),
        '2d ago',
      );
      expect(
        formatPostedAge(now.subtract(const Duration(days: 8)), now: now),
        '1w ago',
      );
      expect(
        formatPostedAge(now.subtract(const Duration(days: 45)), now: now),
        '1mo ago',
      );
      expect(
        formatPostedAge(now.subtract(const Duration(days: 400)), now: now),
        '1y ago',
      );
    });
  });

  group('formatAllowance', () {
    test('normalises Google period wording without inventing pay', () {
      expect(formatAllowance(null), 'Not disclosed');
      expect(formatAllowance('  '), 'Not disclosed');
      expect(formatAllowance('12,000,000 VND a month'), '12,000,000 VND / mo');
      expect(formatAllowance('8M–12M VND per month'), '8M–12M VND / mo');
      expect(formatAllowance('Negotiable'), 'Negotiable');
      expect(formatAllowance('USD 20/hour'), 'USD 20/hour');
      expect(formatAllowance('12M   VND   monthly'), '12M VND / mo');
    });
  });

  group('findSkills', () {
    test('finds known skills in order of first mention', () {
      expect(
        findSkills('Flutter Intern. Requirements: Dart, Firebase and Git.'),
        ['Flutter', 'Dart', 'Firebase', 'Git'],
      );
    });

    test('is case-insensitive and respects word boundaries', () {
      expect(findSkills('We use javascript and MySQL'), [
        'JavaScript',
        'MySQL',
      ]);
      expect(findSkills('GitHub, Golang'), ['Golang']);
    });

    test('matches skills with symbols', () {
      expect(findSkills('C#, ASP.NET Core and C++'), ['C#', 'ASP.NET', 'C++']);
    });

    test('drops a skill that is part of a longer match', () {
      expect(findSkills('React Native developer'), ['React Native']);
      expect(findSkills('React and React Native'), ['React Native']);
    });

    test('ignores ambiguous words and domains', () {
      expect(
        findSkills('Ai cũng có thể apply, contact hr@company.net'),
        isEmpty,
      );
    });
  });

  group('allowanceFromText (real listing text)', () {
    final cases = <String, String?>{
      'Thu nhập: Khoảng 2-3 triệu đồng /tháng Địa điểm làm việc: 68':
          'About 2,000,000–3,000,000 VND / mo',
      'Được trả mức thù lao 4.000.000 VNĐ/tháng trong thời gian là sinh viên.':
          '4,000,000 VND / mo',
      'Quyền lợiInternship allowance: 3M per monthBAP’s benefit':
          '3,000,000 VND / mo',
      'Lương: 1000K - 2000K VND một tháng   Loại hình công việc':
          '1,000,000–2,000,000 VND / mo',
      '3. Benefits:  Internship allowance: 10,000,000 VND/month  Insurance':
          '10,000,000 VND / mo',
      'Được hưởng trợ cấp hàng tháng (3tr/1 tháng), cơ hội làm việc':
          '3,000,000 VND / mo',
      'Quyền lợiAllowance: 500,000 VND/month.Holiday bonuses':
          '500,000 VND / mo',
      'Quyền lợi được hưởng  - Mức lương: khoảng 4,000,000 VND. - Hỗ trợ':
          'About 4,000,000 VND',
      'Trợ cấp: Lên đến 5.000.000 cho sinh viên xuất sắc':
          'Up to 5,000,000 VND',
      'Trợ cấp : lên đến 2.300.000       M': 'Up to 2,300,000 VND',
      'Mức lương: Hỗ trợ lương theo năng lực (4tr - 6tr/tháng)':
          '4,000,000–6,000,000 VND / mo',
      'Stipend: \$500 per month for remote interns': '\$500 / mo',
      'Allowance: 7,000,000VND gross/month.  - Lunch allowance: '
              '700,000VND/month  - Home Office Support Allowance: '
              '250,000VND/month.':
          '7,000,000 VND / mo',
      'Mức lương: Đến 3 triệu VNĐ)  We are seeking': 'Up to 3,000,000 VND',
      'Mức lương: Từ 2 triệu VNĐ)  Hỗ trợ cài đặt': 'From 2,000,000 VND',
      'Allowance: from 7,000,000 VND, open to negotiate': 'From 7,000,000 VND',
      'Thu nhập: lương cứng 7 -> 10 triệu / tháng + thưởng':
          '7,000,000–10,000,000 VND / mo',
      'QUYỀN LỢI:  Thu nhập từ 5.000.000 – 10.000.000 VNĐ/tháng (có thể':
          '5,000,000–10,000,000 VND / mo',
      'Internship allowance: 3 million VND per month': '3,000,000 VND / mo',
      // Not the internship pay: meal allowance, post-hire salary.
      'Meal allowance of 730,000 VND/month. Medical benefit': null,
      'Được phụ cấp ăn trưa 30.000 đồng/ngày': null,
      'official salary of 15+ million VND/ month, 13th month salary': null,
      'Mô tả công việc:   (Mức lương: Thỏa thuận)   Thu thập': 'Negotiable',
      'Thông tin chungThu nhập: Thoả thuậnNơi làm việc': 'Negotiable',
      // No amount and not negotiable: stays "Not disclosed".
      'Phúc lợi: - Lương tháng 13  - Khám sức khỏe định kỳ': null,
      'Competitive salary and 13th-month salary14+ annual leave days': null,
      'Attractive allowance for Internship program (30 hours/week).': null,
      'Social insurance based on 100% salary Modern office': null,
      'Hạn nộp: 30/07/2026 Kinh nghiệm: 1 năm': null,
    };

    cases.forEach((text, expected) {
      test(text, () => expect(allowanceFromText(text), expected));
    });

    test('an amount wins over "negotiable" elsewhere in the text', () {
      expect(
        allowanceFromText('Mức lương: Thỏa thuận. Trợ cấp: 3 triệu/tháng'),
        '3,000,000 VND / mo',
      );
    });

    test('formatAllowance keeps the extracted text as is', () {
      for (final text in ['3,000,000 VND / mo', 'Negotiable']) {
        expect(formatAllowance(text), text);
      }
    });
  });
}
