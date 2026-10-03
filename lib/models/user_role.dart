/// Roles supported by MamboPoint (spec section 23).
///
/// The [value] strings are the exact values persisted in Firestore and
/// validated by `firestore.rules`; they must not be renamed without also
/// updating the security rules.
enum UserRole {
  owner('owner'),
  admin('admin'),
  manager('manager'),
  staff('staff');

  const UserRole(this.value);

  /// Value stored in Firestore (`users/{uid}.role`).
  final String value;

  /// Parses a persisted role value. Returns `null` for unknown input so
  /// callers can distinguish "missing role" from "staff".
  static UserRole? tryParse(String? raw) {
    if (raw == null) return null;
    final String needle = raw.trim().toLowerCase();
    for (final UserRole role in UserRole.values) {
      if (role.value == needle) return role;
    }
    return null;
  }

  /// Parses a persisted role value, falling back to the least privileged
  /// role when the value is missing or unrecognised.
  static UserRole parseOrLeastPrivileged(String? raw) =>
      tryParse(raw) ?? UserRole.staff;

  /// Owner, Admin and Manager share product-management rights. Staff is
  /// read-only in this phase.
  bool get isManagerial => switch (this) {
    UserRole.owner || UserRole.admin || UserRole.manager => true,
    UserRole.staff => false,
  };

  /// Owner and Admin additionally manage business settings and team members.
  bool get isAdministrative => switch (this) {
    UserRole.owner || UserRole.admin => true,
    UserRole.manager || UserRole.staff => false,
  };

  /// Mirrors `canViewProducts` in firestore.rules: every role may view.
  bool get canViewProducts => true;

  /// Mirrors `canManageProducts` in firestore.rules.
  bool get canManageProducts => isManagerial;

  /// Mirrors `canDeactivateProducts` in firestore.rules.
  bool get canDeactivateProducts => isManagerial;

  /// Mirrors `canManageCategories` in firestore.rules.
  bool get canManageCategories => isManagerial;

  /// Mirrors `canManageBusiness` in firestore.rules.
  bool get canManageBusiness => isAdministrative;

  /// Human readable label for the UI.
  String get label => switch (this) {
    UserRole.owner => 'Owner',
    UserRole.admin => 'Admin',
    UserRole.manager => 'Manager',
    UserRole.staff => 'Staff',
  };
}
