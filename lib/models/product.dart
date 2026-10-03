import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/product_limits.dart';
import '../core/constants/units.dart';
import '../core/utils/firestore_converters.dart';
import '../core/utils/search_tokens.dart';

/// Derived stock state used by the product list, details page and the stock
/// filter (spec section 8).
///
/// This is deliberately computed rather than stored so it can never drift
/// away from `stockQuantity` / `lowStockThreshold`.
enum StockStatus {
  inStock('In Stock'),
  lowStock('Low Stock'),
  outOfStock('Out of Stock');

  const StockStatus(this.label);

  /// Human readable label, also used to keep status communicable without
  /// relying on colour alone (spec section 31).
  final String label;
}

/// A product sold by a business.
///
/// Document: `businesses/{businessId}/products/{productId}`
///
/// Field set and semantics follow spec section 4. Nullable fields
/// (`barcode`, `categoryId`, `categoryName`, `description`, `imageUrl`) are
/// written explicitly as `null` rather than omitted, so the document shape is
/// stable and the security rules can validate every field.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.categoryId,
    this.categoryName,
    this.description,
    this.unit = ProductUnits.defaultUnit,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.stockQuantity = 0,
    this.lowStockThreshold = 0,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.nameTokens = const <String>[],
  });

  final String id;

  /// Display name, required (spec section 5.1).
  final String name;

  /// Stock Keeping Unit, unique within the business (spec section 5.2).
  final String sku;

  /// Optional barcode, unique within the business when present
  /// (spec section 5.3).
  final String? barcode;

  /// Primary relationship to `businesses/{businessId}/categories/{id}`.
  final String? categoryId;

  /// Snapshot of the category name for list performance (spec section 4).
  /// Kept in sync by the category rename path.
  final String? categoryName;

  final String? description;

  /// Unit of measurement, see [ProductUnits] (spec section 6).
  final String unit;

  /// What the business pays to acquire the product.
  final double purchasePrice;

  /// What the customer pays.
  final double sellingPrice;

  /// Quantity on hand. Integer to avoid floating point drift.
  final int stockQuantity;

  /// At or below this quantity the product reports [StockStatus.lowStock].
  final int lowStockThreshold;

  /// Download URL of the image in Firebase Storage, if any.
  final String? imageUrl;

  /// Inactive products stay in Firestore but leave the POS selection
  /// (spec section 9).
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Lowercase word prefixes persisted for `array-contains` search.
  /// See [buildNameTokens].
  final List<String> nameTokens;

  /// Lowercase name, persisted for sorting and case-insensitive matching.
  String get nameLower => normalizeName(name);

  /// Lowercase, whitespace-free SKU for prefix search and uniqueness claims.
  String get skuLower => normalizeSku(sku);

  /// Stock state derived from [stockQuantity] and [lowStockThreshold].
  StockStatus get stockStatus {
    if (stockQuantity <= 0) return StockStatus.outOfStock;
    if (lowStockThreshold > 0 && stockQuantity <= lowStockThreshold) {
      return StockStatus.lowStock;
    }
    return StockStatus.inStock;
  }

  /// Selling price minus purchase price (spec section 19).
  double get estimatedMargin => sellingPrice - purchasePrice;

  /// Gross margin as a percentage of the selling price, or `null` when no
  /// selling price has been set. This is an estimate only: it excludes
  /// overheads, discounts, taxes and wastage.
  double? get marginPercentage {
    if (sellingPrice <= 0) return null;
    return (estimatedMargin / sellingPrice) * 100;
  }

  /// True when the product is priced below cost. The UI warns rather than
  /// blocks, because loss leaders and clearance are legitimate
  /// (spec section 7).
  bool get isBelowCost => sellingPrice < purchasePrice;

  bool get hasImage => (imageUrl ?? '').trim().isNotEmpty;

  bool get hasBarcode => (barcode ?? '').trim().isNotEmpty;

  /// Name of the category to display, falling back to a neutral label.
  String get categoryLabel => (categoryName ?? '').trim().isEmpty
      ? 'Uncategorised'
      : categoryName!.trim();

  /// Case-insensitive match across name, SKU and barcode.
  ///
  /// Used to refine Firestore prefix queries and to filter an already-loaded
  /// page without another round trip (spec section 11).
  bool matchesQuery(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    if (name.toLowerCase().contains(needle)) return true;
    if (skuLower.contains(needle)) return true;
    return (barcode ?? '').toLowerCase().contains(needle);
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
    id: trimmedOrNull(map['id']) ?? id,
    name: stringOrEmpty(map['name']),
    sku: stringOrEmpty(map['sku']),
    barcode: trimmedOrNull(map['barcode']),
    categoryId: trimmedOrNull(map['categoryId']),
    categoryName: trimmedOrNull(map['categoryName']),
    description: trimmedOrNull(map['description']),
    unit: ProductUnits.orDefault(trimmedOrNull(map['unit'])),
    purchasePrice: doubleFrom(map['purchasePrice']),
    sellingPrice: doubleFrom(map['sellingPrice']),
    stockQuantity: intFrom(map['stockQuantity']),
    lowStockThreshold: intFrom(map['lowStockThreshold']),
    imageUrl: trimmedOrNull(map['imageUrl']),
    isActive: boolFrom(map['isActive'], fallback: true),
    createdAt: dateTimeFromFirestore(map['createdAt']),
    updatedAt: dateTimeFromFirestore(map['updatedAt']),
    createdBy: trimmedOrNull(map['createdBy']),
    updatedBy: trimmedOrNull(map['updatedBy']),
    nameTokens: stringListFrom(map['nameTokens']),
  );

  factory Product.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Product.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  /// Builds the SKU for a 1-based sequence number, e.g. `PRD-000007`
  /// (spec section 5.2). The sequence comes from a Firestore transaction on
  /// `businesses/{businessId}/counters/sku`, so it never depends on client
  /// time or on a client-side counter.
  static String skuForSequence(int sequence) =>
      '${ProductLimits.skuPrefix}'
      '${sequence.toString().padLeft(ProductLimits.skuSequenceDigits, '0')}';

  /// Full document payload. Always writes every field, including explicit
  /// `null`s, so the stored shape stays stable and complete for the security
  /// rules to validate.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'nameLower': nameLower,
    'nameTokens': nameTokens.isEmpty ? buildNameTokens(name) : nameTokens,
    'sku': sku,
    'skuLower': skuLower,
    'barcode': barcode,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'description': description,
    'unit': unit,
    'purchasePrice': purchasePrice,
    'sellingPrice': sellingPrice,
    'stockQuantity': stockQuantity,
    'lowStockThreshold': lowStockThreshold,
    'imageUrl': imageUrl,
    'isActive': isActive,
    'createdAt': timestampFromFirestore(createdAt),
    'updatedAt': timestampFromFirestore(updatedAt),
    'createdBy': createdBy ?? '',
    'updatedBy': updatedBy ?? '',
  };

  /// Payload for `set()` on a new document. Audit fields are stamped with the
  /// server timestamp and the acting user so they cannot be spoofed.
  Map<String, dynamic> toCreateMap({
    required String uid,
    required FieldValue serverTimestamp,
  }) => <String, dynamic>{
    ...toMap(),
    'createdAt': serverTimestamp,
    'updatedAt': serverTimestamp,
    'createdBy': uid,
    'updatedBy': uid,
  };

  /// Payload for `update()` on an existing document. `createdAt`/`createdBy`
  /// are omitted so they survive the merge untouched, which is also what the
  /// security rules require.
  Map<String, dynamic> toUpdateMap({
    required String uid,
    required FieldValue serverTimestamp,
  }) {
    final Map<String, dynamic> data = toMap()
      ..remove('createdAt')
      ..remove('createdBy');
    return <String, dynamic>{
      ...data,
      'updatedAt': serverTimestamp,
      'updatedBy': uid,
    };
  }

  /// Copy with individual fields replaced.
  ///
  /// Note: because nullable fields cannot distinguish "not supplied" from
  /// "clear this field", use the form-to-model mapper when clearing
  /// `barcode`, `categoryId`, `categoryName`, `description` or `imageUrl`.
  Product copyWith({
    String? name,
    String? sku,
    String? barcode,
    String? categoryId,
    String? categoryName,
    String? description,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    int? stockQuantity,
    int? lowStockThreshold,
    String? imageUrl,
    bool? isActive,
    DateTime? updatedAt,
    String? updatedBy,
    List<String>? nameTokens,
  }) => Product(
    id: id,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    barcode: barcode ?? this.barcode,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    description: description ?? this.description,
    unit: unit ?? this.unit,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    stockQuantity: stockQuantity ?? this.stockQuantity,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    imageUrl: imageUrl ?? this.imageUrl,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    nameTokens: nameTokens ?? this.nameTokens,
  );

  /// Copy that applies a new name and keeps the derived search fields in
  /// sync. Prefer this over [copyWith] whenever the name changes.
  Product withName(String newName) => Product(
    id: id,
    name: newName,
    sku: sku,
    barcode: barcode,
    categoryId: categoryId,
    categoryName: categoryName,
    description: description,
    unit: unit,
    purchasePrice: purchasePrice,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    lowStockThreshold: lowStockThreshold,
    imageUrl: imageUrl,
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
    createdBy: createdBy,
    updatedBy: updatedBy,
    nameTokens: buildNameTokens(newName),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          other.id == id &&
          other.name == name &&
          other.sku == sku &&
          other.barcode == barcode &&
          other.categoryId == categoryId &&
          other.categoryName == categoryName &&
          other.description == description &&
          other.unit == unit &&
          other.purchasePrice == purchasePrice &&
          other.sellingPrice == sellingPrice &&
          other.stockQuantity == stockQuantity &&
          other.lowStockThreshold == lowStockThreshold &&
          other.imageUrl == imageUrl &&
          other.isActive == isActive &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.createdBy == createdBy &&
          other.updatedBy == updatedBy;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sku,
    barcode,
    categoryId,
    categoryName,
    description,
    unit,
    purchasePrice,
    sellingPrice,
    stockQuantity,
    lowStockThreshold,
    imageUrl,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
  );

  @override
  String toString() =>
      'Product(id: $id, name: $name, sku: $sku, isActive: $isActive)';
}
