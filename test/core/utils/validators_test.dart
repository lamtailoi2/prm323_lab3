import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/validators.dart';
import 'package:internly/services/analytics_service.dart';

void main() {
  group('Validators', () {
    const message = 'Enter your full name to continue.';

    test('required', () {
      expect(Validators.required(null, message: message), message);
      expect(Validators.required('   ', message: message), message);
      expect(Validators.required('Minh', message: message), isNull);
    });

    test('email', () {
      expect(Validators.email('minh@student.edu.vn', message: 'x'), isNull);
      expect(Validators.email(' minh@student.edu.vn ', message: 'x'), isNull);
      expect(Validators.email('minh@student', message: 'x'), 'x');
      expect(Validators.email('', message: 'x'), 'x');
    });

    test('maxLength', () {
      expect(Validators.maxLength('a' * 500, 500, message: 'x'), isNull);
      expect(Validators.maxLength('a' * 501, 500, message: 'x'), 'x');
      expect(Validators.maxLength(null, 500, message: 'x'), isNull);
    });

    test('phone', () {
      for (final valid in ['0908123456', '+84 908 123 456', '090-812.3456']) {
        expect(Validators.phone(valid, message: 'x'), isNull, reason: valid);
      }
      for (final invalid in ['', '12345', 'call me', '+84 908 abc 456']) {
        expect(Validators.phone(invalid, message: 'x'), 'x', reason: invalid);
      }
      expect(Validators.phone('1' * 16, message: 'x'), 'x');
    });
  });

  group('AnalyticsNames.isValidEventName', () {
    test('accepts plan event names', () {
      for (final name in ['login', 'logout', 'export_pdf', 'internship_save']) {
        expect(AnalyticsNames.isValidEventName(name), isTrue, reason: name);
      }
    });

    test('rejects invalid or reserved names', () {
      for (final name in [
        '',
        '1event',
        'has-dash',
        'has space',
        'a' * 41,
        'firebase_custom',
        'google_x',
        'ga_x',
      ]) {
        expect(AnalyticsNames.isValidEventName(name), isFalse, reason: name);
      }
    });
  });
}
