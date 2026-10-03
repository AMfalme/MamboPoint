import '../constants/product_limits.dart';
import 'firestore_converters.dart';

/// Builds the lowercase prefix tokens persisted as `Product.nameTokens`.
///
/// Firestore cannot do "contains" matching, so a product stores every
/// prefix of each word in its name (from 2 characters up). A search for
/// "tom" then becomes a cheap `array-contains` query that still matches
/// "Fresh Tomatoes".
///
/// The token list is deterministic for a given name, which keeps writes
/// idempotent and makes the function trivially unit testable.
List<String> buildNameTokens(
  String name, {
  int maxTokens = ProductLimits.maxNameTokens,
  int minPrefixLength = 2,
}) {
  final Set<String> tokens = <String>{};
  if (maxTokens <= 0) return const <String>[];

  // Split on anything that is not a letter or digit so "Tomato-2kg" and
  // "Tomato 2kg" produce the same tokens.
  final Iterable<String> words = name
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((String word) => word.isNotEmpty);

  for (final String word in words) {
    if (word.length < minPrefixLength) {
      tokens.add(word);
    } else {
      for (int end = minPrefixLength; end <= word.length; end++) {
        tokens.add(word.substring(0, end));
        if (tokens.length >= maxTokens) {
          return List<String>.unmodifiable(tokens);
        }
      }
    }
    if (tokens.length >= maxTokens) break;
  }

  return List<String>.unmodifiable(tokens);
}

/// Lowercase form of a product/category name, stored for sorting and
/// case-insensitive matching.
String normalizeName(String name) => normalizeForSearch(name);

/// Lowercase, whitespace-free form of an SKU, stored for prefix search and
/// uniqueness claims.
String normalizeSku(String sku) => uniqueKey(sku);

/// Lowercase, whitespace-free form of a barcode. Barcodes are digits in
/// practice, but scanners occasionally emit spaces or letters.
String normalizeBarcode(String barcode) => uniqueKey(barcode);
