import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Defensive reader for Firestore document data.
///
/// Required fields throw a [FormatException] that names the collection,
/// document ID and field, so services can skip (and log) a malformed document
/// instead of crashing a whole list. Optional fields fall back to `null` or an
/// empty collection when missing or of the wrong type.
class FirestoreReader {
  FirestoreReader(this.path, Map<String, Object?>? data)
    : _data = data ?? const <String, Object?>{};

  /// `collection/documentId`, used in error messages only.
  final String path;
  final Map<String, Object?> _data;

  bool has(String key) => _data[key] != null;

  /// A copy of the wrapped document data, for handing a nested object to a
  /// model parser.
  Map<String, Object?> toMap() => Map<String, Object?>.unmodifiable(_data);

  String requireString(String key) {
    final value = _data[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw _invalid(key, 'a non-empty string', value);
  }

  String? optionalString(String key) {
    final value = _data[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  int? optionalInt(String key) {
    final value = _data[key];
    if (value is int) return value;
    if (value is double && value.isFinite) return value.round();
    return null;
  }

  bool boolOr(String key, {required bool fallback}) {
    final value = _data[key];
    return value is bool ? value : fallback;
  }

  /// Returns the non-empty strings in a list field; drops other entries.
  List<String> stringList(String key) {
    final value = _data[key];
    if (value is! List) return const <String>[];
    return List<String>.unmodifiable(
      value.whereType<String>().where((s) => s.trim().isNotEmpty),
    );
  }

  /// Accepts a Firestore [Timestamp], a [DateTime], epoch milliseconds or an
  /// ISO-8601 string.
  DateTime requireDateTime(String key) {
    final value = _data[key];
    final parsed = _toDateTime(value);
    if (parsed != null) return parsed;
    throw _invalid(key, 'a timestamp', value);
  }

  DateTime? optionalDateTime(String key) => _toDateTime(_data[key]);

  /// Parses an enum stored as a string. Unknown values are rejected rather
  /// than silently mapped to a default.
  T requireEnum<T extends Enum>(String key, T? Function(String raw) parse) {
    final value = _data[key];
    final parsed = value is String ? parse(value) : null;
    if (parsed != null) return parsed;
    throw _invalid(key, 'a known ${T.toString()} value', value);
  }

  T? optionalEnum<T extends Enum>(String key, T? Function(String raw) parse) {
    final value = _data[key];
    return value is String ? parse(value) : null;
  }

  /// Returns a nested reader for a map field, or `null` when absent.
  FirestoreReader? optionalMap(String key) {
    final value = _data[key];
    if (value is! Map) return null;
    return FirestoreReader('$path.$key', Map<String, Object?>.from(value));
  }

  FirestoreReader requireMap(String key) {
    final reader = optionalMap(key);
    if (reader != null) return reader;
    throw _invalid(key, 'a map', _data[key]);
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  FormatException _invalid(String key, String expected, Object? actual) {
    final found = actual == null ? 'nothing' : actual.runtimeType.toString();
    return FormatException('$path: "$key" must be $expected, found $found.');
  }
}
