import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/services/cv_match_service.dart';

Map<Object?, Object?> _payload() => <Object?, Object?>{
  'internshipTitle': 'Flutter Intern',
  'companyName': 'Northstar Labs',
  'percent': 75,
  'matchedCount': 3,
  'totalRequired': 4,
  'matched': <Object?>['Flutter', 'Dart', 'SQL'],
  'missing': <Object?>['Git'],
  'niceToHave': <Object?>['Docker'],
  'suggestions': <Object?>[
    <Object?, Object?>{'skill': 'Git', 'text': 'Mention your Git project.'},
  ],
  'summary': 'A solid start.',
  'cvReadable': true,
};

void main() {
  test('parses the full callable payload', () {
    final result = parseMatchResult(_payload());

    expect(result.internshipTitle, 'Flutter Intern');
    expect(result.companyName, 'Northstar Labs');
    expect(result.percent, 75);
    expect(result.matchedCount, 3);
    expect(result.totalRequired, 4);
    expect(result.matched, ['Flutter', 'Dart', 'SQL']);
    expect(result.missing, ['Git']);
    expect(result.niceToHave, ['Docker']);
    expect(result.suggestions.single.skill, 'Git');
    expect(result.suggestions.single.text, 'Mention your Git project.');
    expect(result.summary, 'A solid start.');
    expect(result.cvReadable, isTrue);
    expect(result.hasRequirements, isTrue);
    expect(result.level.label, 'High match');
  });

  test('accepts a missing company and clamps the percentage', () {
    final payload = _payload()
      ..remove('companyName')
      ..['percent'] = 140;
    final result = parseMatchResult(payload);
    expect(result.companyName, '');
    expect(result.percent, 100);
  });

  test('rejects malformed payloads with a recoverable AppException', () {
    final badPayloads = <Object?>[
      null,
      'not a map',
      <Object?, Object?>{},
      _payload()..['percent'] = 'high',
      _payload()..['cvReadable'] = 'yes',
      _payload()..['matched'] = 'Flutter',
      _payload()..['matched'] = <Object?>['Flutter', 3],
      _payload()..['suggestions'] = <Object?>['Git'],
      _payload()
        ..['suggestions'] = <Object?>[
          <Object?, Object?>{'skill': 'Git'},
        ],
    ];

    for (final payload in badPayloads) {
      expect(
        () => parseMatchResult(payload),
        throwsA(
          isA<AppException>()
              .having((error) => error.kind, 'kind', AppErrorKind.unknown)
              .having(
                (error) => error.message,
                'message',
                'We could not read the CV match result. Please try again.',
              ),
        ),
        reason: 'payload: $payload',
      );
    }
  });

  test('maps every callable error code to a safe message', () {
    AppErrorKind kindOf(String code) => mapCvMatchError(code).kind;

    expect(kindOf('unauthenticated'), AppErrorKind.permissionDenied);
    expect(kindOf('permission-denied'), AppErrorKind.permissionDenied);
    expect(kindOf('invalid-argument'), AppErrorKind.invalidInput);
    expect(kindOf('not-found'), AppErrorKind.notFound);
    expect(kindOf('resource-exhausted'), AppErrorKind.rateLimited);
    expect(kindOf('too-many-requests'), AppErrorKind.rateLimited);
    expect(kindOf('cancelled'), AppErrorKind.cancelled);
    expect(kindOf('unavailable'), AppErrorKind.network);
    expect(kindOf('deadline-exceeded'), AppErrorKind.network);
    expect(kindOf('internal'), AppErrorKind.network);
    expect(kindOf('network-request-failed'), AppErrorKind.network);
    expect(kindOf('something-else'), AppErrorKind.unknown);

    expect(
      mapCvMatchError('not-found').message,
      'This internship is no longer available.',
    );
    expect(
      mapCvMatchError('unavailable').message,
      'We could not check your CV. Check your connection and try again.',
    );
  });
}
