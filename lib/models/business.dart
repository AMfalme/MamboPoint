import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';

/// A tenant (shop) inside MamboPoint.
///
/// Document: `businesses/{businessId}`
///
/// The `id` field must always equal the document id; `firestore.rules`
/// enforces this so a document can never be moved between tenants.
class Business {
  const Business({
    required this.id,
    required this.name,
    required this.ownerId,
    this.currency = defaultCurrency,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// MamboPoint launches with Kenyan Shilling only (spec section 36).
  static const String defaultCurrency = 'KES';

  final String id;
  final String name;

  /// uid of the user who registered the business.
  final String ownerId;

  /// Uppercase ISO-4217 code, validated by `firestore.rules`.
  final String currency;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  factory Business.fromMap(String id, Map<String, dynamic> map) {
    final String currency = stringOrEmpty(map['currency']).toUpperCase();
    return Business(
      id: id,
      name: stringOrEmpty(map['name']),
      ownerId: stringOrEmpty(map['ownerId']),
      currency: currency.length == 3 ? currency : defaultCurrency,
      isActive: boolFrom(map['isActive'], fallback: true),
      createdAt: dateTimeFromFirestore(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
      createdBy: trimmedOrNull(map['createdBy']),
    );
  }

  factory Business.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Business.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'ownerId': ownerId,
    'currency': currency,
    'isActive': isActive,
    'createdAt': timestampFromFirestore(createdAt),
    'updatedAt': timestampFromFirestore(updatedAt),
    'createdBy': createdBy,
  };

  Business copyWith({
    String? name,
    String? ownerId,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) => Business(
    id: id,
    name: name ?? this.name,
    ownerId: ownerId ?? this.ownerId,
    currency: currency ?? this.currency,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Business &&
          other.id == id &&
          other.name == name &&
          other.ownerId == ownerId &&
          other.currency == currency &&
          other.isActive == isActive &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.createdBy == createdBy;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    ownerId,
    currency,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
  );

  @override
  String toString() => 'Business(id: $id, name: $name, currency: $currency)';
}
