import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/errors/app_exception.dart';

/// SerpAPI key, injected at build time from the untracked `.env` file:
/// `flutter run --dart-define-from-file=.env` (template: `.env.example`).
/// It is compiled into the app; see handoff-gaps G-25 for the trade-off.
const String serpApiKey = String.fromEnvironment('SERPAPI_KEY');

/// Low-level access to SerpAPI (internship listings come from its
/// `google_jobs` engine). Feature services build typed queries and parse the
/// results; Views and ViewModels never call this directly.
abstract interface class SerpApiClient {
  /// Calls `https://serpapi.com/search.json` with [params] (must include
  /// `engine`) and returns the decoded JSON. "No results" is returned as a
  /// normal response (no `jobs_results`), not as an error.
  Future<Map<String, Object?>> search(Map<String, String> params);
}

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final serpApiClientProvider = Provider<SerpApiClient>(
  (ref) => HttpSerpApiClient(ref.watch(httpClientProvider), apiKey: serpApiKey),
);

class HttpSerpApiClient implements SerpApiClient {
  HttpSerpApiClient(
    this._http, {
    required this._apiKey,
    this._timeout = const Duration(seconds: 20),
  });

  final http.Client _http;
  final String _apiKey;
  final Duration _timeout;

  static final Uri _endpoint = Uri.https('serpapi.com', '/search.json');

  @override
  Future<Map<String, Object?>> search(Map<String, String> params) async {
    if (_apiKey.isEmpty) {
      throw const AppException(
        AppErrorKind.configuration,
        'Job search is not set up for this build (missing SERPAPI_KEY).',
      );
    }
    final uri = _endpoint.replace(
      queryParameters: {...params, 'api_key': _apiKey},
    );

    final http.Response response;
    try {
      response = await _http.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const AppException(
        AppErrorKind.network,
        'Job search is taking too long. Check your connection and try again.',
      );
    } on http.ClientException {
      // Not attached as `cause`: its message contains the URL, and the URL
      // contains the API key.
      throw const AppException(
        AppErrorKind.network,
        'We could not load internships. Check your connection and try again.',
      );
    }

    final body = _decode(response.body);
    final error = body['error'];

    switch (response.statusCode) {
      case 200:
        break;
      case 401 || 403:
        throw const AppException(
          AppErrorKind.configuration,
          'Job search is not available: the SerpAPI key was rejected.',
        );
      case 429:
        throw const AppException(
          AppErrorKind.rateLimited,
          'The job search limit has been reached. Please try again later.',
        );
      default:
        throw AppException(
          AppErrorKind.unknown,
          'Job search is unavailable right now. Try again in a moment.',
          cause: 'HTTP ${response.statusCode}: $error',
        );
    }

    if (error is String && !_isNoResults(error)) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not load internships. Try again in a moment.',
        cause: error,
      );
    }
    return body;
  }

  /// SerpAPI answers an empty search with HTTP 200 and this error text.
  static bool _isNoResults(String error) =>
      error.toLowerCase().contains("hasn't returned any results");

  static Map<String, Object?> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Fall through.
    }
    return const <String, Object?>{'error': 'Invalid response body'};
  }
}
