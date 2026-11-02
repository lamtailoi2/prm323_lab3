import 'dart:async';
import 'dart:typed_data';

import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/utils/job_key.dart';
import 'package:internly/features/internships/models/search_history_entry.dart';
import 'package:internly/models/app_user.dart';
import 'package:internly/models/cv_validation_result.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/crashlytics_service.dart';
import 'package:internly/services/cv_validation_service.dart';
import 'package:internly/services/document_picker_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/file_storage_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/saved_internship_service.dart';
import 'package:internly/services/saved_service.dart';
import 'package:internly/services/search_history_service.dart';
import 'package:internly/services/user_profile_service.dart';

const testUser = AppUser(
  uid: 'uid-123',
  email: 'student@example.com',
  displayName: 'Test Student',
);

/// A listing with stable IDs for tests: `job-<id>` and its short key.
Internship testInternship(
  String id, {
  String? title,
  String? companyName,
  String? location,
  WorkMode? workMode,
  String? salary,
  String? postedText,
  DateTime? postedAt,
  String? logoUrl,
  int? searchRank,
  String? searchKeyword,
  List<String> skills = const <String>[],
  String? description,
  List<JobHighlight> highlights = const <JobHighlight>[],
  String? scheduleType,
  String? via,
}) {
  final jobId = 'job-$id';
  return Internship(
    jobId: jobId,
    key: jobKeyFor(jobId),
    title: title ?? 'Internship $id',
    companyName: companyName ?? 'Company $id',
    location: location ?? 'Ho Chi Minh City, Vietnam',
    workMode: workMode,
    salary: salary,
    postedTextSource: postedText,
    postedAt: postedAt,
    logoUrl: logoUrl,
    searchRank: searchRank,
    searchKeyword: searchKeyword,
    skills: skills,
    description: description,
    highlights: highlights,
    scheduleType: scheduleType,
    via: via,
  );
}

/// In-memory [InternshipService] backed by a broadcast stream. Tests set
/// [results] before listening, or call [emit] to model a Firestore update.
class FakeInternshipService implements InternshipService {
  List<Internship> results = const <Internship>[];
  AppException? error;
  Completer<void>? gate;
  int watchCalls = 0;

  final StreamController<List<Internship>> _updates =
      StreamController<List<Internship>>.broadcast();

  @override
  Stream<List<Internship>> watchActive() async* {
    watchCalls++;
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    yield results;
    yield* _updates.stream;
  }

  /// Pushes a new snapshot, as Firestore would.
  void emit(List<Internship> next) {
    results = next;
    _updates.add(next);
  }

  /// Pushes a listener error.
  void fail(AppException failure) {
    error = failure;
    _updates.addError(failure);
  }

  /// `/internships/{key}` documents for [watchByKey]; a missing key models a
  /// listing the sync function deleted.
  final Map<String, Internship> byKey = <String, Internship>{};
  AppException? byKeyError;
  Completer<void>? byKeyGate;
  int watchByKeyCalls = 0;
  final StreamController<Internship?> _byKeyUpdates =
      StreamController<Internship?>.broadcast();

  @override
  Stream<Internship?> watchByKey(String key) async* {
    watchByKeyCalls++;
    await byKeyGate?.future;
    final failure = byKeyError;
    if (failure != null) throw failure;
    yield byKey[key];
    yield* _byKeyUpdates.stream;
  }

  /// Pushes a new snapshot of one listing (`null` = deleted).
  void emitOne(Internship? next) => _byKeyUpdates.add(next);

  Future<void> dispose() async {
    await _updates.close();
    await _byKeyUpdates.close();
  }
}

/// A tracked application with stable IDs for tests: `job-<id>` and its key.
InternshipApplication testApplication(
  String id, {
  String? title,
  String? companyName,
  DateTime? appliedAt,
  ApplicationStatus status = ApplicationStatus.submitted,
  DateTime? nextStepAt,
}) {
  return InternshipApplication(
    jobKey: jobKeyFor('job-$id'),
    title: title ?? 'Position $id',
    companyName: companyName ?? 'Company $id',
    appliedAt: appliedAt ?? DateTime(2026, 10, 1),
    status: status,
    nextStepAt: nextStepAt,
  );
}

/// In-memory [ApplicationService] backed by a broadcast stream. Tests set
/// [results] before listening, or call [emit] to model a Firestore update.
class FakeApplicationService implements ApplicationService {
  List<InternshipApplication> results = const <InternshipApplication>[];

  /// Thrown by the next subscription; usually an [AppException], but any
  /// error exercises the ViewModel's fallback.
  Object? error;
  Completer<void>? gate;
  int watchCalls = 0;

  final StreamController<List<InternshipApplication>> _updates =
      StreamController<List<InternshipApplication>>.broadcast();

  @override
  Stream<List<InternshipApplication>> watchApplications() async* {
    watchCalls++;
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    yield results;
    yield* _updates.stream;
  }

  /// Pushes a new snapshot, as Firestore would.
  void emit(List<InternshipApplication> next) {
    results = next;
    _updates.add(next);
  }

  /// Pushes a listener error.
  void fail(Object failure) {
    error = failure;
    _updates.addError(failure);
  }

  Future<void> dispose() => _updates.close();
}

/// In-memory [RemoteConfigService] seeded with the in-app defaults.
class FakeRemoteConfigService implements RemoteConfigService {
  final Map<String, Object> values = <String, Object>{
    RemoteConfigKeys.homeRecommendedLimit: 5,
    RemoteConfigKeys.homeRecentLimit: 10,
    RemoteConfigKeys.cvMatchEnabled: true,
  };

  final StreamController<void> _updates = StreamController<void>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  bool getBool(String key) => values[key] as bool? ?? false;

  @override
  int getInt(String key) => values[key] as int? ?? 0;

  @override
  String getString(String key) => values[key] as String? ?? '';

  @override
  Map<String, ({String value, String source})> snapshot() => {
    for (final entry in values.entries)
      entry.key: (value: '${entry.value}', source: 'default'),
  };

  /// Changes [key] and notifies listeners like a console update would.
  void publish(String key, Object value) {
    values[key] = value;
    _updates.add(null);
  }

  @override
  Stream<void> get onUpdated => _updates.stream;

  @override
  void dispose() => _updates.close();
}

/// In-memory [AuthService]. Sign-in succeeds with [testUser] unless
/// [signInError] is set.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? initialUser}) : _user = initialUser;

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _user;

  AppException? signInError;
  AppException? signOutError;
  int signInCalls = 0;
  int signOutCalls = 0;

  /// Completes the next sign-in only when the test calls `complete()`.
  Completer<void>? signInGate;

  /// Emits the current user first, then every change. Subscribes to the
  /// change stream synchronously on listen, so no event can be lost.
  @override
  Stream<AppUser?> authStateChanges() {
    StreamSubscription<AppUser?>? changes;
    late final StreamController<AppUser?> controller;
    controller = StreamController<AppUser?>(
      onListen: () {
        controller.add(_user);
        changes = _controller.stream.listen(controller.add);
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithGoogle() async {
    signInCalls++;
    await signInGate?.future;
    final error = signInError;
    if (error != null) throw error;
    _emit(testUser);
    return testUser;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    final error = signOutError;
    if (error != null) throw error;
    _emit(null);
  }

  void _emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  Future<void> dispose() => _controller.close();
}

/// Records Crashlytics calls instead of sending them.
class FakeCrashlyticsService implements CrashlyticsService {
  final Map<String, Object> customKeys = <String, Object>{};
  final List<Object> recordedErrors = <Object>[];
  String? userId;

  @override
  void registerGlobalErrorHandlers() {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async => recordedErrors.add(error);

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setUserId(String? uid) async => userId = uid;

  @override
  Future<void> setCustomKey(String key, Object value) async =>
      customKeys[key] = value;

  @override
  void crashForTesting() {}
}

/// In-memory [SearchHistoryService] backed by a broadcast stream, keyed by
/// uid like Firestore would be.
class FakeSearchHistoryService implements SearchHistoryService {
  final Map<String, List<SearchHistoryEntry>> entriesByUid =
      <String, List<SearchHistoryEntry>>{};
  AppException? error;
  int nextId = 0;

  /// Holds [record] open, as an offline Firestore write never completes.
  Completer<void>? recordGate;

  final StreamController<List<SearchHistoryEntry>> _updates =
      StreamController<List<SearchHistoryEntry>>.broadcast();

  @override
  Stream<List<SearchHistoryEntry>> watchRecent(
    String uid, {
    int limit = 10,
  }) async* {
    final failure = error;
    if (failure != null) throw failure;
    yield _entriesFor(uid, limit);
    yield* _updates.stream.map((_) => _entriesFor(uid, limit));
  }

  List<SearchHistoryEntry> _entriesFor(String uid, int limit) {
    final entries = entriesByUid[uid] ?? const <SearchHistoryEntry>[];
    return entries.take(limit).toList();
  }

  @override
  Future<void> record(String uid, String term) async {
    if (recordGate case final gate?) await gate.future;
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    final entries = entriesByUid.putIfAbsent(uid, () => <SearchHistoryEntry>[])
      ..removeWhere((entry) => entry.term == trimmed);
    entries.insert(
      0,
      SearchHistoryEntry(
        id: 'entry-${nextId++}',
        term: trimmed,
        searchedAt: DateTime.now(),
      ),
    );
    _updates.add(const <SearchHistoryEntry>[]);
  }

  @override
  Future<void> clear(String uid) async {
    entriesByUid[uid] = <SearchHistoryEntry>[];
    _updates.add(const <SearchHistoryEntry>[]);
  }

  /// Pushes a listener error, as a Firestore stream would.
  void fail(AppException failure) {
    error = failure;
    _updates.addError(failure);
  }

  Future<void> dispose() => _updates.close();
}

/// Records analytics calls instead of sending them.
class FakeAnalyticsService implements AnalyticsService {
  final List<String> events = <String>[];
  final List<Map<String, Object>?> eventParameters = <Map<String, Object>?>[];
  final List<String> screens = <String>[];
  final List<String?> userIds = <String?>[];

  @override
  Future<void> logLogin({required String method}) async =>
      events.add('login:$method');

  @override
  Future<void> logLogout() async => events.add('logout');

  @override
  Future<void> logScreenView({required String screenName}) async =>
      screens.add(screenName);

  /// Parameters of the last custom event with each name.
  final Map<String, Map<String, Object>?> parameters =
      <String, Map<String, Object>?>{};

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    events.add(name);
    eventParameters.add(parameters);
    this.parameters[name] = parameters;
  }

  @override
  Future<void> setUserId(String? uid) async => userIds.add(uid);
}

/// In-memory [SavedService] for tests.
class FakeSavedService implements SavedService {
  final Map<String, Set<String>> savedByUid = <String, Set<String>>{};
  AppException? error;
  final StreamController<List<String>> _updates =
      StreamController<List<String>>.broadcast();

  @override
  Stream<List<String>> watchSavedIds(String uid) async* {
    final failure = error;
    if (failure != null) throw failure;
    yield (savedByUid[uid] ?? const <String>{}).toList(growable: false);
    yield* _updates.stream;
  }

  @override
  Future<void> save(String uid, String internshipId) async {
    final failure = error;
    if (failure != null) throw failure;
    final set = savedByUid.putIfAbsent(uid, () => <String>{});
    set.add(internshipId);
    _updates.add(set.toList(growable: false));
  }

  @override
  Future<void> unsave(String uid, String internshipId) async {
    final failure = error;
    if (failure != null) throw failure;
    final set = savedByUid.putIfAbsent(uid, () => <String>{});
    set.remove(internshipId);
    _updates.add(set.toList(growable: false));
  }

  Future<void> dispose() => _updates.close();
}

/// In-memory [SavedInternshipService] that keeps the saved keys in a map and
/// pushes every change to [watchSaved] listeners, as Firestore would.
class FakeSavedInternshipService implements SavedInternshipService {
  final Map<String, Internship> _saved = <String, Internship>{};
  final StreamController<List<Internship>> _updates =
      StreamController<List<Internship>>.broadcast();

  AppException? error;
  Completer<void>? gate;
  int watchCalls = 0;
  int saveCalls = 0;
  int removeCalls = 0;

  /// Keys currently saved, in insertion order.
  List<String> get savedKeys => _saved.keys.toList(growable: false);

  /// Pre-fills the saved list, as a previous session would have left it.
  void seed(Iterable<Internship> internships) {
    for (final internship in internships) {
      _saved[internship.key] = internship;
    }
    _updates.add(_snapshot);
  }

  @override
  Stream<List<Internship>> watchSaved() {
    watchCalls++;
    late final StreamController<List<Internship>> controller;
    StreamSubscription<List<Internship>>? changes;
    controller = StreamController<List<Internship>>(
      onListen: () {
        controller.add(_snapshot);
        changes = _updates.stream.listen(controller.add);
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> save(Internship internship) async {
    saveCalls++;
    await gate?.future;
    if (error case final failure?) throw failure;
    _saved[internship.key] = internship;
    _updates.add(_snapshot);
  }

  @override
  Future<void> remove(String internshipKey) async {
    removeCalls++;
    await gate?.future;
    if (error case final failure?) throw failure;
    _saved.remove(internshipKey);
    _updates.add(_snapshot);
  }

  List<Internship> get _snapshot =>
      List<Internship>.unmodifiable(_saved.values);

  Future<void> dispose() => _updates.close();
}

/// In-memory `users/{uid}` document. Writes merge into [profile] and are
/// pushed to listeners, as a Firestore snapshot listener would.
class FakeUserProfileService implements UserProfileService {
  FakeUserProfileService({this.profile});

  /// `null` models a profile that has never been saved.
  UserProfile? profile;
  AppException? loadError;
  AppException? saveError;
  Completer<void>? loadGate;
  Completer<void>? saveGate;
  int watchCalls = 0;
  final List<String> writes = <String>[];

  final StreamController<UserProfile?> _updates =
      StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    watchCalls++;
    await loadGate?.future;
    final failure = loadError;
    if (failure != null) throw failure;
    yield profile;
    yield* _updates.stream;
  }

  @override
  Future<void> updateDetails(String uid, ProfileDetails details) =>
      _write('details', (current) => _copy(current, details: details));

  @override
  Future<void> updateSkills(String uid, List<String> skills) =>
      _write('skills', (current) => _copy(current, skills: skills));

  @override
  Future<void> updatePreferences(
    String uid,
    InternshipPreferences preferences,
  ) => _write(
    'preferences',
    (current) => _copy(current, preferences: preferences),
  );

  @override
  Future<void> updateCv(String uid, CvFile cv) =>
      _write('cv', (current) => _copy(current, cv: cv));

  Future<void> _write(
    String section,
    UserProfile Function(UserProfile current) change,
  ) async {
    await saveGate?.future;
    final failure = saveError;
    if (failure != null) throw failure;
    writes.add(section);
    profile = change(profile ?? const UserProfile());
    _updates.add(profile);
  }

  /// A merge write of one section, as `SetOptions(merge: true)` does.
  static UserProfile _copy(
    UserProfile current, {
    ProfileDetails? details,
    List<String>? skills,
    InternshipPreferences? preferences,
    CvFile? cv,
  }) => UserProfile(
    details: details ?? current.details,
    skills: skills ?? current.skills,
    preferences: preferences ?? current.preferences,
    cv: cv ?? current.cv,
  );

  Future<void> dispose() => _updates.close();
}

/// Minimal valid PDF bytes (`%PDF-` signature) of [length] bytes.
Uint8List pdfBytes([int length = 2048]) {
  final bytes = Uint8List(length);
  bytes.setAll(0, '%PDF-'.codeUnits);
  return bytes;
}

/// Returns [next] from the picker; `null` models a closed picker.
class FakeDocumentPickerService implements DocumentPickerService {
  PickedDocument? next;
  AppException? error;
  int calls = 0;

  @override
  Future<PickedDocument?> pickPdf() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return next;
  }
}

/// Records uploads and reports progress in two steps.
class FakeFileStorageService implements FileStorageService {
  AppException? error;
  Completer<void>? gate;
  final List<String> uploadedNames = <String>[];

  @override
  Future<UploadedFile> uploadPdf({
    required StorageFolder folder,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.5);
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    onProgress?.call(1);
    uploadedNames.add(fileName);
    return UploadedFile(
      url: 'https://storage.example/${folder.path}/$fileName',
      storagePath: '${folder.path}/uid-123/$fileName',
      fileName: fileName,
      sizeBytes: bytes.length,
      uploadedAt: DateTime(2026, 10, 28),
    );
  }
}

/// Records CV validation calls instead of reaching Cloud Functions.
class FakeCvValidationService implements CvValidationService {
  CvValidationResult result = const CvValidationResult(isValid: true);
  AppException? error;

  /// Completes the next check only when the test calls `complete()`.
  Completer<void>? gate;

  int calls = 0;
  final List<String> paths = <String>[];

  @override
  Future<CvValidationResult> validate(String storagePath) async {
    calls++;
    paths.add(storagePath);
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

/// Records opened links instead of launching them.
class FakeExternalLinkService implements ExternalLinkService {
  final List<Uri> opened = <Uri>[];
  AppException? error;

  @override
  Future<void> open(Uri uri) async {
    final failure = error;
    if (failure != null) throw failure;
    opened.add(uri);
  }
}
