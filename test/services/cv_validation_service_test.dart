import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/models/cv_validation_result.dart';
import 'package:internly/services/cv_validation_service.dart';

void main() {
  group('parseValidationResult', () {
    test('reads a valid verdict', () {
      expect(
        parseValidationResult(<String, Object>{'isValid': true, 'reason': ''}),
        const CvValidationResult(isValid: true),
      );
    });

    test('keeps the reason of a rejected CV', () {
      expect(
        parseValidationResult(<String, Object>{
          'isValid': false,
          'reason': '  No experience section.  ',
        }),
        const CvValidationResult(
          isValid: false,
          reason: 'No experience section.',
        ),
      );
    });

    test('rejects payloads without a boolean verdict', () {
      for (final data in <Object?>[
        null,
        'not a map',
        <String, Object>{},
        <String, Object>{'isValid': 'yes'},
        <String, Object>{'isValid': 1},
      ]) {
        expect(
          () => parseValidationResult(data),
          throwsA(
            isA<AppException>().having(
              (error) => error.kind,
              'kind',
              AppErrorKind.unknown,
            ),
          ),
        );
      }
    });
  });

  test('Cloud Functions error codes map to user-safe messages', () {
    AppErrorKind kindOf(String code) => mapCvValidationError(code).kind;

    expect(kindOf('unauthenticated'), AppErrorKind.permissionDenied);
    expect(kindOf('permission-denied'), AppErrorKind.permissionDenied);
    expect(kindOf('invalid-argument'), AppErrorKind.invalidInput);
    expect(kindOf('failed-precondition'), AppErrorKind.configuration);
    expect(kindOf('not-found'), AppErrorKind.notFound);
    expect(kindOf('resource-exhausted'), AppErrorKind.rateLimited);
    expect(kindOf('too-many-requests'), AppErrorKind.rateLimited);
    expect(kindOf('cancelled'), AppErrorKind.cancelled);
    expect(kindOf('unavailable'), AppErrorKind.network);
    expect(kindOf('deadline-exceeded'), AppErrorKind.network);
    expect(kindOf('internal'), AppErrorKind.network);
    expect(kindOf('network-request-failed'), AppErrorKind.network);
    expect(kindOf('something-else'), AppErrorKind.unknown);
  });
}
