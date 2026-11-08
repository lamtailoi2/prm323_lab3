import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/cv_library.dart';
import 'package:internly/models/user_profile.dart';

void main() {
  CvFile cv(
    String path, {
    String? id,
    String? fileName,
    DateTime? uploadedAt,
  }) => CvFile(
    id: id,
    fileName: fileName ?? path.split('/').last,
    url: 'https://storage.example/$path',
    storagePath: path,
    sizeBytes: 2048,
    uploadedAt: uploadedAt ?? DateTime.utc(2026, 10, 1),
  );

  group('mergeLegacyCv', () {
    test('an empty library and no legacy entry stay empty', () {
      expect(mergeLegacyCv(const [], null), isEmpty);
    });

    test('appends the legacy entry when it is not in the library', () {
      final library = cv('cvs/uid-1/new.pdf', id: 'cv-1');
      final legacy = cv('cvs/uid-1/old.pdf');

      final merged = mergeLegacyCv([library], legacy);

      expect(merged, hasLength(2));
      expect(merged.first, library);
      expect(merged.last, legacy.copyWith(id: legacyCvId));
      expect(merged.last.id, legacyCvId);
    });

    test('does not duplicate the legacy entry by storage path', () {
      final legacy = cv('cvs/uid-1/old.pdf');
      final inLibrary = legacy.copyWith(id: 'cv-1');

      final merged = mergeLegacyCv([inLibrary], legacy);

      expect(merged, [inLibrary]);
    });

    test('keeps the library order', () {
      final newest = cv('cvs/uid-1/new.pdf', id: 'cv-1');
      final older = cv('cvs/uid-1/old.pdf', id: 'cv-2');

      expect(mergeLegacyCv([newest, older], null), [newest, older]);
    });
  });

  group('defaultCv', () {
    test('is null for an empty library', () {
      expect(defaultCv(const [], null, null), isNull);
      expect(defaultCv(const [], 'cv-1', null), isNull);
    });

    test('follows defaultCvId first', () {
      final newest = cv(
        'cvs/uid-1/new.pdf',
        id: 'cv-new',
        uploadedAt: DateTime.utc(2026, 10, 2),
      );
      final older = cv(
        'cvs/uid-1/old.pdf',
        id: 'cv-old',
        uploadedAt: DateTime.utc(2026, 10, 1),
      );

      expect(defaultCv([newest, older], 'cv-old', null), older);
    });

    test('uses the legacy entry when there is no id', () {
      final library = cv(
        'cvs/uid-1/new.pdf',
        id: 'cv-new',
        uploadedAt: DateTime.utc(2026, 10, 2),
      );
      final legacy = cv('cvs/uid-1/old.pdf');

      expect(
        defaultCv([library], null, legacy)?.storagePath,
        legacy.storagePath,
      );
    });

    test('falls back to the newest CV when the id no longer exists', () {
      final newest = cv(
        'cvs/uid-1/new.pdf',
        id: 'cv-new',
        uploadedAt: DateTime.utc(2026, 10, 2),
      );
      final older = cv(
        'cvs/uid-1/old.pdf',
        id: 'cv-old',
        uploadedAt: DateTime.utc(2026, 10, 1),
      );

      expect(defaultCv([older, newest], 'cv-deleted', null), newest);
    });

    test('the legacy entry wins over the newest when it is the default', () {
      final newer = cv(
        'cvs/uid-1/newer.pdf',
        id: 'cv-newer',
        uploadedAt: DateTime.utc(2026, 10, 3),
      );
      final legacy = cv(
        'cvs/uid-1/legacy.pdf',
        uploadedAt: DateTime.utc(2026, 9, 1),
      );

      expect(
        defaultCv([newer], 'cv-missing', legacy)?.storagePath,
        legacy.storagePath,
      );
    });
  });

  test('isSameCv compares storage paths, not file names', () {
    final first = cv('cvs/uid-1/first.pdf', id: 'cv-1', fileName: 'cv.pdf');
    final second = cv('cvs/uid-1/second.pdf', id: 'cv-2', fileName: 'cv.pdf');

    expect(first.fileName, second.fileName);
    expect(isSameCv(first, second), isFalse);
    expect(isSameCv(first, first.copyWith(id: 'cv-3')), isTrue);
  });
}
