import 'package:cloud_firestore/cloud_firestore.dart';

/// Defensive conversions between Firestore values and plain Dart types.
///
/// Repository documents are trusted after the security rules validate them,
/// but data can still arrive from the emulator, from seed scripts or from
/// older schema revisions. These helpers keep the model layer total: they
/// never throw on unexpected input.

/// Converts a Firestore timestamp-ish value into a [DateTime].
DateTime? dateTimeFromFirestore(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Converts a [DateTime] back into a Firestore [Timestamp].
Timestamp? timestampFromFirestore(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);

/// Trimmed string, or `null` when absent/blank.
String? trimmedOrNull(Object? value) {
  if (value == null) return null;
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// Trimmed string, or an empty string when absent/blank.
String stringOrEmpty(Object? value) => value?.toString().trim() ?? '';

/// Reads a [double] from a num or numeric string.
double doubleFrom(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

/// Reads an [int] from a num or numeric string.
int intFrom(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

/// Reads a [bool], falling back for missing or unexpected values.
bool boolFrom(Object? value, {bool fallback = false}) =>
    value is bool ? value : fallback;

/// Reads a list of trimmed, non-empty strings.
List<String> stringListFrom(Object? value) {
  if (value is! List) return const <String>[];
  final List<String> result = <String>[];
  for (final Object? item in value) {
    final String? text = trimmedOrNull(item);
    if (text != null) result.add(text);
  }
  return result;
}

/// String values are compared case-insensitively for search purposes.
String normalizeForSearch(String? value) => (value ?? '').trim().toLowerCase();

/// Comparison key for case-insensitive unique values (SKU, barcode, names).
String uniqueKey(String? value) =>
    normalizeForSearch(value).replaceAll(RegExp(r'\s+'), '');
