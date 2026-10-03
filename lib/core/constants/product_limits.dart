/// Field limits for product data.
///
/// These values intentionally mirror the bounds enforced by
/// `firestore.rules` and `storage.rules`. Client-side validation is a UX
/// convenience only, so the two must stay in sync: if a limit changes here it
/// must change in the security rules as well.
class ProductLimits {
  const ProductLimits._();

  // --- Product name -------------------------------------------------
  static const int nameMinLength = 1;
  static const int nameMaxLength = 120;

  // --- Identifiers --------------------------------------------------
  static const int skuMinLength = 1;
  static const int skuMaxLength = 64;
  static const int barcodeMaxLength = 64;

  /// Prefix used by automatically generated SKUs (spec section 5.2).
  static const String skuPrefix = 'PRD-';

  /// Number of zero-padded digits in a generated SKU.
  /// `PRD-000001`, `PRD-000002`, ...
  static const int skuSequenceDigits = 6;

  /// Upper bound for the SKU counter document.
  static const int maxSkuSequence = 100000000;

  // --- Copy ---------------------------------------------------------
  static const int descriptionMaxLength = 1000;
  static const int categoryNameMaxLength = 120;
  static const int categoryDescriptionMaxLength = 1000;

  // --- Unit ---------------------------------------------------------
  static const int unitMaxLength = 32;

  // --- Money and quantities ----------------------------------------
  static const double maxMoney = 1000000000;

  /// Quantity values are stored as integers to avoid floating point drift.
  static const int maxQuantity = 1000000000;

  // --- Search support ----------------------------------------------
  /// Maximum number of searchable name tokens stored per product.
  static const int maxNameTokens = 24;

  // --- Images -------------------------------------------------------
  /// Maximum accepted product image size (5 MB), matching storage.rules.
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int imageUrlMaxLength = 2048;
}
