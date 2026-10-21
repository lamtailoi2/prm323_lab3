import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/services/serp_api_client.dart';

const _key = 'test-key-123';

HttpSerpApiClient _client(
  MockClientHandler handler, {
  String apiKey = _key,
  Duration timeout = const Duration(seconds: 5),
}) => HttpSerpApiClient(MockClient(handler), apiKey: apiKey, timeout: timeout);

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

Matcher _appError(AppErrorKind kind) =>
    throwsA(isA<AppException>().having((e) => e.kind, 'kind', kind));

void main() {
  const params = {'engine': 'google_jobs', 'q': 'flutter intern'};

  test('sends params plus the API key and returns the JSON body', () async {
    late Uri seen;
    final client = _client((request) async {
      seen = request.url;
      return _json({
        'jobs_results': [
          {'title': 'Flutter Intern'},
        ],
      });
    });

    final body = await client.search(params);

    expect(seen.host, 'serpapi.com');
    expect(seen.path, '/search.json');
    expect(seen.queryParameters['engine'], 'google_jobs');
    expect(seen.queryParameters['q'], 'flutter intern');
    expect(seen.queryParameters['api_key'], _key);
    expect(body['jobs_results'], isA<List<Object?>>());
  });

  test('"no results" is returned as an empty response, not an error', () async {
    final client = _client(
      (_) async => _json({
        'error': "Google hasn't returned any results for this query.",
      }),
    );
    final body = await client.search(params);
    expect(body['jobs_results'], isNull);
  });

  test('missing key is a configuration error and makes no request', () async {
    var calls = 0;
    final client = _client((_) async {
      calls++;
      return _json({});
    }, apiKey: '');
    await expectLater(
      client.search(params),
      _appError(AppErrorKind.configuration),
    );
    expect(calls, 0);
  });

  test('maps HTTP failures to user-safe errors', () async {
    await expectLater(
      _client((_) async => _json({'error': 'Invalid API key.'}, 401))
          .search(params),
      _appError(AppErrorKind.configuration),
    );
    await expectLater(
      _client((_) async => _json({'error': 'Run out of searches.'}, 429))
          .search(params),
      _appError(AppErrorKind.rateLimited),
    );
    await expectLater(
      _client((_) async => http.Response('oops', 503)).search(params),
      _appError(AppErrorKind.unknown),
    );
    await expectLater(
      _client((_) async => _json({'error': 'Unsupported parameter.'}))
          .search(params),
      _appError(AppErrorKind.unknown),
    );
  });

  test('network failure never leaks the API key', () async {
    final client = _client(
      (request) async =>
          throw http.ClientException('Failed host lookup', request.url),
    );
    try {
      await client.search(params);
      fail('expected an AppException');
    } on AppException catch (e) {
      expect(e.kind, AppErrorKind.network);
      expect('${e.message} ${e.cause}', isNot(contains(_key)));
    }
  });

  test('timeout is reported as a network error', () async {
    final client = _client(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(client.search(params), _appError(AppErrorKind.network));
  });
}
