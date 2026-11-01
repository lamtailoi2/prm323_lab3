import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/internships/models/search_filter_criteria.dart';
import 'package:internly/features/internships/viewmodels/search_results_viewmodel.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/saved_service.dart';
import 'package:internly/services/search_history_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeInternshipService internships;
  late FakeSavedService saved;
  late FakeSearchHistoryService history;

  setUp(() {
    internships = FakeInternshipService();
    saved = FakeSavedService();
    history = FakeSearchHistoryService();
  });

  tearDown(() async {
    await internships.dispose();
    await saved.dispose();
    await history.dispose();
  });

  ProviderContainer createContainer({String? uid}) {
    final container = ProviderContainer(
      overrides: [
        internshipServiceProvider.overrideWithValue(internships),
        savedServiceProvider.overrideWithValue(saved),
        searchHistoryServiceProvider.overrideWithValue(history),
        currentUserIdProvider.overrideWithValue(uid ?? testUser.uid),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  SearchResultsViewModel listen(ProviderContainer container) {
    container.listen(searchResultsViewModelProvider, (_, _) {});
    return container.read(searchResultsViewModelProvider.notifier);
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  final now = DateTime.now();
  final sampleListings = [
    testInternship(
      '1',
      title: 'Flutter Developer Intern',
      companyName: 'FPT Software',
      workMode: WorkMode.remote,
      postedAt: now.subtract(const Duration(days: 2)),
      searchRank: 0,
      skills: const ['Flutter', 'Dart', 'REST API'],
    ),
    testInternship(
      '2',
      title: 'Mobile App Intern (Flutter & iOS)',
      companyName: 'VNG Corporation',
      workMode: WorkMode.remote,
      postedAt: now.subtract(const Duration(days: 1)),
      searchRank: 1,
      skills: const ['Flutter', 'State Management', 'Git'],
    ),
    testInternship(
      '3',
      title: 'Backend Node.js Intern',
      companyName: 'MoMo',
      workMode: WorkMode.onSite,
      postedAt: now.subtract(const Duration(hours: 5)),
      searchRank: 2,
      skills: const ['Node.js', 'NestJS'],
    ),
  ];

  test('loads listings and emits ViewData', () async {
    internships.results = sampleListings;
    final container = createContainer();
    listen(container);

    await settle();
    final state = container.read(searchResultsViewModelProvider);
    expect(state.results, isA<ViewData<List<Internship>>>());
    final data = (state.results as ViewData<List<Internship>>).data;
    expect(data.length, 3);
  });

  test('filters listings by query matching title or skills', () async {
    internships.results = sampleListings;
    final container = createContainer();
    final notifier = listen(container);
    await settle();

    notifier.setQuery('Flutter');
    final state = container.read(searchResultsViewModelProvider);
    final data = (state.results as ViewData<List<Internship>>).data;
    expect(data.length, 2);
    expect(
      data.map((e) => e.title),
      containsAll([
        'Flutter Developer Intern',
        'Mobile App Intern (Flutter & iOS)',
      ]),
    );
    expect(history.entriesByUid[testUser.uid]?.first.term, 'Flutter');
  });

  test('filters listings by work mode', () async {
    internships.results = sampleListings;
    final container = createContainer();
    final notifier = listen(container);
    await settle();

    notifier.setWorkMode(WorkMode.onSite);
    final state = container.read(searchResultsViewModelProvider);
    final data = (state.results as ViewData<List<Internship>>).data;
    expect(data.length, 1);
    expect(data.single.title, 'Backend Node.js Intern');
  });

  test('filters by both query and work mode', () async {
    internships.results = sampleListings;
    final container = createContainer();
    final notifier = listen(container);
    await settle();

    notifier.setQuery('Flutter');
    notifier.setWorkMode(WorkMode.remote);
    final state = container.read(searchResultsViewModelProvider);
    final data = (state.results as ViewData<List<Internship>>).data;
    expect(data.length, 2);
    expect(state.activeFilterCount, 2);
  });

  test(
    'filters by criteria with skills, location and calculates count',
    () async {
      internships.results = sampleListings;
      final container = createContainer();
      final notifier = listen(container);
      await settle();

      const criteria = SearchFilterCriteria(
        skills: {'Dart'},
        workModes: {WorkMode.remote},
      );
      expect(notifier.countMatching(criteria), 1);

      notifier.setCriteria(criteria);
      final state = container.read(searchResultsViewModelProvider);
      final data = (state.results as ViewData<List<Internship>>).data;
      expect(data.length, 1);
      expect(data.single.companyName, 'FPT Software');
      expect(state.activeFilterCount, 2);
    },
  );

  test(
    'filters by criteria with skills, location and calculates count',
    () async {
      internships.results = sampleListings;
      final container = createContainer();
      final notifier = listen(container);
      await settle();

      const criteria = SearchFilterCriteria(
        skills: {'Dart'},
        workModes: {WorkMode.remote},
      );
      expect(notifier.countMatching(criteria), 1);

      notifier.setCriteria(criteria);
      final state = container.read(searchResultsViewModelProvider);
      final data = (state.results as ViewData<List<Internship>>).data;
      expect(data.length, 1);
      expect(data.single.companyName, 'FPT Software');
      expect(state.activeFilterCount, 2);
    },
  );

  test('clearing filters returns all listings', () async {
    internships.results = sampleListings;
    final container = createContainer();
    final notifier = listen(container);
    await settle();

    notifier.setQuery('Flutter');
    notifier.setWorkMode(WorkMode.remote);
    notifier.clearFilters();

    final state = container.read(searchResultsViewModelProvider);
    final data = (state.results as ViewData<List<Internship>>).data;
    expect(data.length, 3);
    expect(state.query, '');
    expect(state.workMode, isNull);
    expect(state.activeFilterCount, 0);
  });

  test('sorts by most recent first', () async {
    internships.results = sampleListings;
    final container = createContainer();
    final notifier = listen(container);
    await settle();

    notifier.setSortBy(SearchSortBy.mostRecent);
    final state = container.read(searchResultsViewModelProvider);
    final data = (state.results as ViewData<List<Internship>>).data;
    // Newest is Node.js (5h ago), then VNG (1d ago), then FPT (2d ago)
    expect(data[0].companyName, 'MoMo');
    expect(data[1].companyName, 'VNG Corporation');
    expect(data[2].companyName, 'FPT Software');
  });

  test('sorts by best match (rank)', () async {
    internships.results = sampleListings;
    final container = createContainer();
    final notifier = listen(container);
    await settle();

    notifier.setSortBy(SearchSortBy.bestMatch);
    final state = container.read(searchResultsViewModelProvider);
    final data = (state.results as ViewData<List<Internship>>).data;
    expect(data[0].companyName, 'FPT Software');
    expect(data[1].companyName, 'VNG Corporation');
    expect(data[2].companyName, 'MoMo');
  });

  test('emits ViewEmpty when no listings match', () async {
    internships.results = sampleListings;
    final container = createContainer();
    final notifier = listen(container);
    await settle();

    notifier.setQuery('Blockchain');
    final state = container.read(searchResultsViewModelProvider);
    expect(state.results, isA<ViewEmpty<List<Internship>>>());
  });

  test('handles service error and retries', () async {
    internships.error = const AppException(
      AppErrorKind.network,
      'Network failed',
    );
    final container = createContainer();
    listen(container);

    await settle();
    var state = container.read(searchResultsViewModelProvider);
    expect(state.results, isA<ViewError<List<Internship>>>());

    internships.error = null;
    internships.results = sampleListings;
    container.read(searchResultsViewModelProvider.notifier).retry();

    await settle();
    state = container.read(searchResultsViewModelProvider);
    expect(state.results, isA<ViewData<List<Internship>>>());
  });

  test('toggleSave updates savedIds and calls service', () async {
    internships.results = sampleListings;
    final container = createContainer();
    final notifier = listen(container);
    await settle();

    final key = sampleListings.first.key;
    await notifier.toggleSave(key);

    var state = container.read(searchResultsViewModelProvider);
    expect(state.savedIds, contains(key));
    expect(saved.savedByUid[testUser.uid], contains(key));

    await notifier.toggleSave(key);
    state = container.read(searchResultsViewModelProvider);
    expect(state.savedIds, isNot(contains(key)));
  });
}
