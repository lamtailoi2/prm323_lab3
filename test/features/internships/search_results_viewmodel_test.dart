import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/internships/models/search_filter_criteria.dart';
import 'package:internly/features/internships/viewmodels/search_results_viewmodel.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/saved_service.dart';
import 'package:internly/services/search_history_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeInternshipService internships;
  late FakeSavedService saved;
  late FakeSearchHistoryService history;
  late FakeAnalyticsService analytics;

  setUp(() {
    internships = FakeInternshipService();
    saved = FakeSavedService();
    history = FakeSearchHistoryService();
    analytics = FakeAnalyticsService();
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
        analyticsServiceProvider.overrideWithValue(analytics),
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

  test('the same job under several sync keywords is listed once', () async {
    internships.results = [
      ...sampleListings,
      testInternship(
        '4',
        title: 'Flutter Developer Intern',
        companyName: 'FPT Software',
        workMode: WorkMode.remote,
        searchRank: 5,
        skills: const ['Flutter', 'Dart'],
      ),
    ];
    final container = createContainer();
    final notifier = listen(container);
    await settle();

    final data =
        (container.read(searchResultsViewModelProvider).results
                as ViewData<List<Internship>>)
            .data;
    expect(data.length, 3);
    // The copy with the better sync rank is kept.
    expect(data.map((e) => e.jobId), isNot(contains('job-4')));
    expect(
      notifier.countMatching(const SearchFilterCriteria(skills: {'Dart'})),
      1,
    );
  });

  test(
    'a job found only through a lower-ranked copy is kept (CR-08)',
    () async {
      internships.results = [
        testInternship(
          'a',
          title: 'Java Intern',
          companyName: 'FPT Software',
          searchRank: 0,
          searchKeyword: 'IT internship Vietnam',
        ),
        testInternship(
          'b',
          title: 'Java Intern',
          companyName: 'FPT Software',
          searchRank: 3,
          searchKeyword: 'thực tập backend',
        ),
      ];
      final container = createContainer();
      final notifier = listen(container);
      await settle();

      notifier.setQuery('backend');
      final data =
          (container.read(searchResultsViewModelProvider).results
                  as ViewData<List<Internship>>)
              .data;
      expect(data.map((e) => e.jobId), ['job-b']);
      expect(notifier.countMatching(const SearchFilterCriteria()), 1);
    },
  );

  group('analytics', () {
    test('a submitted search logs search with its result count', () async {
      internships.results = sampleListings;
      final container = createContainer();
      final notifier = listen(container);
      await settle();

      notifier.setQuery('  Flutter ');

      expect(analytics.events, ['search']);
      expect(analytics.parameters['search'], {
        'search_term': 'Flutter',
        'result_count': 2,
        'source': 'search',
      });
    });

    test(
      'a search opened before the pool arrives logs once, with the count',
      () async {
        internships.results = sampleListings;
        final container = createContainer();
        final notifier = listen(container);

        notifier.init(query: 'Node');
        expect(analytics.events, isEmpty);

        await settle();
        expect(analytics.events, ['search']);
        expect(analytics.parameters['search']?['result_count'], 1);

        // A new snapshot is not a new search.
        internships.emit(sampleListings.take(2).toList());
        await settle();
        expect(analytics.events, ['search']);
      },
    );

    test('a blank search, sorting and removing chips log nothing', () async {
      internships.results = sampleListings;
      final container = createContainer();
      final notifier = listen(container);
      notifier.init(workMode: WorkMode.remote);
      await settle();

      notifier
        ..setQuery('   ')
        ..setSortBy(SearchSortBy.bestMatch)
        ..removeWorkMode(WorkMode.remote)
        ..clearFilters();

      expect(analytics.events, isEmpty);
    });

    test(
      'Show results on the Search Results sheet logs search_filter_apply',
      () async {
        internships.results = sampleListings;
        final container = createContainer();
        final notifier = listen(container);
        await settle();

        notifier.setCriteria(
          const SearchFilterCriteria(
            workModes: {WorkMode.remote, WorkMode.onSite},
            skills: {'Flutter', 'Dart'},
            location: 'Ho Chi Minh City',
          ),
        );

        expect(analytics.events, ['search_filter_apply']);
        expect(analytics.parameters['search_filter_apply'], {
          'work_mode': 'on_site,remote',
          'location': 'Ho Chi Minh City',
          'skill_count': 2,
          'job_type': 'any',
          'allowance': 'any',
          'result_count': 2,
          'source': 'search_results',
        });
      },
    );

    test('a Job type or allowance filter is logged (CR-13)', () async {
      internships.results = sampleListings;
      final container = createContainer();
      final notifier = listen(container);
      await settle();

      notifier.setCriteria(
        const SearchFilterCriteria(
          jobType: 'Internship',
          allowanceRange: 'Negotiable',
        ),
      );

      expect(
        analytics.parameters['search_filter_apply']?['job_type'],
        'Internship',
      );
      expect(
        analytics.parameters['search_filter_apply']?['allowance'],
        'Negotiable',
      );
      expect(analytics.parameters['search_filter_apply']?['result_count'], 0);
    });

    test('filters applied on the Search tab log with source search', () async {
      internships.results = sampleListings;
      final container = createContainer();
      final notifier = listen(container);

      notifier.init(
        query: 'Flutter',
        criteria: const SearchFilterCriteria(location: 'Any location'),
      );
      await settle();

      expect(analytics.events, ['search', 'search_filter_apply']);
      expect(analytics.parameters['search_filter_apply'], {
        'work_mode': 'any',
        'location': 'any',
        'skill_count': 0,
        'job_type': 'any',
        'allowance': 'any',
        'result_count': 2,
        'source': 'search',
      });
    });
  });
}
