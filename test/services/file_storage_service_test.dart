import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/services/file_storage_service.dart';

import '../helpers/fakes.dart';

final Uint8List _pdf = Uint8List.fromList(
  utf8.encode('%PDF-1.7\n1 0 obj << >> endobj\n%%EOF'),
);

Matcher _appError(AppErrorKind kind) =>
    throwsA(isA<AppException>().having((e) => e.kind, 'kind', kind));

void main() {
  late FakeAuthService auth;

  setUp(() async {
    auth = FakeAuthService();
    await auth.signInWithGoogle(); // signed in as testUser
  });
  tearDown(() => auth.dispose());

  CloudinaryStorageService service(
    MockClientHandler handler, {
    String cloudName = 'demo-cloud',
    String preset = 'internly_pdf',
  }) => CloudinaryStorageService(
    MockClient(handler),
    auth: auth,
    cloudName: cloudName,
    uploadPreset: preset,
  );

  http.Response ok(String folder) => http.Response(
    jsonEncode({
      'secure_url':
          'https://res.cloudinary.com/demo-cloud/image/upload/$folder/x.pdf',
      'public_id': '$folder/x',
      'bytes': _pdf.length,
      'created_at': '2026-10-21T10:00:00Z',
    }),
    200,
  );

  test(
    'uploads into the signed-in user\'s own folder and reports progress',
    () async {
      late String body;
      late Uri url;
      final progress = <double>[];
      final storage = service((request) async {
        url = request.url;
        body = latin1.decode(request.bodyBytes);
        return ok('internly/reports/${testUser.uid}');
      });

      final file = await storage.uploadPdf(
        folder: StorageFolder.reports,
        fileName: 'My Applications Report.pdf',
        bytes: _pdf,
        onProgress: progress.add,
      );

      expect(url.path, '/v1_1/demo-cloud/auto/upload');
      expect(body, contains('internly_pdf'));
      expect(body, contains('internly/reports/${testUser.uid}'));
      // Random suffix: 16 bytes = 32 hex characters after the slug.
      expect(body, matches(RegExp(r'my-applications-report-[0-9a-f]{32}')));
      expect(file.url, startsWith('https://res.cloudinary.com/'));
      expect(file.storagePath, 'internly/reports/${testUser.uid}/x');
      expect(file.sizeBytes, _pdf.length);
      expect(progress, isNotEmpty);
      expect(progress.last, 1);
    },
  );

  test('signed-out users cannot upload and no request is sent', () async {
    await auth.signOut();
    var calls = 0;
    final storage = service((_) async {
      calls++;
      return ok('x');
    });
    await expectLater(
      storage.uploadPdf(
        folder: StorageFolder.cvs,
        fileName: 'cv.pdf',
        bytes: _pdf,
      ),
      _appError(AppErrorKind.permissionDenied),
    );
    expect(calls, 0);
  });

  test('rejects files that are not PDFs or are too large', () async {
    final storage = service((_) async => ok('x'));
    await expectLater(
      storage.uploadPdf(
        folder: StorageFolder.cvs,
        fileName: 'cv.pdf',
        bytes: Uint8List.fromList(utf8.encode('<html>not a pdf</html>')),
      ),
      _appError(AppErrorKind.invalidInput),
    );
    await expectLater(
      storage.uploadPdf(
        folder: StorageFolder.cvs,
        fileName: 'cv.pdf',
        bytes: Uint8List(CloudinaryStorageService.maxBytes + 1),
      ),
      _appError(AppErrorKind.invalidInput),
    );
  });

  test('missing Cloudinary settings is a configuration error', () async {
    final storage = service((_) async => ok('x'), cloudName: '');
    await expectLater(
      storage.uploadPdf(
        folder: StorageFolder.reports,
        fileName: 'r.pdf',
        bytes: _pdf,
      ),
      _appError(AppErrorKind.configuration),
    );
  });

  test('maps Cloudinary and network failures to user-safe errors', () async {
    Future<void> expectKind(MockClientHandler handler, AppErrorKind kind) =>
        expectLater(
          service(handler).uploadPdf(
            folder: StorageFolder.reports,
            fileName: 'r.pdf',
            bytes: _pdf,
          ),
          _appError(kind),
        );

    await expectKind(
      (_) async => http.Response(
        jsonEncode({
          'error': {'message': 'Upload preset not found'},
        }),
        400,
      ),
      AppErrorKind.configuration,
    );
    await expectKind(
      (_) async => http.Response(
        jsonEncode({
          'error': {'message': 'File size too large. Got 20000000.'},
        }),
        400,
      ),
      AppErrorKind.invalidInput,
    );
    await expectKind(
      (_) async => http.Response('{}', 420),
      AppErrorKind.rateLimited,
    );
    await expectKind(
      (request) async =>
          throw http.ClientException('Connection closed', request.url),
      AppErrorKind.network,
    );
  });
}
