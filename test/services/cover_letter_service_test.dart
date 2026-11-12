import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/services/cover_letter_service.dart';

void main() {
  group('parseCoverLetterDraft', () {
    test('reads a valid AI payload', () {
      final draft = parseCoverLetterDraft(<String, Object?>{
        'subject': ' Application for Flutter Intern ',
        'body': ' Dear Hiring Team, ... ',
        'source': 'ai',
      });

      expect(draft.subject, 'Application for Flutter Intern');
      expect(draft.body, 'Dear Hiring Team, ...');
      expect(draft.usedAi, isTrue);
    });

    test('marks the deterministic template', () {
      final draft = parseCoverLetterDraft(<String, Object?>{
        'subject': 'Application for Flutter Intern',
        'body': 'Dear Hiring Team, ...',
        'source': 'template',
      });

      expect(draft.usedAi, isFalse);
    });

    test('rejects a malformed payload', () {
      expect(
        () => parseCoverLetterDraft(<String, Object?>{'subject': 'Only'}),
        throwsA(isA<AppException>()),
      );
      expect(
        () => parseCoverLetterDraft('not a map'),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('mapCoverLetterError', () {
    test('maps the codes to safe messages', () {
      expect(
        mapCoverLetterError('unauthenticated').kind,
        AppErrorKind.permissionDenied,
      );
      expect(mapCoverLetterError('not-found').kind, AppErrorKind.notFound);
      expect(
        mapCoverLetterError('resource-exhausted').kind,
        AppErrorKind.rateLimited,
      );
      expect(mapCoverLetterError('unavailable').kind, AppErrorKind.network);
      expect(mapCoverLetterError('something-else').kind, AppErrorKind.unknown);
    });
  });
}
