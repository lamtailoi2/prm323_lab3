import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/serp_api_client.dart';

import '../helpers/fakes.dart';

class _FakeSerpApiClient implements SerpApiClient {
  Map<String, Object?> response = const {};
  AppException? error;
  final List<Map<String, String>> calls = [];

  @override
  Future<Map<String, Object?>> search(Map<String, String> params) async {
    calls.add(params);
    final currentError = error;
    if (currentError != null) throw currentError;
    return response;
  }
}

void main() {
  late _FakeSerpApiClient client;
  late FakeCrashlyticsService crashlytics;
  late DateTime now;
  late SerpApiInternshipService service;

  Map<String, Object?> job(String id) => {
    'job_id': id,
    'title': 'Flutter Intern $id',
    'company_name': 'Northstar Labs',
  };

  setUp(() {
    client = _FakeSerpApiClient();
    crashlytics = FakeCrashlyticsService();
    now = DateTime(2026, 10, 21, 9);
    service = SerpApiInternshipService(
      client,
      crashlytics: crashlytics,
      clock: () => now,
    );
  });

  test('queries google_jobs for internships in Ho Chi Minh City', () async {
    client.response = {
      'jobs_results': [job('1'), job('2')],
    };
    final results = await service.search(keyword: 'Flutter');

    expect(results.map((i) => i.title), [
      'Flutter Intern 1',
      'Flutter Intern 2',
    ]);
    expect(client.calls.single, {
      'engine': 'google_jobs',
      'q': 'Flutter internship',
      'location': 'Ho Chi Minh City, Vietnam',
      'hl': 'en',
      'gl': 'vn',
    });
  });

  test('no jobs_results means an empty list', () async {
    client.response = {'error': "Google hasn't returned any results"};
    expect(await service.search(keyword: 'zzqx'), isEmpty);
  });

  test('skips and logs malformed jobs without hiding the others', () async {
    client.response = {
      'jobs_results': [
        job('1'),
        {'title': 'No company or id'},
        'not an object',
        job('2'),
      ],
    };
    final results = await service.search(keyword: 'Flutter');

    expect(results.map((i) => i.jobId), ['1', '2']);
    expect(crashlytics.recordedErrors, hasLength(2));
    expect(crashlytics.recordedErrors, everyElement(isA<FormatException>()));
  });

  test('passes AppException from the client through', () async {
    client.error = const AppException(
      AppErrorKind.rateLimited,
      'The job search limit has been reached. Please try again later.',
    );
    await expectLater(
      service.search(keyword: 'Flutter'),
      throwsA(
        isA<AppException>().having(
          (e) => e.kind,
          'kind',
          AppErrorKind.rateLimited,
        ),
      ),
    );
  });

  test('reuses results per keyword for 10 minutes', () async {
    client.response = {
      'jobs_results': [job('1')],
    };
    await service.search(keyword: 'Flutter');
    await service.search(keyword: ' flutter ');
    expect(client.calls, hasLength(1));

    await service.search(keyword: 'React');
    expect(client.calls, hasLength(2));

    now = now.add(const Duration(minutes: 10));
    await service.search(keyword: 'Flutter');
    expect(client.calls, hasLength(3));
  });

  test('does not cache failures', () async {
    client.error = const AppException(AppErrorKind.network, 'Offline');
    await expectLater(service.search(keyword: 'Flutter'), throwsA(anything));

    client
      ..error = null
      ..response = {
        'jobs_results': [job('1')],
      };
    expect(await service.search(keyword: 'Flutter'), hasLength(1));
    expect(client.calls, hasLength(2));
  });
}
