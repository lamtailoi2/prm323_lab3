import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/internships/viewmodels/apply_form_viewmodel.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/document_picker_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/file_storage_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/saved_internship_service.dart';
import 'package:internly/services/user_profile_service.dart';

import '../../helpers/fakes.dart';

/// A signed-in uid the test can change, as signing in with another account
/// does, so ViewModels that watch `currentUserIdProvider` rebuild.
class _Uid extends Notifier<String?> {
  @override
  String? build() => testUser.uid;

  void set(String? uid) => state = uid;
}

final _uidProvider = NotifierProvider<_Uid, String?>(_Uid.new);

void main() {
  late FakeInternshipService internships;
  late FakeUserProfileService profiles;
  late FakeSavedInternshipService saved;
  late FakeAnalyticsService analytics;
  late FakeDocumentPickerService picker;
  late FakeFileStorageService storage;
  late FakeExternalLinkService links;
  late FakeRemoteConfigService remoteConfig;
  late ProviderContainer container;

  final listing = testInternship(
    '1',
    title: 'Flutter Developer Intern',
    companyName: 'FPT Software',
  );
  final args = (internshipKey: listing.key, source: 'search');
  final profileCv = CvFile(
    fileName: 'Profile_CV.pdf',
    url: 'https://storage.example/cvs/profile.pdf',
    storagePath: 'cvs/uid-123/profile.pdf',
    sizeBytes: 420 * 1024,
    uploadedAt: DateTime(2026, 10, 14),
  );
  final picked = PickedDocument(name: 'Job_CV.pdf', bytes: pdfBytes());

  setUp(() {
    internships = FakeInternshipService()..byKey[listing.key] = listing;
    profiles = FakeUserProfileService(profile: UserProfile(cv: profileCv));
    saved = FakeSavedInternshipService();
    analytics = FakeAnalyticsService();
    picker = FakeDocumentPickerService();
    storage = FakeFileStorageService();
    links = FakeExternalLinkService();
    remoteConfig = FakeRemoteConfigService();
    container = ProviderContainer.test(
      overrides: [
        internshipServiceProvider.overrideWithValue(internships),
        userProfileServiceProvider.overrideWithValue(profiles),
        savedInternshipServiceProvider.overrideWithValue(saved),
        analyticsServiceProvider.overrideWithValue(analytics),
        documentPickerServiceProvider.overrideWithValue(picker),
        fileStorageServiceProvider.overrideWithValue(storage),
        externalLinkServiceProvider.overrideWithValue(links),
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
        currentUserIdProvider.overrideWith((ref) => ref.watch(_uidProvider)),
      ],
    );
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await saved.dispose();
    remoteConfig.dispose();
  });

  ApplyFormViewModel listen() {
    container.listen(applyFormViewModelProvider(args), (_, _) {});
    return container.read(applyFormViewModelProvider(args).notifier);
  }

  ApplyFormState read() => container.read(applyFormViewModelProvider(args));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('logs apply_start once with the listing and the Detail tab', () async {
    listen();
    await settle();
    // Another account rebuilds the ViewModel (CR-19).
    container.read(_uidProvider.notifier).set('other-uid');
    await settle();

    expect(analytics.events.where((e) => e == 'apply_start'), hasLength(1));
    expect(analytics.parameters['apply_start'], {
      'internship_id': listing.key,
      'source': 'search',
    });
  });

  test(
    'another account drops the CV uploaded for this internship (CR-19)',
    () async {
      picker.next = picked;
      final viewModel = listen();
      await settle();
      await viewModel.chooseCv();
      await viewModel.uploadSelected();
      expect(read().cv?.source, CvSource.uploaded);

      container.read(_uidProvider.notifier).set('other-uid');
      await settle();
      expect(read().uploadedCv, isNull);
      expect(read().pending, isNull);
    },
  );

  test(
    'a listing that left the pool opens from its saved copy (CR-19)',
    () async {
      internships.byKey.clear();
      saved.seed([listing]);
      listen();
      await settle();
      await settle();

      expect((read().internship as ViewData<Internship>).data.key, listing.key);
    },
  );

  test('loads the listing and selects the Profile CV', () async {
    listen();
    expect(read().internship, isA<ViewLoading<Internship>>());
    expect(read().profileLoaded, isFalse);
    await settle();

    expect((read().internship as ViewData<Internship>).data, listing);
    expect(read().profileLoaded, isTrue);
    expect(read().cv?.file, profileCv);
    expect(read().cv?.source, CvSource.profile);
  });

  test(
    'a listing gone from the pool and not saved is the empty state',
    () async {
      internships.byKey.clear();
      listen();
      await settle();
      expect(read().internship, isA<ViewEmpty<Internship>>());
    },
  );

  test('a load error shows the error state; Retry listens again', () async {
    internships.byKeyError = const AppException(
      AppErrorKind.network,
      'We could not reach Internly.',
    );
    final viewModel = listen();
    await settle();
    expect(read().internship, isA<ViewError<Internship>>());

    internships.byKeyError = null;
    viewModel.retry();
    await settle();
    expect(read().internship, isA<ViewData<Internship>>());
    expect(internships.watchByKeyCalls, 2);
  });

  test(
    'without a Profile CV, Continue to review returns nothing and flags it',
    () async {
      profiles.profile = const UserProfile();
      final viewModel = listen();
      await settle();

      expect(read().cv, isNull);
      expect(viewModel.continueToReview(), isNull);
      expect(read().missingCv, isTrue);
    },
  );

  test(
    'a profile load error is shown with Retry, not as "no CV" (CR-18)',
    () async {
      profiles.loadError = const AppException(
        AppErrorKind.network,
        'We could not reach Internly.',
      );
      final viewModel = listen();
      await settle();

      expect(read().profileLoaded, isTrue);
      expect(read().profileError?.kind, AppErrorKind.network);
      expect(read().cv, isNull);

      profiles.loadError = null;
      viewModel.retryProfile();
      expect(read().profileLoaded, isFalse);
      await settle();
      expect(read().profileError, isNull);
      expect(read().cv?.file, profileCv);
    },
  );

  test('Continue to review hands over the selected CV', () async {
    final viewModel = listen();
    await settle();

    final cv = viewModel.continueToReview();
    expect(cv?.file.storagePath, 'cvs/uid-123/profile.pdf');
    expect(cv?.source, CvSource.profile);
    expect(read().missingCv, isFalse);
  });

  test('Choose file selects a PDF without uploading it yet', () async {
    picker.next = picked;
    final viewModel = listen();
    await settle();

    await viewModel.chooseCv();
    expect(read().pending?.name, 'Job_CV.pdf');
    expect(read().isUploading, isFalse);
    expect(storage.uploadedNames, isEmpty);

    viewModel.removeSelected();
    expect(read().pending, isNull);
  });

  test(
    'an uploaded CV is used for this internship only and logs cv_upload',
    () async {
      profiles.profile = const UserProfile();
      picker.next = picked;
      storage.gate = Completer<void>();
      final viewModel = listen();
      await settle();
      viewModel.continueToReview();
      await viewModel.chooseCv();

      final upload = viewModel.uploadSelected();
      await settle();
      expect(read().isUploading, isTrue);
      expect(read().progress, 0.5);

      storage.gate!.complete();
      expect(await upload, isTrue);

      expect(read().isUploading, isFalse);
      expect(read().pending, isNull);
      expect(read().cv?.source, CvSource.uploaded);
      expect(read().cv?.file.storagePath, 'cvs/uid-123/Job_CV.pdf');
      expect(read().missingCv, isFalse);
      // The Profile default is left as it is (DC-26).
      expect(profiles.writes, isEmpty);
      expect(analytics.parameters['cv_upload'], {
        'source': 'apply_form',
        'file_size_kb': 2,
      });
    },
  );

  test('a failed upload keeps the file; uploading again succeeds', () async {
    picker.next = picked;
    storage.error = const AppException(
      AppErrorKind.network,
      'We could not upload the file. Check your connection and try again.',
    );
    final viewModel = listen();
    await settle();
    await viewModel.chooseCv();

    expect(await viewModel.uploadSelected(), isFalse);
    expect(read().uploadError?.kind, AppErrorKind.network);
    expect(read().pending?.name, 'Job_CV.pdf');
    expect(read().canRetry, isTrue);
    expect(analytics.events, isNot(contains('cv_upload')));

    storage.error = null;
    expect(await viewModel.uploadSelected(), isTrue);
    expect(read().uploadError, isNull);
    expect(read().cv?.source, CvSource.uploaded);
    expect(storage.uploadedNames, ['Job_CV.pdf']);
  });

  test(
    'a file over 10 MB is rejected when chosen and nothing is uploaded',
    () async {
      picker.next = PickedDocument(
        name: 'Huge.pdf',
        bytes: pdfBytes(maxUploadBytes + 1),
      );
      final viewModel = listen();
      await settle();

      await viewModel.chooseCv();
      expect(
        read().uploadError?.message,
        'The file must be a PDF of at most 10 MB.',
      );
      expect(read().pending, isNull);
      expect(await viewModel.uploadSelected(), isFalse);
      expect(storage.uploadedNames, isEmpty);
    },
  );

  test('closing the picker changes nothing', () async {
    final viewModel = listen();
    await settle();

    await viewModel.chooseCv();
    expect(picker.calls, 1);
    expect(read().pending, isNull);
    expect(read().uploadError, isNull);
    expect(read().cv?.source, CvSource.profile);
  });

  test('closing the CV sheet drops the chosen file and the error', () async {
    picker.next = picked;
    storage.error = const AppException(AppErrorKind.network, 'Offline.');
    final viewModel = listen();
    await settle();
    await viewModel.chooseCv();
    await viewModel.uploadSelected();

    viewModel.closeCvSheet();
    expect(read().pending, isNull);
    expect(read().uploadError, isNull);
    expect(read().cv?.source, CvSource.profile);
  });

  test('an upload still running when the sheet closes finishes', () async {
    picker.next = picked;
    storage.gate = Completer<void>();
    final viewModel = listen();
    await settle();
    await viewModel.chooseCv();

    final upload = viewModel.uploadSelected();
    await settle();
    viewModel.closeCvSheet();
    expect(read().isUploading, isTrue);

    storage.gate!.complete();
    await upload;
    expect(read().cv?.source, CvSource.uploaded);
  });

  test('Continue does not fall back to the Profile CV after a failed upload '
      '(CR-15)', () async {
    picker.next = picked;
    storage.error = const AppException(AppErrorKind.network, 'Offline.');
    final viewModel = listen();
    await settle();
    await viewModel.chooseCv();
    await viewModel.uploadSelected();

    expect(viewModel.continueToReview(), isNull);
    expect(read().missingCv, isFalse);

    viewModel.useProfileCv();
    expect(viewModel.continueToReview()?.source, CvSource.profile);
  });

  test('Use CV from Profile drops a failed upload', () async {
    picker.next = picked;
    storage.error = const AppException(AppErrorKind.network, 'Offline.');
    final viewModel = listen();
    await settle();
    await viewModel.chooseCv();
    await viewModel.uploadSelected();

    viewModel.useProfileCv();
    expect(read().uploadError, isNull);
    expect(read().pending, isNull);
    expect(read().cv?.source, CvSource.profile);
  });

  test('taps while a CV uploads are ignored', () async {
    picker.next = picked;
    storage.gate = Completer<void>();
    final viewModel = listen();
    await settle();
    await viewModel.chooseCv();

    final upload = viewModel.uploadSelected();
    await settle();
    expect(await viewModel.uploadSelected(), isFalse);
    await viewModel.chooseCv();
    viewModel.removeSelected();
    expect(viewModel.continueToReview(), isNull);
    expect(read().missingCv, isFalse);
    expect(picker.calls, 1);
    expect(read().pending?.name, 'Job_CV.pdf');

    storage.gate!.complete();
    await upload;
  });

  test('Preview opens the CV; a failure is returned to show', () async {
    final viewModel = listen();
    await settle();

    expect(await viewModel.previewCv(), isNull);
    expect(links.opened.single.toString(), profileCv.url);

    links.error = const AppException(
      AppErrorKind.unknown,
      'We could not open this file.',
    );
    expect(
      (await viewModel.previewCv())?.message,
      'We could not open this file.',
    );
  });

  test(
    'skill match compares Profile skills with the listing; off by config',
    () async {
      internships.byKey[listing.key] = testInternship(
        '1',
        skills: const ['Flutter', 'Dart', 'Git', 'REST API'],
      );
      profiles.profile = UserProfile(
        cv: profileCv,
        skills: const ['Flutter', 'Dart'],
      );
      listen();
      expect(read().skillMatch, isNull);
      await settle();

      expect(read().skillMatch?.matched, ['Flutter', 'Dart']);
      expect(read().skillMatch?.missing, ['Git', 'REST API']);

      remoteConfig.values[RemoteConfigKeys.cvMatchEnabled] = false;
      container.invalidate(applyFormViewModelProvider(args));
      listen();
      await settle();
      expect(read().skillMatch, isNull);
    },
  );
}
