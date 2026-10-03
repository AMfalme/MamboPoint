import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../models/product.dart';
import '../domain/product_filter.dart';
import 'product_reader.dart';

/// Query sizing for the product list.
///
/// Spec section 32 requires the module to scale from tens to thousands of
/// products without a rewrite, so every read is bounded and paged.
class ProductQueryLimits {
  const ProductQueryLimits._();

  /// Page size for the unfiltered/filtered list.
  static const int pageSize = 50;

  /// Per-field cap while searching. A free-text search fans out to several
  /// single-field queries which are then merged, so this bounds total reads.
  static const int searchPerFieldLimit = 60;

  /// Combined ceiling for merged search results.
  static const int searchCombinedLimit = 200;
}

/// Reads products for the Product Management module.
///
/// Documented in `docs/FIRESTORE_DATA_MODEL.md`. All reads are tenant-scoped:
/// the caller's membership is enforced by `firestore.rules`, so a query can
/// never cross into another business.
class ProductRepository implements ProductReader {
  ProductRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _productsRef(String businessId) =>
      _firestore.collection(FirestorePaths.products(businessId));

  /// Fetches a page of products for the given [filter].
  ///
  /// Free-text search takes a different path to plain filtering:
  ///
  /// * **No query text** — Firestore does all the work: status/category
  ///   equality filters, server-side ordering and cursor pagination.
  /// * **Query text** — Firestore has no cross-field `OR`, so the text is
  ///   matched against name tokens, the name prefix, the SKU prefix and (for
  ///   numeric input) the barcode prefix in parallel. Results are merged,
  ///   de-duplicated, then refined and ordered client-side.
  ///
  /// Stock filtering is always applied client-side because stock state is
  /// derived from two fields and is intentionally not persisted.
  @override
  Future<ProductQueryResult> fetchProducts({
    required String businessId,
    required ProductFilter filter,
    Object? cursor,
    int limit = ProductQueryLimits.pageSize,
  }) async {
    try {
      if (filter.hasQuery) {
        return await _fetchSearchResults(
          businessId: businessId,
          filter: filter,
        );
      }
      return await _fetchFilteredPage(
        businessId: businessId,
        filter: filter,
        cursor: cursor,
        limit: limit,
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ProductRepository.fetchProducts');
      throw mapError(error, fallbackMessage: ErrorMessages.loadProducts);
    }
  }

  /// Watches a single product. Used by the details view so an edit made on
  /// another device appears without a manual refresh.
  Stream<Product?> watchProduct({
    required String businessId,
    required String productId,
  }) {
    return _productsRef(businessId)
        .doc(productId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          if (!doc.exists) return null;
          return Product.fromDocument(doc);
        })
        .handleError((Object error, StackTrace stackTrace) {
          logError(error, stackTrace, context: 'ProductRepository.watchProduct');
          throw mapError(error, fallbackMessage: ErrorMessages.loadProduct);
        });
  }

  /// Reads a single product once.
  Future<Product?> getProduct({
    required String businessId,
    required String productId,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _productsRef(
        businessId,
      ).doc(productId).get();
      if (!doc.exists) return null;
      return Product.fromDocument(doc);
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ProductRepository.getProduct');
      throw mapError(error, fallbackMessage: ErrorMessages.loadProduct);
    }
  }

  /// Server-filtered, server-sorted, cursor-paged read.
  Future<ProductQueryResult> _fetchFilteredPage({
    required String businessId,
    required ProductFilter filter,
    required Object? cursor,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _buildBaseQuery(businessId, filter);

    query = query.orderBy(
      filter.sort.firestoreField,
      descending: filter.sort.descending,
    );

    // A stable tie-breaker keeps paging from jittering when many products
    // share the same primary sort value.
    final ProductSortOrder? tieBreaker = filter.sort.tieBreaker;
    if (tieBreaker != null) {
      query = query.orderBy(
        tieBreaker.firestoreField,
        descending: tieBreaker.descending,
      );
    }

    if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }

    // Fetch one extra document so "is there another page?" is answered
    // without a second round trip.
    final QuerySnapshot<Map<String, dynamic>> snapshot = await query
        .limit(limit + 1)
        .get();

    final List<Product> fetched = snapshot.docs
        .map(Product.fromDocument)
        .toList(growable: false);

    final bool hasMore = fetched.length > limit;
    final List<Product> page = hasMore
        ? fetched.sublist(0, limit)
        : fetched;

    // Stock state is derived from two fields and is deliberately not
    // persisted, so the stock filter is applied here rather than in the query.
    final List<Product> visible = page
        .where(filter.matches)
        .toList(growable: false);

    // The cursor must point past the last *fetched* document, not the last
    // visible one, otherwise refined-out documents would be re-read.
    final DocumentSnapshot<Map<String, dynamic>>? lastDocument =
        snapshot.docs.isEmpty
        ? null
        : snapshot.docs[page.isEmpty ? 0 : page.length - 1];

    return ProductQueryResult(
      products: visible,
      hasMore: hasMore,
      cursor: lastDocument,
    );
  }

  /// Applies the filters Firestore can express directly.
  ///
  /// Fields that are not being filtered are left out entirely, which keeps
  /// the query on single-field indexes whenever possible.
  Query<Map<String, dynamic>> _buildBaseQuery(
    String businessId,
    ProductFilter filter,
  ) {
    Query<Map<String, dynamic>> query = _productsRef(businessId);

    final bool? isActive = filter.status.isActiveValue;
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    final String? categoryId = filter.categoryId;
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query;
  }

  /// Free-text search across name, SKU and barcode (spec section 11).
  ///
  /// Firestore cannot `OR` across different fields, so the needle is matched
  /// against four single-field queries in parallel and the results are merged.
  /// Each query is individually bounded, and the merged set is capped by
  /// [ProductQueryLimits.searchCombinedLimit].
  ///
  /// Because a merged result set has no meaningful server-side order, results
  /// are sorted in memory by the user's chosen order. Ties fall back to name.
  Future<ProductQueryResult> _fetchSearchResults({
    required String businessId,
    required ProductFilter filter,
  }) async {
    const String maxSuffix = '\uf8ff';
    final String needle = filter.normalizedQuery;
    final Query<Map<String, dynamic>> base = _buildBaseQuery(
      businessId,
      filter,
    );

    final List<Future<QuerySnapshot<Map<String, dynamic>>>> pending =
        <Future<QuerySnapshot<Map<String, dynamic>>>>[
          // Word-prefix match: "tom" finds "Fresh Tomatoes".
          base
              .where('nameTokens', arrayContains: needle)
              .limit(ProductQueryLimits.searchPerFieldLimit)
              .get(),
          // Name start-of-string prefix.
          base
              .where('nameLower', isGreaterThanOrEqualTo: needle)
              .where('nameLower', isLessThanOrEqualTo: '$needle$maxSuffix')
              .limit(ProductQueryLimits.searchPerFieldLimit)
              .get(),
          // SKU prefix.
          base
              .where('skuLower', isGreaterThanOrEqualTo: needle)
              .where('skuLower', isLessThanOrEqualTo: '$needle$maxSuffix')
              .limit(ProductQueryLimits.searchPerFieldLimit)
              .get(),
        ];

    if (_looksLikeBarcode(needle)) {
      pending.add(
        base
            .where('barcode', isGreaterThanOrEqualTo: needle)
            .where('barcode', isLessThanOrEqualTo: '$needle$maxSuffix')
            .limit(ProductQueryLimits.searchPerFieldLimit)
            .get(),
      );
    }

    final List<QuerySnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait(pending);

    // De-duplicate: the same product can match several of the queries.
    final Map<String, Product> merged = <String, Product>{};
    for (final QuerySnapshot<Map<String, dynamic>> snapshot in snapshots) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        merged.putIfAbsent(doc.id, () => Product.fromDocument(doc));
        if (merged.length >= ProductQueryLimits.searchCombinedLimit) break;
      }
      if (merged.length >= ProductQueryLimits.searchCombinedLimit) break;
    }

    // A prefix index can return near-misses ("tom" matching "tomato" inside a
    // longer word), so the exact predicate is re-applied here.
    final List<Product> refined = merged.values
        .where(filter.matches)
        .toList(growable: true);
    _sortInMemory(refined, filter.sort);

    return ProductQueryResult(
      products: List<Product>.unmodifiable(refined),
      // Search intentionally returns a single bounded set rather than paging:
      // the merged ordering is only meaningful in memory.
      hasMore: false,
    );
  }

  /// Barcodes are numeric in practice (EAN-8/13, UPC-A), so the barcode query
  /// is only issued when the input could plausibly be one. This keeps a plain
  /// name search to fewer reads.
  static bool _looksLikeBarcode(String needle) =>
      needle.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(needle);

  /// Orders merged search results in memory using the same semantics as the
  /// server-side ordering in [_fetchFilteredPage].
  static void _sortInMemory(List<Product> products, ProductSortOrder sort) {
    final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);

    int compare(Product a, Product b) {
      final int primary = switch (sort) {
        ProductSortOrder.nameAscending => a.nameLower.compareTo(b.nameLower),
        ProductSortOrder.sellingPriceAscending => a.sellingPrice.compareTo(
          b.sellingPrice,
        ),
        ProductSortOrder.sellingPriceDescending => b.sellingPrice.compareTo(
          a.sellingPrice,
        ),
        ProductSortOrder.stockAscending => a.stockQuantity.compareTo(
          b.stockQuantity,
        ),
        ProductSortOrder.recentlyUpdated => (b.updatedAt ?? epoch).compareTo(
          a.updatedAt ?? epoch,
        ),
      };
      if (primary != 0) return primary;
      return a.nameLower.compareTo(b.nameLower);
    }

    products.sort(compare);
  }

}
