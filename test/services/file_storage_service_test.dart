import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/services/file_storage_service.dart';

import '../helpers/fakes.dart';

final Uint8List _pdf = Uint8List.fromList(
  utf8.encode('%PDF-1.7\n1 0 obj << >> endobj\n%%EOF'),
);
const _id = '0123456789abcdef0123456789abcdef';

Matcher _appError(AppErrorKind kind) =>
    throwsA(isA<AppException>().having((e) => e.kind, 'kind', kind));

void main() {
  group('prepareUploadPath (checks mirrored by storage.rules)', () {
    test('builds a path inside the user\'s own folder', () {
      final path = prepareUploadPath(
        uid: testUser.uid,
        folder: StorageFolder.reports,
        fileName: 'My Applications Report.pdf',
        bytes: _pdf,
        randomId: _id,
      );
      expect(path, 'reports/${testUser.uid}/my-applications-report-$_id.pdf');
    });

    test('rejects signed-out users', () {
      expect(
        () => prepareUploadPath(
          uid: null,
          folder: StorageFolder.cvs,
          fileName: 'cv.pdf',
          bytes: _pdf,
          randomId: _id,
        ),
        _appError(AppErrorKind.permissionDenied),
      );
    });

    test('rejects non-PDF, empty and oversized files', () {
      for (final bytes in [
        Uint8List.fromList(utf8.encode('<html>not a pdf</html>')),
        Uint8List(0),
        Uint8List(maxUploadBytes + 1),
      ]) {
        expect(
          () => prepareUploadPath(
            uid: testUser.uid,
            folder: StorageFolder.cvs,
            fileName: 'cv.pdf',
            bytes: bytes,
            randomId: _id,
          ),
          _appError(AppErrorKind.invalidInput),
        );
      }
    });

    test('sanitizes file names', () {
      final path = prepareUploadPath(
        uid: 'u1',
        folder: StorageFolder.cvs,
        fileName: '../../Nguyễn CV (final).PDF',
        bytes: _pdf,
        randomId: _id,
      );
      expect(path, startsWith('cvs/u1/'));
      expect(path, isNot(contains('..')));
      expect(path, matches(RegExp(r'^cvs/u1/[a-z0-9-]+-[0-9a-f]{32}\.pdf$')));
    });
  });

  test('FirebaseStorageService rejects signed-out users before using '
      'Firebase', () async {
    final auth = FakeAuthService();
    addTearDown(auth.dispose);
    // No FirebaseStorage is created: validation fails first.
    final service = FirebaseStorageService(auth: auth);
    await expectLater(
      service.uploadPdf(
        folder: StorageFolder.reports,
        fileName: 'r.pdf',
        bytes: _pdf,
      ),
      _appError(AppErrorKind.permissionDenied),
    );
  });

  test('maps Cloud Storage error codes to user-safe errors', () {
    expect(
      mapStorageError('storage/unauthorized').kind,
      AppErrorKind.permissionDenied,
    );
    expect(
      mapStorageError('unauthenticated').kind,
      AppErrorKind.permissionDenied,
    );
    expect(mapStorageError('canceled').kind, AppErrorKind.cancelled);
    expect(mapStorageError('retry-limit-exceeded').kind, AppErrorKind.network);
    expect(mapStorageError('quota-exceeded').kind, AppErrorKind.rateLimited);
    expect(mapStorageError('something-else').kind, AppErrorKind.unknown);
  });
}
