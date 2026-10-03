import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambopoint/core/constants/units.dart';
import 'package:mambopoint/models/product.dart';

void main() {
  const Product tomatoes = Product(
    id: 'p1',
    name: 'Fresh Tomatoes',
    sku: 'TOM-001',
    barcode: '616110123456',
    categoryId: 'c1',
    categoryName: 'Vegetables',
    unit: ProductUnits.kilogram,
    purchasePrice: 80,
    sellingPrice: 120,
    stockQuantity: 45,
    lowStockThreshold: 10,
  );

  group('stockStatus', () {
    test('is inStock above the threshold', () {
      expect(tomatoes.stockStatus, StockStatus.inStock);
    });

    test('is lowStock at the threshold', () {
      expect(
        tomatoes.copyWith(stockQuantity: 10).stockStatus,
        StockStatus.lowStock,
      );
    });

    test('is lowStock below the threshold', () {
      expect(
        tomatoes.copyWith(stockQuantity: 3).stockStatus,
        StockStatus.lowStock,
      );
    });

    test('outOfStock wins over lowStock at zero', () {
      expect(
        tomatoes.copyWith(stockQuantity: 0).stockStatus,
        StockStatus.outOfStock,
      );
    });

    test('a threshold of zero disables the low stock warning', () {
      expect(
        tomatoes.copyWith(lowStockThreshold: 0).stockStatus,
        StockStatus.inStock,
      );
    });
  });

  group('margin', () {
    test('is selling price minus purchase price', () {
      expect(tomatoes.estimatedMargin, 40);
    });

    test('percentage follows the spec worked example', () {
      expect(tomatoes.marginPercentage, closeTo(33.33, 0.01));
    });

    test('is null without a selling price', () {
      expect(tomatoes.copyWith(sellingPrice: 0).marginPercentage, isNull);
    });

    test('flags below cost pricing without blocking it', () {
      expect(tomatoes.copyWith(sellingPrice: 50).isBelowCost, isTrue);
      expect(tomatoes.isBelowCost, isFalse);
    });
  });

  group('search helpers', () {
    test('matchesQuery is case insensitive across name, sku and barcode', () {
      expect(tomatoes.matchesQuery('tomatoes'), isTrue);
      expect(tomatoes.matchesQuery('TOM-001'), isTrue);
      expect(tomatoes.matchesQuery('6161101'), isTrue);
      expect(tomatoes.matchesQuery('banana'), isFalse);
    });

    test('an empty query matches everything', () {
      expect(tomatoes.matchesQuery('  '), isTrue);
    });
  });

  group('serialisation', () {
    test('round trips through a Firestore map', () {
      final Product restored = Product.fromMap('p1', tomatoes.toMap());
      expect(restored.name, tomatoes.name);
      expect(restored.sku, tomatoes.sku);
      expect(restored.sellingPrice, tomatoes.sellingPrice);
      expect(restored.stockQuantity, tomatoes.stockQuantity);
      expect(restored.unit, ProductUnits.kilogram);
      expect(restored.isActive, isTrue);
    });

    test('always writes every field the security rules validate', () {
      final Map<String, dynamic> map = tomatoes.toMap();
      const List<String> requiredKeys = <String>[
        'id',
        'name',
        'nameLower',
        'nameTokens',
        'sku',
        'skuLower',
        'barcode',
        'categoryId',
        'categoryName',
        'description',
        'unit',
        'purchasePrice',
        'sellingPrice',
        'stockQuantity',
        'lowStockThreshold',
        'imageUrl',
        'isActive',
        'createdBy',
        'updatedBy',
      ];
      for (final String key in requiredKeys) {
        expect(map.containsKey(key), isTrue, reason: 'missing $key');
      }
    });

    test('derives nameLower and nameTokens from the name', () {
      final Map<String, dynamic> map = tomatoes.toMap();
      expect(map['nameLower'], 'fresh tomatoes');
      expect(map['nameTokens'], contains('tom'));
    });

    test('toCreateMap stamps audit fields with the acting user', () {
      final Map<String, dynamic> map = tomatoes.toCreateMap(
        uid: 'u1',
        serverTimestamp: FieldValue.serverTimestamp(),
      );
      expect(map['createdBy'], 'u1');
      expect(map['updatedBy'], 'u1');
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('toUpdateMap never rewrites createdAt/createdBy', () {
      final Map<String, dynamic> map = tomatoes.toUpdateMap(
        uid: 'u2',
        serverTimestamp: FieldValue.serverTimestamp(),
      );
      expect(map.containsKey('createdAt'), isFalse);
      expect(map.containsKey('createdBy'), isFalse);
      expect(map['updatedBy'], 'u2');
    });

    test('skuForSequence zero pads the generated SKU', () {
      expect(Product.skuForSequence(1), 'PRD-000001');
      expect(Product.skuForSequence(1234), 'PRD-001234');
    });

    test('withName refreshes the derived search fields', () {
      final Product renamed = tomatoes.withName('Ripe Tomatoes');
      expect(renamed.toMap()['nameLower'], 'ripe tomatoes');
      expect(renamed.toMap()['nameTokens'], contains('rip'));
    });
  });

  group('display helpers', () {
    test('categoryLabel falls back for uncategorised products', () {
      expect(tomatoes.categoryLabel, 'Vegetables');
      const Product uncategorised = Product(
        id: 'p2',
        name: 'Salt',
        sku: 'SLT-001',
      );
      expect(uncategorised.categoryLabel, 'Uncategorised');
      expect(uncategorised.hasImage, isFalse);
      expect(uncategorised.hasBarcode, isFalse);
    });
  });
}
