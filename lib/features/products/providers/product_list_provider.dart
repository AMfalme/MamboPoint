import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../models/product.dart';
import '../../auth/providers/session_providers.dart';
import '../data/product_reader.dart';
import '../data/product_repository.dart';
import '../domain/product_filter.dart';
import '../domain/product_list_state.dart';

/// Firestore-backed reader, swappable in tests and in the emulator.
final Provider<ProductReader> productReaderProvider = Provider<ProductReader>(
  (ref) => ProductRepository(ref.watch(firestoreProvider)),
);

/// Holds the product list, its filter and its paging cursor.
///
/// The notifier is the single place that owns list state, so the page widget
/// stays presentational and filter logic is testable without a widget tree.
class ProductListNotifier extends AsyncNotifier<ProductListState> {
  /// Typing is debounced so a search does not fire a query per keystroke
  /// (spec section 32).
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// Upper bound on how many pages are auto-fetched to satisfy a filter that
  /// is applied client-side, so a pathological query cannot loop forever.
  static const int _maxAutoPages = 4;

  Timer? _debounce;

  /// Guards against an older, slower response overwriting a newer one.
  int _requestToken = 0;

  @override
  Future<ProductListState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    final String businessId = ref.watch(requireBusinessIdProvider);
    return _fetchFirstPage(
      businessId: businessId,
      filter: const ProductFilter(),
    );
  }

  ProductFilter get _filter => state.value?.filter ?? const ProductFilter();

  ProductReader get _repository => ref.read(productReaderProvider);

  String get _businessId => ref.read(requireBusinessIdProvider);

  /// Applies the free-text query after a short debounce (spec section 11:
  /// the user should not have to press Enter).
  void setQuery(String query) {
    if (query.trim() == _filter.query.trim()) return;
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      unawaited(_load(_filter.withQuery(query)));
    });
  }

  void setCategory(String? categoryId) =>
      unawaited(_load(_filter.withCategory(categoryId)));

  void setStatus(ProductStatusFilter status) =>
      unawaited(_load(_filter.withStatus(status)));

  void setStock(ProductStockFilter stock) =>
      unawaited(_load(_filter.withStock(stock)));

  void setSort(ProductSortOrder sort) =>
      unawaited(_load(_filter.withSort(sort)));

  /// Clears refinements while keeping the chosen sort order.
  void clearFilters() => unawaited(_load(_filter.cleared()));

  /// Clears everything including the search text.
  void resetAll() => unawaited(_load(const ProductFilter()));

  Future<void> refresh() async {
    _debounce?.cancel();
    await _load(_filter);
  }

  /// Loads the first page for [filter].
  ///
  /// Already-loaded rows stay on screen and the list is flagged as reloading,
  /// so changing a filter never flashes an empty screen (spec section 26).
  Future<void> _load(ProductFilter filter) async {
    final int token = ++_requestToken;
    final ProductListState? previous = state.value;

    state = previous == null
        ? const AsyncValue<ProductListState>.loading()
        : AsyncValue<ProductListState>.data(
            previous.copyWith(isReloading: true),
          );

    final AsyncValue<ProductListState> result = await AsyncValue.guard(
      () => _fetchFirstPage(businessId: _businessId, filter: filter),
    );

    // A newer request already produced the state, so discard this result.
    if (token != _requestToken) return;
    state = result;
  }

  /// Fetches the first page, transparently paging past results that the
  /// client-side refinements removed.
  ///
  /// The stock filter is derived and applied in memory, so a page can be
  /// entirely filtered away. Without this loop the user would see a false
  /// "no products" message while matching products exist further on.
  Future<ProductListState> _fetchFirstPage({
    required String businessId,
    required ProductFilter filter,
  }) async {
    final List<Product> collected = <Product>[];
    Object? cursor;
    bool hasMore = false;

    for (int attempt = 0; attempt < _maxAutoPages; attempt++) {
      final ProductQueryResult page = await _repository.fetchProducts(
        businessId: businessId,
        filter: filter,
        cursor: cursor,
      );
      collected.addAll(page.products);
      cursor = page.cursor;
      hasMore = page.hasMore;

      // Stop as soon as something is visible, or when nothing is left.
      if (collected.isNotEmpty || !hasMore) break;
    }

    return ProductListState(
      products: List<Product>.unmodifiable(collected),
      filter: filter,
      hasMore: hasMore,
      cursor: cursor,
    );
  }

  /// Appends the next page.
  ///
  /// Throws a mapped [AppException] on failure so the caller can show a toast.
  /// Products already on screen are always kept.
  Future<void> loadMore() async {
    final ProductListState? current = state.value;
    if (current == null || !current.canLoadMore) return;

    state = AsyncValue<ProductListState>.data(
      current.copyWith(isLoadingMore: true),
    );

    try {
      final ProductQueryResult page = await _repository.fetchProducts(
        businessId: _businessId,
        filter: current.filter,
        cursor: current.cursor,
      );

      final ProductListState? latest = state.value;
      if (latest == null) return;

      state = AsyncValue<ProductListState>.data(
        latest.copyWith(
          products: <Product>[...latest.products, ...page.products],
          hasMore: page.hasMore,
          cursor: page.cursor,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ProductListNotifier.loadMore');
      final ProductListState? latest = state.value;
      if (latest != null) {
        state = AsyncValue<ProductListState>.data(
          latest.copyWith(isLoadingMore: false),
        );
      }
      throw mapError(error, fallbackMessage: ErrorMessages.loadProducts);
    }
  }
}

/// The product list controller.
final AsyncNotifierProvider<ProductListNotifier, ProductListState>
productListProvider =
    AsyncNotifierProvider<ProductListNotifier, ProductListState>(
      ProductListNotifier.new,
    );

/// Products currently on screen, or an empty list while loading.
final Provider<List<Product>> visibleProductsProvider = Provider<List<Product>>(
  (ref) => ref.watch(productListProvider).value?.products ?? const <Product>[],
);

/// Whether the signed-in user may create, edit or deactivate products.
///
/// Derived from [UserRole] in one place so widgets never re-implement
/// permission logic (spec section 23).
final Provider<bool> canManageProductsProvider = Provider<bool>(
  (ref) => ref.watch(currentUserRoleProvider)?.canManageProducts ?? false,
);

/// The filter currently applied to the product list.
///
/// Exposed separately so filter controls rebuild only when the filter changes,
/// not on every product-list update.
final Provider<ProductFilter> productFilterProvider = Provider<ProductFilter>(
  (ref) =>
      ref.watch(productListProvider).value?.filter ?? const ProductFilter(),
);
