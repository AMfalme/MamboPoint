import 'package:flutter/foundation.dart';

import '../../../models/product.dart';

/// Status filter options (spec section 12).
enum ProductStatusFilter {
  all('All'),
  active('Active'),
  inactive('Inactive');

  const ProductStatusFilter(this.label);

  final String label;

  /// Firestore-side predicate. `null` means "do not constrain this field",
  /// which keeps the query index-free when the filter is not in use.
  bool? get isActiveValue => switch (this) {
    ProductStatusFilter.all => null,
    ProductStatusFilter.active => true,
    ProductStatusFilter.inactive => false,
  };
}

/// Stock filter options (spec section 12).
///
/// Stock state is derived from `stockQuantity` and `lowStockThreshold`, so
/// unlike status it cannot be expressed as a simple Firestore equality
/// filter. It is applied client-side over the fetched page, which keeps
/// `stockStatus` out of the persisted schema entirely.
enum ProductStockFilter {
  all('All'),
  inStock('In Stock'),
  lowStock('Low Stock'),
  outOfStock('Out of Stock');

  const ProductStockFilter(this.label);

  final String label;

  bool matches(Product product) => switch (this) {
    ProductStockFilter.all => true,
    ProductStockFilter.inStock => product.stockStatus == StockStatus.inStock,
    ProductStockFilter.lowStock => product.stockStatus == StockStatus.lowStock,
    ProductStockFilter.outOfStock =>
      product.stockStatus == StockStatus.outOfStock,
  };
}

/// Sort options (spec section 13).
enum ProductSortOrder {
  recentlyUpdated('Recently updated'),
  nameAscending('Name (A to Z)'),
  sellingPriceDescending('Selling price (high to low)'),
  sellingPriceAscending('Selling price (low to high)'),
  stockAscending('Stock (low to high)');

  const ProductSortOrder(this.label);

  final String label;

  /// Persisted field this order sorts on. Resolved here so the UI never has
  /// to know Firestore field names.
  String get firestoreField => switch (this) {
    ProductSortOrder.recentlyUpdated => 'updatedAt',
    ProductSortOrder.nameAscending => 'nameLower',
    ProductSortOrder.sellingPriceDescending => 'sellingPrice',
    ProductSortOrder.sellingPriceAscending => 'sellingPrice',
    ProductSortOrder.stockAscending => 'stockQuantity',
  };

  /// Whether the query returns highest/newest first.
  bool get descending => switch (this) {
    ProductSortOrder.recentlyUpdated => true,
    ProductSortOrder.sellingPriceDescending => true,
    ProductSortOrder.nameAscending => false,
    ProductSortOrder.sellingPriceAscending => false,
    ProductSortOrder.stockAscending => false,
  };

  /// Stable tie-breaker so paging does not jitter when many products share
  /// the primary sort value.
  ProductSortOrder? get tieBreaker => this == ProductSortOrder.nameAscending
      ? null
      : ProductSortOrder.nameAscending;
}

/// The complete filter state of the product list.
///
/// Immutable and value-comparable so a provider can cheaply detect a real
/// change and avoid a redundant Firestore round trip.
@immutable
class ProductFilter {
  const ProductFilter({
    this.query = '',
    this.categoryId,
    this.status = ProductStatusFilter.all,
    this.stock = ProductStockFilter.all,
    this.sort = ProductSortOrder.recentlyUpdated,
  });

  /// Free-text search across name, SKU and barcode (spec section 11).
  final String query;

  /// `null` means all categories.
  final String? categoryId;

  final ProductStatusFilter status;
  final ProductStockFilter stock;
  final ProductSortOrder sort;

  String get normalizedQuery => query.trim().toLowerCase();

  bool get hasQuery => normalizedQuery.isNotEmpty;

  /// True when anything narrows the result set. Decides between the
  /// "no products yet" and "no products found" empty states (spec 28).
  bool get hasAnyFilter =>
      hasQuery ||
      categoryId != null ||
      status != ProductStatusFilter.all ||
      stock != ProductStockFilter.all;

  /// Number of active refinements, shown as a badge on the filter control.
  int get activeFilterCount =>
      (categoryId != null ? 1 : 0) +
      (status != ProductStatusFilter.all ? 1 : 0) +
      (stock != ProductStockFilter.all ? 1 : 0);

  ProductFilter withQuery(String value) => ProductFilter(
    query: value,
    categoryId: categoryId,
    status: status,
    stock: stock,
    sort: sort,
  );

  /// Passing `null` clears the category filter, which is why this is a
  /// dedicated method rather than part of a generic `copyWith`.
  ProductFilter withCategory(String? value) => ProductFilter(
    query: query,
    categoryId: value,
    status: status,
    stock: stock,
    sort: sort,
  );

  ProductFilter withStatus(ProductStatusFilter value) => ProductFilter(
    query: query,
    categoryId: categoryId,
    status: value,
    stock: stock,
    sort: sort,
  );

  ProductFilter withStock(ProductStockFilter value) => ProductFilter(
    query: query,
    categoryId: categoryId,
    status: status,
    stock: value,
    sort: sort,
  );

  ProductFilter withSort(ProductSortOrder value) => ProductFilter(
    query: query,
    categoryId: categoryId,
    status: status,
    stock: stock,
    sort: value,
  );

  /// Clears refinements but keeps the chosen sort order, so the user does not
  /// lose their preferred view when resetting filters.
  ProductFilter cleared() => ProductFilter(sort: sort);

  /// Client-side refinement applied to a server result page.
  ///
  /// Firestore cannot express these combinations (case-insensitive
  /// substring search, derived stock state), so the query narrows the result
  /// set cheaply and this predicate makes it exact.
  bool matches(Product product) {
    if (hasQuery && !product.matchesQuery(normalizedQuery)) return false;

    if (categoryId != null && product.categoryId != categoryId) return false;

    switch (status) {
      case ProductStatusFilter.all:
        break;
      case ProductStatusFilter.active:
        if (!product.isActive) return false;
      case ProductStatusFilter.inactive:
        if (product.isActive) return false;
    }

    if (!stock.matches(product)) return false;

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductFilter &&
          other.query == query &&
          other.categoryId == categoryId &&
          other.status == status &&
          other.stock == stock &&
          other.sort == sort;

  @override
  int get hashCode => Object.hash(query, categoryId, status, stock, sort);

  @override
  String toString() =>
      'ProductFilter(query: $query, categoryId: $categoryId, '
      'status: ${status.name}, stock: ${stock.name}, sort: ${sort.name})';
}

