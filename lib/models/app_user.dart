import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';
import 'business.dart';
import 'user_role.dart';

/// Application profile for an authenticated Firebase user.
///
/// Document: `users/{uid}`
///
/// This document is the bridge between Firebase Authentication and the
/// multi-tenant data model: it records which business the user belongs to and
/// which [UserRole] they hold. Authorization in the client and in
/// `firestore.rules` both read it.
class AppUser {
  const AppUser({
    required this.uid,
    required this.businessId,
    required this.role,
    this.email = '',
    this.displayName = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;

  /// Business this user primarily belongs to.
  final String businessId;

  final UserRole role;
  final String email;
  final String displayName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Name to show in the UI, falling back to the email local part.
  String get friendlyName {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (email.contains('@')) return email.split('@').first;
    return email;
  }

  bool get canManageProducts => role.canManageProducts;
  bool get canDeactivateProducts => role.canDeactivateProducts;
  bool get canManageCategories => role.canManageCategories;
  bool get canManageBusiness => role.canManageBusiness;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: trimmedOrNull(map['uid']) ?? uid,
    businessId: stringOrEmpty(map['businessId']),
    role: UserRole.parseOrLeastPrivileged(map['role'] as String?),
    email: stringOrEmpty(map['email']),
    displayName: stringOrEmpty(map['displayName']),
    isActive: boolFrom(map['isActive'], fallback: true),
    createdAt: dateTimeFromFirestore(map['createdAt']),
    updatedAt: dateTimeFromFirestore(map['updatedAt']),
  );

  factory AppUser.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  /// Builds the Firestore payload. `uid` and `role` are immutable once
  /// written for a non-administrative user, so edits must reuse them.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'uid': uid,
    'businessId': businessId,
    'role': role.value,
    'email': email,
    'displayName': displayName,
    'isActive': isActive,
    'createdAt': timestampFromFirestore(createdAt),
    'updatedAt': timestampFromFirestore(updatedAt),
  };

  /// Payload used when bootstrapping a brand new owner profile.
  ///
  /// The security rules only allow this when `businessId` refers to a
  /// business whose `ownerId` is this same user.
  static Map<String, dynamic> newOwnerMap({
    required String uid,
    required String businessId,
    required String email,
    required String displayName,
    required FieldValue serverTimestamp,
  }) => <String, dynamic>{
    'uid': uid,
    'businessId': businessId,
    'role': UserRole.owner.value,
    'email': email.trim(),
    'displayName': displayName.trim(),
    'isActive': true,
    'createdAt': serverTimestamp,
    'updatedAt': serverTimestamp,
  };

  /// Payload used to register a business owned by [uid].
  static Map<String, dynamic> newBusinessMap({
    required String businessId,
    required String name,
    required String uid,
    String currency = Business.defaultCurrency,
    required FieldValue serverTimestamp,
  }) => <String, dynamic>{
    'id': businessId,
    'name': name.trim(),
    'ownerId': uid,
    'currency': currency.toUpperCase(),
    'isActive': true,
    'createdAt': serverTimestamp,
    'updatedAt': serverTimestamp,
    'createdBy': uid,
  };

  AppUser copyWith({
    String? businessId,
    UserRole? role,
    String? email,
    String? displayName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppUser(
    uid: uid,
    businessId: businessId ?? this.businessId,
    role: role ?? this.role,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.uid == uid &&
          other.businessId == businessId &&
          other.role == role &&
          other.email == email &&
          other.displayName == displayName &&
          other.isActive == isActive &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    uid,
    businessId,
    role,
    email,
    displayName,
    isActive,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'AppUser(uid: $uid, businessId: $businessId, role: ${role.value})';
}
