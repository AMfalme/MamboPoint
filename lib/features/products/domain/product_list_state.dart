import 'package:flutter/foundation.dart';

import '../../../models/product.dart';
import 'product_filter.dart';

/// Immutable state of the product list screen.
@immutable
class ProductListState {
  const ProductListState({
    this.products = const <Product>[],
    this.filter = const ProductFilter(),
    this.isReloading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.cursor,
  });

  final List<Product> products;

  /// The filter that produced [products]. Kept in state so the notifier can
  /// derive the next filter without the widget having to pass it back in.
  final ProductFilter filter;

  /// True while the first page is being (re)fetched for a new filter.
  ///
  /// Tracked explicitly rather than by swapping the whole [AsyncValue] to
  /// loading, so already-loaded rows stay visible while a filter is applied
  /// (spec section 26: never blank the screen during a Firebase operation).
  final bool isReloading;

  /// True while an additional page is being fetched.
  final bool isLoadingMore;

  /// Whether another page is available.
  final bool hasMore;

  /// Opaque paging token produced by the repository.
  final Object? cursor;

  bool get isEmpty => products.isEmpty;

  /// True when the list is empty *because of* filters. Selects the
  /// "No products found" empty state rather than "No products yet"
  /// (spec section 28).
  bool get isEmptyBecauseOfFilters => products.isEmpty && filter.hasAnyFilter;

  /// Search results come back as one bounded set, so "load more" is only
  /// offered while browsing by filter and sort.
  bool get canLoadMore =>
      hasMore && !filter.hasQuery && !isLoadingMore && !isReloading;

  ProductListState copyWith({
    List<Product>? products,
    ProductFilter? filter,
    bool? isReloading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? cursor,
  }) => ProductListState(
    products: products ?? this.products,
    filter: filter ?? this.filter,
    isReloading: isReloading ?? this.isReloading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    cursor: cursor ?? this.cursor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductListState &&
          identical(other.products, products) &&
          other.filter == filter &&
          other.isReloading == isReloading &&
          other.isLoadingMore == isLoadingMore &&
          other.hasMore == hasMore &&
          other.cursor == cursor;

  @override
  int get hashCode => Object.hash(
    identityHashCode(products),
    filter,
    isReloading,
    isLoadingMore,
    hasMore,
  );

  @override
  String toString() =>
      'ProductListState(${products.length} products, hasMore: $hasMore, '
      'isReloading: $isReloading, isLoadingMore: $isLoadingMore, '
      'filter: $filter)';
}
