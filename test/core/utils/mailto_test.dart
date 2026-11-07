import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/mailto.dart';

void main() {
  test('encodes the subject, the body and newlines', () {
    final uri = buildMailtoUri(
      to: 'hr@acme.com',
      subject: 'Application for Flutter Intern',
      body: 'Dear Hiring Team,\nI am Minh & I build apps.',
    );

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'hr@acme.com');
    expect(uri.query, contains('subject=Application%20for%20Flutter%20Intern'));
    expect(
      uri.query,
      contains(
        'body=Dear%20Hiring%20Team%2C%0AI%20am%20Minh%20%26%20I%20build%20apps.',
      ),
    );
  });

  test('an empty recipient still opens a draft', () {
    final uri = buildMailtoUri(subject: 'Hi', body: 'Body');
    expect(uri.toString(), 'mailto:?subject=Hi&body=Body');
  });

  test('keeps Vietnamese diacritics encoded', () {
    final uri = buildMailtoUri(
      to: 'hr@acme.vn',
      subject: 'Ứng tuyển',
      body: 'Kính gửi',
    );
    expect(uri.query, contains('subject=%E1%BB%A8ng%20tuy%E1%BB%83n'));
  });
}
