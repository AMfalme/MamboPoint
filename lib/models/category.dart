import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';
import '../core/utils/search_tokens.dart';

/// A product category owned by a business.
///
/// Document: `businesses/{businessId}/categories/{categoryId}`
///
/// Categories are never hard-deleted; they are deactivated so historical
/// products keep a valid reference (spec section 9).
class Category {
  const Category({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Lowercase name, persisted so categories can be sorted and matched
  /// case-insensitively without a full scan.
  String get nameLower => normalizeName(name);

  factory Category.fromMap(String id, Map<String, dynamic> map) => Category(
    id: id,
    name: stringOrEmpty(map['name']),
    description: trimmedOrNull(map['description']),
    isActive: boolFrom(map['isActive'], fallback: true),
    createdAt: dateTimeFromFirestore(map['createdAt']),
    updatedAt: dateTimeFromFirestore(map['updatedAt']),
    createdBy: trimmedOrNull(map['createdBy']),
    updatedBy: trimmedOrNull(map['updatedBy']),
  );

  factory Category.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Category.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'nameLower': nameLower,
    'description': description,
    'isActive': isActive,
    'createdAt': timestampFromFirestore(createdAt),
    'updatedAt': timestampFromFirestore(updatedAt),
    'createdBy': createdBy ?? '',
    'updatedBy': updatedBy ?? '',
  };

  Category copyWith({
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) => Category(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.isActive == isActive &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.createdBy == createdBy &&
          other.updatedBy == updatedBy;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
  );

  @override
  String toString() => 'Category(id: $id, name: $name, isActive: $isActive)';
}
