import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/internships/models/search_filter_criteria.dart';
import 'package:internly/features/internships/models/search_history_entry.dart';
import 'package:internly/features/internships/viewmodels/search_viewmodel.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/search_history_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeInternshipService internships;
  late FakeSearchHistoryService history;
  late ProviderContainer container;

  setUp(() {
    internships = FakeInternshipService();
    history = FakeSearchHistoryService();
    container = ProviderContainer.test(
      overrides: [
        internshipServiceProvider.overrideWithValue(internships),
        searchHistoryServiceProvider.overrideWithValue(history),
        currentUserIdProvider.overrideWithValue(testUser.uid),
      ],
    );
  });

  tearDown(() async {
    await internships.dispose();
    await history.dispose();
  });

  SearchViewModel listen() {
    container.listen(searchViewModelProvider, (_, _) {});
    return container.read(searchViewModelProvider.notifier);
  }

  SearchState read() => container.read(searchViewModelProvider);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  List<SkillCount> trending() =>
      (read().trending as ViewData<List<SkillCount>>).data;

  List<SearchHistoryEntry> recent() =>
      (read().recentSearches as ViewData<List<SearchHistoryEntry>>).data;

  test('starts loading for both trending skills and recent searches', () {
    listen();
    expect(read().trending, isA<ViewLoading<List<SkillCount>>>());
    expect(read().recentSearches, isA<ViewLoading<List<SearchHistoryEntry>>>());
    expect(read().workMode, isNull);
  });

  test('ranks known skills by how many listings mention them', () async {
    internships.results = [
      testInternship('1', skills: ['React', 'Flutter']),
      testInternship('2', skills: ['Flutter']),
      testInternship('3', skills: ['Flutter', 'Python']),
    ];
    listen();
    await settle();

    expect(read().trending, isA<ViewData<List<SkillCount>>>());
    expect(trending().first, const SkillCount('Flutter', 3));
    expect(trending()[1].skill, anyOf('React', 'Python'));
  });

  test('no listings is the empty trending state', () async {
    listen();
    await settle();
    expect(read().trending, isA<ViewEmpty<List<SkillCount>>>());
  });

  test(
    'a trending stream failure is the error state; Retry subscribes again',
    () async {
      internships.error = const AppException(
        AppErrorKind.network,
        'We could not load internships. Check your connection and try again.',
      );
      final vm = listen();
      await settle();
      expect(read().trending, isA<ViewError<List<SkillCount>>>());

      internships
        ..error = null
        ..results = [
          testInternship('1', skills: ['Flutter']),
        ];
      await vm.retryTrending();
      await settle();
      expect(read().trending, isA<ViewData<List<SkillCount>>>());
      expect(internships.watchCalls, 2);
    },
  );

  test('Retry trending is ignored while already loading', () async {
    internships.gate = Completer<void>();
    final vm = listen();
    await settle();
    unawaited(vm.retryTrending());
    expect(internships.watchCalls, 1);
    internships.gate!.complete();
  });

  test("loads this student's recent searches, newest first", () async {
    history.entriesByUid[testUser.uid] = [
      SearchHistoryEntry(
        id: 'a',
        term: 'Flutter intern',
        searchedAt: DateTime.now(),
      ),
    ];
    listen();
    await settle();

    expect(read().recentSearches, isA<ViewData<List<SearchHistoryEntry>>>());
    expect(recent().single.term, 'Flutter intern');
  });

  test('no recent searches is the empty state', () async {
    listen();
    await settle();
    expect(read().recentSearches, isA<ViewEmpty<List<SearchHistoryEntry>>>());
  });

  test('no signed-in user is the empty recent-searches state', () async {
    container = ProviderContainer.test(
      overrides: [
        internshipServiceProvider.overrideWithValue(internships),
        searchHistoryServiceProvider.overrideWithValue(history),
        currentUserIdProvider.overrideWithValue(null),
      ],
    );
    listen();
    await settle();
    expect(read().recentSearches, isA<ViewEmpty<List<SearchHistoryEntry>>>());
  });

  test(
    'a recent-searches failure is the error state; Retry subscribes again',
    () async {
      history.fail(
        const AppException(
          AppErrorKind.unknown,
          'We could not load recent searches. Try again in a moment.',
        ),
      );
      final vm = listen();
      await settle();
      expect(read().recentSearches, isA<ViewError<List<SearchHistoryEntry>>>());

      history.error = null;
      history.entriesByUid[testUser.uid] = [
        SearchHistoryEntry(
          id: 'a',
          term: 'Flutter',
          searchedAt: DateTime.now(),
        ),
      ];
      await vm.retryRecentSearches();
      await settle();
      expect(read().recentSearches, isA<ViewData<List<SearchHistoryEntry>>>());
    },
  );

  test('selecting a work mode sets it; selecting it again clears it', () async {
    final vm = listen();
    await settle();

    vm.selectWorkMode(WorkMode.remote);
    expect(read().workMode, WorkMode.remote);

    vm.selectWorkMode(WorkMode.remote);
    expect(read().workMode, isNull);
  });

  test(
    'recordSearch delegates to the service for the signed-in user',
    () async {
      final vm = listen();
      await settle();

      await vm.recordSearch('  Flutter  ');
      expect(history.entriesByUid[testUser.uid]!.single.term, 'Flutter');
    },
  );

  test('recordSearch with a blank term does nothing', () async {
    final vm = listen();
    await settle();

    await vm.recordSearch('   ');
    expect(history.entriesByUid[testUser.uid], isNull);
  });

  test('clearRecentSearches delegates to the service', () async {
    history.entriesByUid[testUser.uid] = [
      SearchHistoryEntry(id: 'a', term: 'Flutter', searchedAt: DateTime.now()),
    ];
    final vm = listen();
    await settle();

    await vm.clearRecentSearches();
    await settle();
    expect(read().recentSearches, isA<ViewEmpty<List<SearchHistoryEntry>>>());
  });

  test(
    'countMatching previews the filter sheet on the streamed pool',
    () async {
      internships.results = [
        testInternship('1', title: 'Flutter Intern', workMode: WorkMode.remote),
        testInternship('2', title: 'Java Intern', workMode: WorkMode.remote),
        testInternship('3', title: 'Flutter Dev', workMode: WorkMode.onSite),
      ];
      final viewModel = listen();
      await settle();

      const remote = SearchFilterCriteria(workModes: {WorkMode.remote});
      expect(viewModel.countMatching(const SearchFilterCriteria()), 3);
      expect(viewModel.countMatching(remote), 2);
      expect(viewModel.countMatching(remote, query: 'flutter'), 1);
    },
  );
}
