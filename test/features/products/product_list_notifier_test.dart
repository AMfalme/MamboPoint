import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambopoint/features/auth/providers/session_providers.dart';
import 'package:mambopoint/features/products/data/product_reader.dart';
import 'package:mambopoint/features/products/domain/product_filter.dart';
import 'package:mambopoint/features/products/domain/product_list_state.dart';
import 'package:mambopoint/features/products/providers/product_list_provider.dart';
import 'package:mambopoint/models/product.dart';

/// In-memory [ProductReader] that applies the same refinement and ordering the
/// Firestore implementation does.
///
/// Reusing the real [ProductFilter.matches] predicate means these tests cover
/// the actual filtering contract rather than a re-implementation of it.
class _FakeProductReader implements ProductReader {
  _FakeProductReader(this.catalog);

  final List<Product> catalog;
  int fetchCount = 0;
  final List<ProductFilter> receivedFilters = <ProductFilter>[];
  bool failNextFetch = false;

  @override
  Future<ProductQueryResult> fetchProducts({
    required String businessId,
    required ProductFilter filter,
    Object? cursor,
    int limit = 50,
  }) async {
    if (failNextFetch) {
      failNextFetch = false;
      throw StateError('simulated reader failure');
    }

    fetchCount++;
    receivedFilters.add(filter);

    final List<Product> matches = catalog.where(filter.matches).toList();
    _sort(matches, filter.sort);

    final int start = cursor is int ? cursor : 0;
    final int end = (start + limit).clamp(0, matches.length);

    return ProductQueryResult(
      products: matches.sublist(start, end),
      hasMore: end < matches.length,
      cursor: end,
    );
  }

  static void _sort(List<Product> products, ProductSortOrder sort) {
    final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);
    products.sort((Product a, Product b) {
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
    });
  }
}

Product _product(
  String id, {
  required String name,
  required String sku,
  String? barcode,
  String? categoryId,
  double sellingPrice = 100,
  int stockQuantity = 20,
  int lowStockThreshold = 5,
  bool isActive = true,
}) => Product(
  id: id,
  name: name,
  sku: sku,
  barcode: barcode,
  categoryId: categoryId,
  sellingPrice: sellingPrice,
  purchasePrice: sellingPrice / 2,
  stockQuantity: stockQuantity,
  lowStockThreshold: lowStockThreshold,
  isActive: isActive,
);

void main() {
  late List<Product> catalog;
  late _FakeProductReader reader;

  setUp(() {
    catalog = <Product>[
      _product(
        'p1',
        name: 'Fresh Tomatoes',
        sku: 'TOM-001',
        barcode: '616110123456',
        categoryId: 'veg',
        stockQuantity: 45,
      ),
      _product(
        'p2',
        name: 'Bananas',
        sku: 'BAN-001',
        categoryId: 'fruit',
        sellingPrice: 50,
        stockQuantity: 4,
        lowStockThreshold: 10,
      ),
      _product(
        'p3',
        name: 'Cooking Salt',
        sku: 'SLT-001',
        categoryId: 'grocery',
        stockQuantity: 0,
      ),
      _product(
        'p4',
        name: 'Stale Bread',
        sku: 'BRD-001',
        isActive: false,
        stockQuantity: 2,
      ),
    ];
    reader = _FakeProductReader(catalog);
  });

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer(
      // The element type is inferred: Riverpod 3 exposes `Override` from
      // `package:flutter_riverpod/misc.dart`, which tests do not need here.
      overrides: [
        productReaderProvider.overrideWithValue(reader),
        requireBusinessIdProvider.overrideWithValue('biz-1'),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settleDebounce() => Future<void>.delayed(
    ProductListNotifier.searchDebounce + const Duration(milliseconds: 40),
  );

  /// Waits for the microtask queue so an un-debounced filter change lands.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('loads every product on first build', () async {
    final ProviderContainer container = makeContainer();

    final ProductListState state = await container.read(
      productListProvider.future,
    );

    expect(state.products, hasLength(4));
    expect(
      reader.receivedFilters.single.sort,
      ProductSortOrder.recentlyUpdated,
    );
  });

  test('status filter excludes inactive products', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);

    container
        .read(productListProvider.notifier)
        .setStatus(ProductStatusFilter.active);
    await settle();

    final ProductListState state = container.read(productListProvider).value!;
    expect(state.products, hasLength(3));
    expect(state.products.any((Product p) => p.name == 'Stale Bread'), isFalse);
  });

  test('status filter can select only inactive products', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);

    container
        .read(productListProvider.notifier)
        .setStatus(ProductStatusFilter.inactive);
    await settle();

    final ProductListState state = container.read(productListProvider).value!;
    expect(state.products.single.name, 'Stale Bread');
  });

  test('category filter narrows to one category', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);

    container.read(productListProvider.notifier).setCategory('fruit');
    await settle();

    final ProductListState state = container.read(productListProvider).value!;
    expect(state.products.single.name, 'Bananas');
  });

  test('stock filter keeps only low stock products', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);
    final ProductListNotifier notifier = container.read(
      productListProvider.notifier,
    );

    // Restrict to active products first, because the seeded catalogue also
    // contains an inactive low-stock product ("Stale Bread").
    notifier.setStatus(ProductStatusFilter.active);
    await settle();
    notifier.setStock(ProductStockFilter.lowStock);
    await settle();

    final ProductListState state = container.read(productListProvider).value!;
    expect(state.products.single.name, 'Bananas');
  });

  test('stock filter keeps only out of stock products', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);

    container
        .read(productListProvider.notifier)
        .setStock(ProductStockFilter.outOfStock);
    await settle();

    final ProductListState state = container.read(productListProvider).value!;
    expect(state.products.single.name, 'Cooking Salt');
  });

  test('search by name is debounced, then applied', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);
    final int fetchesBefore = reader.fetchCount;

    container.read(productListProvider.notifier).setQuery('toma');

    // Nothing may be queried before the debounce elapses.
    expect(reader.fetchCount, fetchesBefore);

    await settleDebounce();

    expect(
      container.read(productListProvider).value!.products.single.name,
      'Fresh Tomatoes',
    );
  });

  test('search also matches SKU and barcode', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);
    final ProductListNotifier notifier = container.read(
      productListProvider.notifier,
    );

    notifier.setQuery('ban');
    await settleDebounce();
    expect(
      container.read(productListProvider).value!.products.single.name,
      'Bananas',
    );

    notifier.setQuery('616110');
    await settleDebounce();
    expect(
      container.read(productListProvider).value!.products.single.name,
      'Fresh Tomatoes',
    );
  });

  test('search and status filter combine', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);
    final ProductListNotifier notifier = container.read(
      productListProvider.notifier,
    );

    // "bread" only matches the inactive product, so an active-only search
    // must come back empty rather than surfacing it.
    notifier.setStatus(ProductStatusFilter.active);
    await settle();
    notifier.setQuery('bread');
    await settleDebounce();

    expect(container.read(productListProvider).value!.products, isEmpty);
  });

  test('an unmatched search yields an empty result, not an error', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);

    container.read(productListProvider.notifier).setQuery('zzzz');
    await settleDebounce();

    final AsyncValue<ProductListState> result = container.read(
      productListProvider,
    );
    expect(result.hasError, isFalse);
    expect(result.value!.products, isEmpty);
    expect(result.value!.isEmptyBecauseOfFilters, isTrue);
  });

  test('clearing filters keeps the chosen sort order', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);
    final ProductListNotifier notifier = container.read(
      productListProvider.notifier,
    );

    notifier.setSort(ProductSortOrder.sellingPriceAscending);
    await settle();
    notifier.setCategory('veg');
    await settle();
    notifier.clearFilters();
    await settle();

    final ProductFilter filter = container.read(productListProvider).value!.filter;
    expect(filter.categoryId, isNull);
    expect(filter.sort, ProductSortOrder.sellingPriceAscending);
  });

  test('resetAll clears the sort order back to the default', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);
    final ProductListNotifier notifier = container.read(
      productListProvider.notifier,
    );

    notifier.setSort(ProductSortOrder.nameAscending);
    await settle();
    notifier.resetAll();
    await settle();

    expect(
      container.read(productListProvider).value!.filter.sort,
      ProductSortOrder.recentlyUpdated,
    );
  });

  test('loadMore keeps the list intact when there is nothing more', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);

    await container.read(productListProvider.notifier).loadMore();

    expect(container.read(productListProvider).value!.products, hasLength(4));
  });

  test('a reader failure surfaces as an error state', () async {
    final ProviderContainer container = makeContainer();
    await container.read(productListProvider.future);

    reader.failNextFetch = true;
    await container.read(productListProvider.notifier).refresh();

    expect(container.read(productListProvider).hasError, isTrue);
  });
}

