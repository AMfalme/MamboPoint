import 'dart:async';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../features/products/data/product_reader.dart';
import '../../features/products/domain/product_filter.dart';

/// In-memory [ProductReader] used only for the review preview.
///
/// Mirrors the semantics of `ProductRepository.fetchProducts` — server-side
/// style filtering/paging over a fixed sample catalogue — so the list,
/// search, filters, sort and pagination can all be exercised without a
/// signed-in Firebase session.
class PreviewProductReader implements ProductReader {
  PreviewProductReader({List<Product>? products, List<Category>? categories})
    : _products = List<Product>.unmodifiable(
        products ?? PreviewCatalog.products,
      ),
      _categories = List<Category>.unmodifiable(
        categories ?? PreviewCatalog.categories,
      );

  final List<Product> _products;
  final List<Category> _categories;

  List<Category> get categories => _categories;

  @override
  Future<ProductQueryResult> fetchProducts({
    required String businessId,
    required ProductFilter filter,
    Object? cursor,
    int limit = 50,
  }) async {
    // Keep the preview honest: behave like a network fetch with paging.
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final List<Product> matching = _products
        .where(filter.matches)
        .toList(growable: false);
    _sortInPlace(matching, filter.sort);

    int start = 0;
    if (cursor is int) {
      start = cursor.clamp(0, matching.length);
    }
    final int end = (start + limit).clamp(0, matching.length);
    final List<Product> page = matching.sublist(start, end);
    final bool hasMore = end < matching.length;

    return ProductQueryResult(
      products: List<Product>.unmodifiable(page),
      hasMore: hasMore,
      cursor: hasMore ? end : null,
    );
  }

  void _sortInPlace(List<Product> products, ProductSortOrder sort) {
    int compare(Product a, Product b) {
      int result;
      switch (sort) {
        case ProductSortOrder.recentlyUpdated:
          result = _compareDateTime(a.updatedAt, b.updatedAt);
          if (result != 0) return -result; // newest first
          break;
        case ProductSortOrder.nameAscending:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          if (result != 0) return result;
          break;
        case ProductSortOrder.sellingPriceDescending:
          result = a.sellingPrice.compareTo(b.sellingPrice);
          if (result != 0) return -result;
          break;
        case ProductSortOrder.sellingPriceAscending:
          result = a.sellingPrice.compareTo(b.sellingPrice);
          if (result != 0) return result;
          break;
        case ProductSortOrder.stockAscending:
          result = a.stockQuantity.compareTo(b.stockQuantity);
          if (result != 0) return result;
          break;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }

    products.sort(compare);
  }

  int _compareDateTime(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }
}

/// Fixed sample catalogue shown by the review preview.
class PreviewCatalog {
  const PreviewCatalog._();

  static const String businessId = 'preview-business';

  static List<Category> get categories => const <Category>[
    Category(id: 'cat-vegetables', name: 'Vegetables'),
    Category(id: 'cat-fruits', name: 'Fruits'),
    Category(id: 'cat-groceries', name: 'Groceries'),
    Category(id: 'cat-beverages', name: 'Beverages'),
  ];

  static List<Product> get products {
    final DateTime now = DateTime.now();
    return <Product>[
      Product(
        id: 'prd-tomatoes',
        name: 'Fresh Tomatoes',
        sku: 'TOM-001',
        barcode: '616110100001',
        categoryId: 'cat-vegetables',
        categoryName: 'Vegetables',
        description: 'Ripe red tomatoes, ideal for kachumbari and cooking.',
        unit: 'Kg',
        purchasePrice: 80,
        sellingPrice: 120,
        stockQuantity: 45,
        lowStockThreshold: 10,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'prd-onions',
        name: 'Red Onions',
        sku: 'ONI-002',
        categoryId: 'cat-vegetables',
        categoryName: 'Vegetables',
        unit: 'Kg',
        purchasePrice: 60,
        sellingPrice: 100,
        stockQuantity: 8,
        lowStockThreshold: 10,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'prd-milk',
        name: 'Fresh Milk 500ml',
        sku: 'MLK-010',
        barcode: '616110100010',
        categoryId: 'cat-beverages',
        categoryName: 'Beverages',
        unit: 'Packet',
        purchasePrice: 55,
        sellingPrice: 70,
        stockQuantity: 0,
        lowStockThreshold: 12,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'prd-maize-flour',
        name: 'Maize Flour 2kg',
        sku: 'PRD-000004',
        categoryId: 'cat-groceries',
        categoryName: 'Groceries',
        unit: 'Packet',
        purchasePrice: 150,
        sellingPrice: 185,
        stockQuantity: 60,
        lowStockThreshold: 15,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'prd-bananas',
        name: 'Bananas (Dozen)',
        sku: 'BAN-005',
        categoryId: 'cat-fruits',
        categoryName: 'Fruits',
        unit: 'Dozen',
        purchasePrice: 90,
        sellingPrice: 130,
        stockQuantity: 22,
        lowStockThreshold: 5,
        isActive: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
