/// Predefined units of measurement offered by the Product Management module
/// (spec section 6).
///
/// Units are a controlled vocabulary shared by the UI and the validators, so
/// they live in code rather than in Firestore. `Product.unit` is persisted as
/// a plain string, which lets a business introduce a custom unit later
/// without a schema migration.
class ProductUnits {
  const ProductUnits._();

  static const String piece = 'Piece';
  static const String kilogram = 'Kg';
  static const String gram = 'Gram';
  static const String litre = 'Litre';
  static const String millilitre = 'Millilitre';
  static const String bottle = 'Bottle';
  static const String packet = 'Packet';
  static const String box = 'Box';
  static const String dozen = 'Dozen';
  static const String metre = 'Metre';
  static const String roll = 'Roll';
  static const String crate = 'Crate';
  static const String sack = 'Sack';

  /// Default unit applied when a product is created without an explicit unit.
  static const String defaultUnit = piece;

  /// Ordered list used to populate unit dropdowns.
  static const List<String> all = <String>[
    piece,
    kilogram,
    gram,
    litre,
    millilitre,
    bottle,
    packet,
    box,
    dozen,
    metre,
    roll,
    crate,
    sack,
  ];

  /// Whether [unit] is part of the predefined vocabulary.
  static bool isKnown(String unit) => all.contains(unit);

  /// Returns [unit] when known, otherwise [defaultUnit].
  static String orDefault(String? unit) {
    final String trimmed = (unit ?? '').trim();
    return trimmed.isEmpty ? defaultUnit : trimmed;
  }
}
