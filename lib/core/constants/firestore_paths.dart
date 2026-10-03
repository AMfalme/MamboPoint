/// Canonical Firestore paths for the MamboPoint data model.
///
/// Every repository reads its location from here so the multi-tenant layout
/// (`businesses/{businessId}/...`) is declared in exactly one place.
/// See `docs/FIRESTORE_DATA_MODEL.md`.
class FirestorePaths {
  const FirestorePaths._();

  // --- Collection / document ids ------------------------------------
  static const String usersCollection = 'users';
  static const String businessesCollection = 'businesses';
  static const String membersCollection = 'members';
  static const String categoriesCollection = 'categories';
  static const String productsCollection = 'products';
  static const String countersCollection = 'counters';
  static const String skuIndexCollection = 'skuIndex';
  static const String barcodeIndexCollection = 'barcodeIndex';

  /// Document id of the transactional SKU sequence counter.
  static const String skuCounterDoc = 'sku';

  // --- Readable paths (useful for logs and error messages) ----------
  static String user(String uid) => '$usersCollection/$uid';

  static String business(String businessId) =>
      '$businessesCollection/$businessId';

  static String members(String businessId) =>
      '${business(businessId)}/$membersCollection';

  static String categories(String businessId) =>
      '${business(businessId)}/$categoriesCollection';

  static String products(String businessId) =>
      '${business(businessId)}/$productsCollection';

  static String counters(String businessId) =>
      '${business(businessId)}/$countersCollection';

  static String skuIndex(String businessId) =>
      '${business(businessId)}/$skuIndexCollection';

  static String barcodeIndex(String businessId) =>
      '${business(businessId)}/$barcodeIndexCollection';
}
