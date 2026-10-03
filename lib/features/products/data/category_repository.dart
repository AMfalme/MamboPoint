import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../models/category.dart';

/// Reads categories for the Product Management module.
///
/// Categories are stored separately from products (spec section 5.4) so they
/// can be managed and reused. Reads are tenant-scoped and enforced by
/// `firestore.rules`.
class CategoryRepository {
  CategoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _categoriesRef(String businessId) =>
      _firestore.collection(FirestorePaths.categories(businessId));

  /// Watches categories ordered by name.
  ///
  /// A live stream is used because the category filter and the product form's
  /// category picker must both react to a quick-created category without the
  /// user leaving the product workflow (spec section 5.4).
  Stream<List<Category>> watchCategories({
    required String businessId,
    bool includeInactive = false,
  }) {
    Query<Map<String, dynamic>> query = _categoriesRef(businessId);
    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('nameLower')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs.map(Category.fromDocument).toList(growable: false),
        )
        .handleError((Object error, StackTrace stackTrace) {
          logError(
            error,
            stackTrace,
            context: 'CategoryRepository.watchCategories',
          );
          throw mapError(error, fallbackMessage: ErrorMessages.loadCategories);
        });
  }

  /// One-shot read, for callers that cannot await a stream.
  Future<List<Category>> fetchCategories({
    required String businessId,
    bool includeInactive = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _categoriesRef(businessId);
      if (!includeInactive) {
        query = query.where('isActive', isEqualTo: true);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query
          .orderBy('nameLower')
          .get();

      return snapshot.docs.map(Category.fromDocument).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'CategoryRepository.fetchCategories',
      );
      throw mapError(error, fallbackMessage: ErrorMessages.loadCategories);
    }
  }

  /// Resolves a category by id, used to keep `Product.categoryName` in sync.
  Future<Category?> getCategory({
    required String businessId,
    required String categoryId,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _categoriesRef(
        businessId,
      ).doc(categoryId).get();
      if (!doc.exists) return null;
      return Category.fromDocument(doc);
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'CategoryRepository.getCategory');
      throw mapError(error, fallbackMessage: ErrorMessages.loadCategories);
    }
  }
}
