import 'package:flutter_test/flutter_test.dart';
import 'package:mambopoint/models/user_role.dart';

void main() {
  group('parsing', () {
    test('parses every persisted value', () {
      expect(UserRole.tryParse('owner'), UserRole.owner);
      expect(UserRole.tryParse('ADMIN'), UserRole.admin);
      expect(UserRole.tryParse(' manager '), UserRole.manager);
      expect(UserRole.tryParse('staff'), UserRole.staff);
    });

    test('returns null for unknown values', () {
      expect(UserRole.tryParse('superuser'), isNull);
      expect(UserRole.tryParse(null), isNull);
    });

    test('falls back to the least privileged role', () {
      expect(UserRole.parseOrLeastPrivileged('superuser'), UserRole.staff);
      expect(UserRole.parseOrLeastPrivileged(null), UserRole.staff);
      expect(UserRole.parseOrLeastPrivileged('owner'), UserRole.owner);
    });

    test('value round trips for every role', () {
      for (final UserRole role in UserRole.values) {
        expect(UserRole.tryParse(role.value), role);
      }
    });
  });

  group('permissions mirror firestore.rules', () {
    test('every role can view products', () {
      for (final UserRole role in UserRole.values) {
        expect(role.canViewProducts, isTrue);
      }
    });

    test('owner, admin and manager manage products', () {
      expect(UserRole.owner.canManageProducts, isTrue);
      expect(UserRole.admin.canManageProducts, isTrue);
      expect(UserRole.manager.canManageProducts, isTrue);
      expect(UserRole.staff.canManageProducts, isFalse);
    });

    test('staff cannot deactivate or manage categories', () {
      expect(UserRole.staff.canDeactivateProducts, isFalse);
      expect(UserRole.staff.canManageCategories, isFalse);
    });

    test('only owner and admin manage the business', () {
      expect(UserRole.owner.canManageBusiness, isTrue);
      expect(UserRole.admin.canManageBusiness, isTrue);
      expect(UserRole.manager.canManageBusiness, isFalse);
      expect(UserRole.staff.canManageBusiness, isFalse);
    });

    test('labels are human readable', () {
      expect(UserRole.owner.label, 'Owner');
      expect(UserRole.staff.label, 'Staff');
    });
  });
}
