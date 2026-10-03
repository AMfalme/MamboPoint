import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../models/app_user.dart';
import '../../../models/business.dart';

/// Reads the MamboPoint documents that link Firebase Authentication to a
/// tenant: `users/{uid}` and `businesses/{businessId}`.
class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(FirestorePaths.usersCollection).doc(uid);

  DocumentReference<Map<String, dynamic>> _businessRef(String businessId) =>
      _firestore
          .collection(FirestorePaths.businessesCollection)
          .doc(businessId);

  /// Watches the profile for [uid].
  ///
  /// Emits `null` when the authentication account has no profile document
  /// yet, which is how a brand new owner is detected (see the bootstrap
  /// sequence in `docs/FIRESTORE_DATA_MODEL.md`).
  Stream<AppUser?> watchUser(String uid) {
    return _userRef(uid)
        .snapshots()
        .map(
          (DocumentSnapshot<Map<String, dynamic>> doc) =>
              doc.exists ? AppUser.fromDocument(doc) : null,
        )
        .handleError((Object error, StackTrace stackTrace) {
          logError(error, stackTrace, context: 'UserRepository.watchUser');
          throw mapError(error, fallbackMessage: ErrorMessages.loadProducts);
        });
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _userRef(
        uid,
      ).get();
      if (!doc.exists) return null;
      return AppUser.fromDocument(doc);
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'UserRepository.getUser');
      throw mapError(error, fallbackMessage: ErrorMessages.loadProducts);
    }
  }

  /// Watches the business document, used for the tenant name and currency.
  Stream<Business?> watchBusiness(String businessId) {
    return _businessRef(businessId)
        .snapshots()
        .map(
          (DocumentSnapshot<Map<String, dynamic>> doc) =>
              doc.exists ? Business.fromDocument(doc) : null,
        )
        .handleError((Object error, StackTrace stackTrace) {
          logError(error, stackTrace, context: 'UserRepository.watchBusiness');
          throw mapError(error, fallbackMessage: ErrorMessages.loadProducts);
        });
  }

  Future<Business?> getBusiness(String businessId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _businessRef(
        businessId,
      ).get();
      if (!doc.exists) return null;
      return Business.fromDocument(doc);
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'UserRepository.getBusiness');
      throw mapError(error, fallbackMessage: ErrorMessages.loadProducts);
    }
  }
}
