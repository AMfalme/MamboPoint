import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../models/app_user.dart';
import '../../../models/business.dart';
import '../../../models/user_role.dart';
import '../data/user_repository.dart';

final Provider<UserRepository> userRepositoryProvider =
    Provider<UserRepository>(
      (ref) => UserRepository(ref.watch(firestoreProvider)),
    );

/// MamboPoint profile of the signed-in user.
///
/// Emits `null` when signed out, and also when the account exists but has no
/// profile document yet.
final StreamProvider<AppUser?> currentUserProfileProvider =
    StreamProvider<AppUser?>((ref) {
      final User? user = ref.watch(authStateChangesProvider).value;
      if (user == null) return Stream<AppUser?>.value(null);
      return ref.watch(userRepositoryProvider).watchUser(user.uid);
    });

/// Business the signed-in user belongs to.
///
/// Null while the profile is still loading or when there is no session.
final Provider<String?> currentBusinessIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProfileProvider).value?.businessId,
);

/// The signed-in user's role.
///
/// Read from one place so permission checks are never duplicated or
/// re-implemented inside widgets (spec section 23).
final Provider<UserRole?> currentUserRoleProvider = Provider<UserRole?>(
  (ref) => ref.watch(currentUserProfileProvider).value?.role,
);

/// The current tenant record, for the business name and currency.
final StreamProvider<Business?> currentBusinessProvider =
    StreamProvider<Business?>((ref) {
      final String? businessId = ref.watch(currentBusinessIdProvider);
      if (businessId == null || businessId.isEmpty) {
        return Stream<Business?>.value(null);
      }
      return ref.watch(userRepositoryProvider).watchBusiness(businessId);
    });

/// Business id required by every tenant-scoped query.
///
/// Throws a user-safe [AppException] when there is no session, so dependent
/// providers surface a "please sign in" state instead of firing a query that
/// the security rules would reject.
final Provider<String> requireBusinessIdProvider = Provider<String>((ref) {
  final String? businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null || businessId.isEmpty) {
    throw const AppException(
      userMessage: 'Please sign in to manage your products.',
      technicalMessage: 'No businessId on the current user profile',
      code: 'no-session',
    );
  }
  return businessId;
});
