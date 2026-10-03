import 'package:flutter/foundation.dart';

import '../../../models/product.dart';
import '../domain/product_filter.dart';

/// One page of products plus the token needed to ask for the next one.
@immutable
class ProductQueryResult {
  const ProductQueryResult({
    required this.products,
    required this.hasMore,
    this.cursor,
  });

  final List<Product> products;

  /// Whether another page is likely available.
  final bool hasMore;

  /// Opaque paging token to hand back to
  /// [ProductReader.fetchProducts].
  ///
  /// Typed as `Object?` on purpose so callers (notifiers, widgets) never need
  /// to import Firestore types.
  final Object? cursor;

  static const ProductQueryResult empty = ProductQueryResult(
    products: <Product>[],
    hasMore: false,
  );
}

/// Read side of the product data layer.
///
/// Extracted as an interface for two reasons:
///
/// 1. The list logic — filtering, client-side refinement, paging, debounce —
///    is the part most worth testing, and it can then be exercised against an
///    in-memory fake with no Firebase instance and no emulator
///    (spec section 42).
/// 2. Spec section 44 asks the module to expose clean interfaces so future
///    POS/inventory code can read products without depending on Firestore.
abstract interface class ProductReader {
  /// Fetches one page of products for [filter].
  ///
  /// [cursor] is the opaque token from a previous [ProductQueryResult].
  Future<ProductQueryResult> fetchProducts({
    required String businessId,
    required ProductFilter filter,
    Object? cursor,
    int limit,
  });
}
