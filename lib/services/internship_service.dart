import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/internship.dart';
import 'crashlytics_service.dart';
import 'serp_api_client.dart';

/// Internship listings from SerpAPI Google Jobs (G-25). The only place that
/// turns SerpAPI JSON into [Internship] models.
abstract interface class InternshipService {
  /// Internships for [keyword] near [location] (default:
  /// [SerpApiInternshipService.defaultLocation]), in Google's relevance
  /// order. One SerpAPI page, so at most 10 results; an empty list when
  /// nothing matches. Throws `AppException` on network, quota or key errors.
  Future<List<Internship>> search({required String keyword, String? location});
}

final internshipServiceProvider = Provider<InternshipService>(
  (ref) => SerpApiInternshipService(
    ref.watch(serpApiClientProvider),
    crashlytics: ref.watch(crashlyticsServiceProvider),
  ),
);

class SerpApiInternshipService implements InternshipService {
  SerpApiInternshipService(
    this._client, {
    required this._crashlytics,
    DateTime Function()? clock,
    this.cacheTtl = const Duration(minutes: 10),
  }) : _clock = clock ?? DateTime.now;

  /// The persona studies and commutes in Ho Chi Minh City (persona.md).
  static const String defaultLocation = 'Ho Chi Minh City, Vietnam';

  final SerpApiClient _client;
  final CrashlyticsService _crashlytics;
  final DateTime Function() _clock;

  /// Successful results are reused for this long per keyword and location,
  /// so switching tabs or skills back and forth does not spend the
  /// free-plan search quota again (G-25 point 2).
  final Duration cacheTtl;

  final Map<String, ({DateTime fetchedAt, List<Internship> results})> _cache =
      {};

  @override
  Future<List<Internship>> search({
    required String keyword,
    String? location,
  }) async {
    final place = location ?? defaultLocation;
    final cacheKey = '${keyword.trim().toLowerCase()}|$place';
    final cached = _cache[cacheKey];
    if (cached != null && _clock().difference(cached.fetchedAt) < cacheTtl) {
      return cached.results;
    }

    final body = await _client.search({
      'engine': 'google_jobs',
      'q': '${keyword.trim()} internship',
      'location': place,
      'hl': 'en',
      'gl': 'vn',
    });
    final results = List<Internship>.unmodifiable(_parse(body['jobs_results']));
    _cache[cacheKey] = (fetchedAt: _clock(), results: results);
    return results;
  }

  Iterable<Internship> _parse(Object? jobs) sync* {
    if (jobs is! List) return; // No results.
    for (final job in jobs) {
      try {
        if (job is! Map<String, Object?>) {
          throw const FormatException('jobs_results: entry is not an object');
        }
        yield Internship.fromSerpApi(job);
      } on FormatException catch (error, stack) {
        // One malformed listing must not hide the others.
        unawaited(
          _crashlytics.recordError(
            error,
            stack,
            reason: 'Skipped a malformed SerpAPI job',
          ),
        );
      }
    }
  }
}
