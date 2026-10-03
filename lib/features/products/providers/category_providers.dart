import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/providers/session_providers.dart';
import '../data/category_repository.dart';
import '../../../models/category.dart';

final Provider<CategoryRepository> categoryRepositoryProvider =
    Provider<CategoryRepository>(
      (ref) => CategoryRepository(ref.watch(firestoreProvider)),
    );

/// Active categories for the current business, ordered by name.
///
/// Exposed as a stream so a category created inside the product form appears
/// in the filter and the picker immediately (spec section 5.4).
final StreamProvider<List<Category>> categoriesProvider =
    StreamProvider<List<Category>>((ref) {
      final String businessId = ref.watch(requireBusinessIdProvider);
      return ref
          .watch(categoryRepositoryProvider)
          .watchCategories(businessId: businessId);
    });
