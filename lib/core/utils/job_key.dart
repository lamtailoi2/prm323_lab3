import 'dart:convert';

const int _fnvOffsetBasis = 0xcbf29ce484222325;
const int _fnvPrime = 0x100000001b3;

/// Short, URL-safe key for a SerpAPI `job_id` (G-25 point 4).
///
/// The raw `job_id` is a long base64 blob that may contain `/`, so it cannot
/// be used as a Firestore document ID, a route segment or an analytics value
/// (≤ 100 characters). The key is the 64-bit FNV-1a hash of the ID as 16 hex
/// characters: stable across runs and devices, unlike `String.hashCode`.
String jobKeyFor(String jobId) {
  var hash = _fnvOffsetBasis;
  for (final byte in utf8.encode(jobId)) {
    hash ^= byte;
    hash *= _fnvPrime; // Wraps at 64 bits on the Dart VM.
  }
  // Two 32-bit halves: a 64-bit int is signed, so it cannot be printed as
  // one unsigned number.
  return _hex32(hash >>> 32) + _hex32(hash & 0xffffffff);
}

String _hex32(int value) => value.toRadixString(16).padLeft(8, '0');
