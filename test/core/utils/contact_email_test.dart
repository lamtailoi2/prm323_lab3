import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/contact_email.dart';

void main() {
  test('finds the recruiting address in a Vietnamese job post', () {
    const text = 'Ứng viên gửi CV đến hr@fptsoftware.com.vn trước 30/11.';
    expect(findApplicationEmail(text), 'hr@fptsoftware.com.vn');
  });

  test('prefers a recruiting mailbox when several are listed', () {
    expect(
      findApplicationEmail('Contact support@acme.com or careers@acme.com.'),
      'careers@acme.com',
    );
  });

  test('strips surrounding punctuation', () {
    expect(findApplicationEmail('Email: recruit@acme.io.'), 'recruit@acme.io');
    expect(findApplicationEmail('(hr@acme.io)'), 'hr@acme.io');
  });

  test('ignores machine addresses', () {
    expect(findApplicationEmail('noreply@acme.com'), isNull);
    expect(findApplicationEmail('no-reply@acme.com'), isNull);
  });

  test('returns null without an address', () {
    expect(findApplicationEmail(null), isNull);
    expect(findApplicationEmail('Apply on our website'), isNull);
  });

  test('deduplicates case-insensitively', () {
    expect(findApplicationEmail('HR@acme.com hr@acme.com'), 'HR@acme.com');
  });
}
