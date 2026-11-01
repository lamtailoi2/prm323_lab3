import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/core/utils/skill_matcher.dart';
import 'package:internly/features/profile/viewmodels/edit_preferences_viewmodel.dart';
import 'package:internly/features/profile/viewmodels/edit_profile_viewmodel.dart';
import 'package:internly/features/profile/viewmodels/edit_skills_viewmodel.dart';
import 'package:internly/features/profile/viewmodels/open_cv_viewmodel.dart';
import 'package:internly/features/profile/viewmodels/profile_viewmodel.dart';
import 'package:internly/features/profile/viewmodels/update_cv_viewmodel.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/document_picker_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/file_storage_service.dart';
import 'package:internly/services/user_profile_service.dart';

import '../../helpers/fakes.dart';

const _network = AppException(
  AppErrorKind.network,
  'We could not save your changes. Check your connection and try again.',
);

void main() {
  late FakeAuthService auth;
  late FakeUserProfileService profiles;
  late FakeAnalyticsService analytics;
  late FakeDocumentPickerService picker;
  late FakeFileStorageService storage;
  late FakeExternalLinkService links;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService(initialUser: testUser);
    profiles = FakeUserProfileService();
    analytics = FakeAnalyticsService();
    picker = FakeDocumentPickerService();
    storage = FakeFileStorageService();
    links = FakeExternalLinkService();
    container = ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        userProfileServiceProvider.overrideWithValue(profiles),
        analyticsServiceProvider.overrideWithValue(analytics),
        documentPickerServiceProvider.overrideWithValue(picker),
        fileStorageServiceProvider.overrideWithValue(storage),
        externalLinkServiceProvider.overrideWithValue(links),
      ],
    );
  });

  tearDown(() async {
    await profiles.dispose();
    await auth.dispose();
  });

  /// Listens to the auth state first: Riverpod 3 pauses providers nobody
  /// listens to, so a bare `read(...future)` would never complete.
  Future<void> signedIn() async {
    container.listen(authStateChangesProvider, (_, _) {});
    await container.read(authStateChangesProvider.future);
  }

  /// Keeps the auto-dispose profile alive (as the screen does) and waits
  /// for the first snapshot.
  Future<void> loadProfile() async {
    await signedIn();
    container.listen(profileViewModelProvider, (_, _) {});
    await pumpEventQueue();
  }

  ViewState<ProfileOverview> profileState() =>
      container.read(profileViewModelProvider);

  group('ProfileViewModel', () {
    test('a profile never saved shows the Google account', () async {
      await loadProfile();

      final state = profileState();
      expect(state, isA<ViewData<ProfileOverview>>());
      final data = (state as ViewData<ProfileOverview>).data;
      expect(data.displayName, 'Test Student');
      expect(data.account.email, 'student@example.com');
      expect(data.profile, const UserProfile());
    });

    test('loading, then the stored profile', () async {
      profiles
        ..profile = const UserProfile(
          details: ProfileDetails(fullName: 'Minh Nguyen'),
          skills: ['Flutter'],
        )
        ..loadGate = Completer<void>();
      await signedIn();
      container.listen(profileViewModelProvider, (_, _) {});
      await pumpEventQueue();
      expect(profileState(), isA<ViewLoading<ProfileOverview>>());

      profiles.loadGate!.complete();
      await pumpEventQueue();
      final data = (profileState() as ViewData<ProfileOverview>).data;
      expect(data.displayName, 'Minh Nguyen');
      expect(data.profile.skills, ['Flutter']);
    });

    test('later writes reach the screen without a reload', () async {
      await loadProfile();
      await profiles.updateSkills(testUser.uid, ['Dart', 'SQL']);
      await pumpEventQueue();

      final data = (profileState() as ViewData<ProfileOverview>).data;
      expect(data.profile.skills, ['Dart', 'SQL']);
      expect(profiles.watchCalls, 1);
    });

    test('error, then Retry subscribes again', () async {
      profiles.loadError = const AppException(
        AppErrorKind.network,
        'We could not load your profile. Check your connection and try again.',
      );
      await loadProfile();
      final state = profileState();
      expect(state, isA<ViewError<ProfileOverview>>());
      expect(
        (state as ViewError<ProfileOverview>).error.kind,
        AppErrorKind.network,
      );

      profiles.loadError = null;
      await container.read(profileViewModelProvider.notifier).retry();
      await pumpEventQueue();
      expect(profileState(), isA<ViewData<ProfileOverview>>());
      expect(profiles.watchCalls, 2);
    });

    test('sign-out drops the profile (user-scoped, Lab 3 §6)', () async {
      await loadProfile();
      expect(profileState(), isA<ViewData<ProfileOverview>>());

      await auth.signOut();
      await pumpEventQueue();
      expect(profileState(), isA<ViewLoading<ProfileOverview>>());
    });
  });

  group('EditProfileViewModel', () {
    Future<EditProfileViewModel> open([
      ProfileDetails details = const ProfileDetails(),
    ]) async {
      profiles.profile = UserProfile(details: details);
      await loadProfile();
      container.listen(editProfileViewModelProvider, (_, _) {});
      return container.read(editProfileViewModelProvider.notifier);
    }

    EditProfileState editState() =>
        container.read(editProfileViewModelProvider);

    ProfileForm form({
      String fullName = 'Minh Nguyen',
      String headline = 'Software Engineering Student',
      String university = '',
      String major = '',
      String phone = '',
      String city = '',
      String bio = '',
    }) => (
      fullName: fullName,
      headline: headline,
      university: university,
      major: major,
      phone: phone,
      city: city,
      bio: bio,
    );

    test('academic standing reads like the frame', () {
      expect(
        EditProfileViewModel.academicStanding(3, 2026),
        'Year 3 · Graduating 2026',
      );
      expect(
        EditProfileViewModel.academicStanding(null, 2026),
        'Graduating 2026',
      );
      expect(EditProfileViewModel.academicStanding(null, null), isEmpty);
      expect(EditProfileViewModel.graduationYears(DateTime(2026, 10)), [
        for (var year = 2026; year <= 2034; year++) year,
      ]);
    });

    test('years start from the profile and toggle like chips', () async {
      final vm = await open(
        const ProfileDetails(yearOfStudy: 3, graduationYear: 2027),
      );
      expect(editState().yearOfStudy, 3);
      expect(editState().graduationYear, 2027);

      vm
        ..selectYearOfStudy(4)
        ..selectGraduationYear(2027);
      expect(editState().yearOfStudy, 4);
      expect(editState().graduationYear, isNull);
    });

    test('validation errors are shown and nothing is saved', () async {
      final vm = await open();

      final saved = await vm.save(
        form(fullName: '  ', headline: '', phone: '12', bio: 'a' * 301),
      );

      expect(saved, isFalse);
      final errors = editState().errors;
      expect(errors.fullName, 'Enter your full name to continue.');
      expect(errors.headline, 'Enter a headline to continue.');
      expect(errors.phone, 'Enter a valid phone number, e.g. 0908 123 456.');
      expect(errors.bio, 'Use 300 characters or fewer.');
      expect(errors.university, isNull);
      expect(profiles.writes, isEmpty);
    });

    test(
      'success trims the fields, saves them and logs profile_update',
      () async {
        final vm = await open();
        vm
          ..selectYearOfStudy(3)
          ..selectGraduationYear(2026);

        final saved = await vm.save(
          form(
            fullName: ' Minh Nguyen ',
            phone: '0908 123 456',
            major: 'Software Engineering',
            city: 'Ho Chi Minh City',
          ),
        );

        expect(saved, isTrue);
        expect(
          profiles.profile?.details,
          const ProfileDetails(
            fullName: 'Minh Nguyen',
            headline: 'Software Engineering Student',
            major: 'Software Engineering',
            yearOfStudy: 3,
            graduationYear: 2026,
            phone: '0908 123 456',
            city: 'Ho Chi Minh City',
          ),
        );
        expect(analytics.events, ['profile_update']);
        expect(analytics.parameters['profile_update'], {
          'section': 'details',
          'item_count': 7,
        });
        expect(editState().errors.isEmpty, isTrue);
        expect(editState().yearOfStudy, 3);
      },
    );

    test('a failed save keeps the form and exposes the message', () async {
      final vm = await open();
      profiles.saveError = _network;

      expect(await vm.save(form()), isFalse);
      expect(editState().save.error, _network);
      expect(analytics.events, isEmpty);
    });

    test('ignores taps while saving', () async {
      final vm = await open();
      profiles.saveGate = Completer<void>();

      final first = vm.save(form());
      expect(editState().save.isLoading, isTrue);
      expect(await vm.save(form()), isFalse);
      profiles.saveGate!.complete();
      expect(await first, isTrue);
      expect(profiles.writes, ['details']);
    });
  });

  group('EditSkillsViewModel', () {
    Future<EditSkillsViewModel> open(List<String> skills) async {
      profiles.profile = UserProfile(skills: skills);
      await loadProfile();
      container.listen(editSkillsViewModelProvider, (_, _) {});
      return container.read(editSkillsViewModelProvider.notifier);
    }

    EditSkillsState skillsState() =>
        container.read(editSkillsViewModelProvider);

    test('starts from the profile skills, suggested first (frame)', () async {
      await open(['React', 'Flutter']);
      expect(skillsState().selected, ['React', 'Flutter']);
      expect(skillsState().suggestions.take(3), ['React', 'Flutter', 'Dart']);
      expect(skillsState().suggestions.toSet(), knownSkills.toSet());
    });

    test('toggle adds and removes; clear all empties the list', () async {
      final vm = await open(['Flutter']);
      vm
        ..toggle('SQL')
        ..toggle('Flutter');
      expect(skillsState().selected, ['SQL']);

      vm.clearAll();
      expect(skillsState().selected, isEmpty);
    });

    test('search filters suggestions case-insensitively', () async {
      final vm = await open(const []);
      vm.search('script');
      expect(skillsState().suggestions, ['JavaScript', 'TypeScript']);

      vm.search('zzz');
      expect(skillsState().suggestions, isEmpty);

      vm.search('');
      expect(skillsState().suggestions, knownSkills);
    });

    test('save stores the draft and logs profile_update', () async {
      final vm = await open(['Flutter']);
      vm.toggle('Docker');

      expect(await vm.save(), isTrue);
      expect(profiles.profile?.skills, ['Flutter', 'Docker']);
      expect(analytics.parameters['profile_update'], {
        'section': 'skills',
        'item_count': 2,
      });
    });

    test('a failed save keeps the draft', () async {
      final vm = await open(['Flutter']);
      profiles.saveError = _network;
      vm.toggle('Git');

      expect(await vm.save(), isFalse);
      expect(skillsState().save.error, _network);
      expect(skillsState().selected, ['Flutter', 'Git']);
    });
  });

  group('EditPreferencesViewModel', () {
    Future<EditPreferencesViewModel> open([
      InternshipPreferences preferences = const InternshipPreferences(),
    ]) async {
      profiles.profile = UserProfile(preferences: preferences);
      await loadProfile();
      container.listen(editPreferencesViewModelProvider, (_, _) {});
      return container.read(editPreferencesViewModelProvider.notifier);
    }

    EditPreferencesState prefsState() =>
        container.read(editPreferencesViewModelProvider);

    test('starts from the stored preferences', () async {
      await open(
        const InternshipPreferences(
          targetRoles: [TargetRole.mobile],
          workModes: [WorkMode.remote],
          location: 'Hanoi',
        ),
      );
      expect(prefsState().targetRoles, {TargetRole.mobile});
      expect(prefsState().workModes, {WorkMode.remote});
      expect(prefsState().location, 'Hanoi');
    });

    test('work modes follow the frame order', () {
      expect(EditPreferencesViewModel.workModeOptions, [
        WorkMode.hybrid,
        WorkMode.remote,
        WorkMode.onSite,
      ]);
    });

    test('save stores roles and modes in a stable order', () async {
      final vm = await open();
      vm
        ..toggleRole(TargetRole.qaTester)
        ..toggleRole(TargetRole.mobile)
        ..toggleWorkMode(WorkMode.onSite)
        ..toggleWorkMode(WorkMode.hybrid)
        ..setLocation('  Da Nang ');

      expect(await vm.save(), isTrue);
      expect(
        profiles.profile?.preferences,
        const InternshipPreferences(
          targetRoles: [TargetRole.mobile, TargetRole.qaTester],
          workModes: [WorkMode.hybrid, WorkMode.onSite],
          location: 'Da Nang',
        ),
      );
      expect(analytics.parameters['profile_update'], {
        'section': 'preferences',
        'item_count': 5,
      });
    });

    test('an empty location starts from the current city', () async {
      profiles.profile = const UserProfile(
        details: ProfileDetails(city: 'Thu Duc'),
      );
      await loadProfile();
      container.listen(editPreferencesViewModelProvider, (_, _) {});
      expect(prefsState().location, 'Thu Duc');
      expect(profiles.writes, isEmpty);
    });

    test('a stored location wins over the current city', () async {
      profiles.profile = const UserProfile(
        details: ProfileDetails(city: 'Thu Duc'),
        preferences: InternshipPreferences(location: 'Hanoi'),
      );
      await loadProfile();
      container.listen(editPreferencesViewModelProvider, (_, _) {});
      expect(prefsState().location, 'Hanoi');
    });

    test('an empty location is stored as not set', () async {
      final vm = await open(const InternshipPreferences(location: 'Hanoi'));
      vm.setLocation('   ');
      expect(await vm.save(), isTrue);
      expect(profiles.profile?.preferences.location, isNull);
    });

    test('a too-long location is a validation error', () async {
      final vm = await open();
      vm.setLocation('a' * 101);
      expect(await vm.save(), isFalse);
      expect(prefsState().locationError, 'Use 100 characters or fewer.');
      expect(profiles.writes, isEmpty);
    });
  });

  group('UpdateCvViewModel', () {
    UpdateCvViewModel listen() {
      container.listen(updateCvViewModelProvider, (_, _) {});
      return container.read(updateCvViewModelProvider.notifier);
    }

    UpdateCvState cvState() => container.read(updateCvViewModelProvider);

    test(
      'choose keeps the picked PDF; a closed picker changes nothing',
      () async {
        final vm = listen();
        await vm.choose();
        expect(cvState().selected, isNull);
        expect(cvState().error, isNull);

        picker.next = PickedDocument(name: 'cv.pdf', bytes: pdfBytes());
        await vm.choose();
        expect(cvState().selected?.name, 'cv.pdf');

        vm.remove();
        expect(cvState().selected, isNull);
      },
    );

    test('a file over 10 MB is rejected before uploading', () async {
      final vm = listen();
      picker.next = PickedDocument(
        name: 'huge.pdf',
        bytes: pdfBytes(maxUploadBytes + 1),
      );
      await vm.choose();

      expect(cvState().selected, isNull);
      expect(
        cvState().error?.message,
        'The file must be a PDF of at most 10 MB.',
      );
      expect(await vm.upload(), isFalse);
      expect(storage.uploadedNames, isEmpty);
    });

    test('upload reports progress, saves the CV and logs cv_upload', () async {
      await signedIn();
      final vm = listen();
      picker.next = PickedDocument(name: 'Minh_CV.pdf', bytes: pdfBytes(4096));
      await vm.choose();
      storage.gate = Completer<void>();

      final upload = vm.upload();
      await pumpEventQueue();
      expect(cvState().isUploading, isTrue);
      expect(cvState().progress, 0.5);

      storage.gate!.complete();
      expect(await upload, isTrue);
      expect(cvState().isUploading, isFalse);
      expect(profiles.profile?.cv?.fileName, 'Minh_CV.pdf');
      expect(
        profiles.profile?.cv?.url,
        'https://storage.example/cvs/Minh_CV.pdf',
      );
      expect(profiles.profile?.cv?.sizeBytes, 4096);
      expect(analytics.parameters['cv_upload'], {
        'source': 'profile',
        'file_size_kb': 4,
      });
    });

    test('a failed upload keeps the file so the student can retry', () async {
      await signedIn();
      final vm = listen();
      picker.next = PickedDocument(name: 'cv.pdf', bytes: pdfBytes());
      await vm.choose();
      storage.error = const AppException(
        AppErrorKind.network,
        'We could not upload the file. Check your connection and try again.',
      );

      expect(await vm.upload(), isFalse);
      expect(cvState().selected?.name, 'cv.pdf');
      expect(cvState().error?.kind, AppErrorKind.network);
      expect(cvState().isUploading, isFalse);
      expect(profiles.writes, isEmpty);
      expect(analytics.events, isEmpty);
    });

    test('a picker failure is shown without losing the selection', () async {
      final vm = listen();
      picker.next = PickedDocument(name: 'cv.pdf', bytes: pdfBytes());
      await vm.choose();
      picker.error = const AppException(
        AppErrorKind.unknown,
        'We could not open this file. Choose it again or pick another PDF.',
      );
      await vm.choose();

      expect(cvState().selected?.name, 'cv.pdf');
      expect(cvState().error?.kind, AppErrorKind.unknown);
    });
  });

  group('OpenCvViewModel', () {
    final cv = CvFile(
      fileName: 'cv.pdf',
      url: 'https://storage.example/cvs/cv.pdf',
      storagePath: 'cvs/uid-123/cv.pdf',
      sizeBytes: 2048,
      uploadedAt: DateTime(2026, 10, 14),
    );

    test('opens the CV download URL', () async {
      container.listen(openCvViewModelProvider, (_, _) {});
      await container.read(openCvViewModelProvider.notifier).open(cv);
      expect(links.opened, [Uri.parse(cv.url)]);
      expect(container.read(openCvViewModelProvider).hasError, isFalse);
    });

    test('exposes a failure for the SnackBar', () async {
      container.listen(openCvViewModelProvider, (_, _) {});
      links.error = const AppException(
        AppErrorKind.unknown,
        'No app on this device can open this file.',
      );
      await container.read(openCvViewModelProvider.notifier).open(cv);
      expect(container.read(openCvViewModelProvider).error, links.error);
    });
  });
}
