import 'package:intl/intl.dart';

/// Single source of truth for money display (spec section 36).
///
/// The spec requires one consistent format across the whole application and
/// explicitly forbids hardcoding currency formatting inside components, so
/// every price in the UI goes through here.
///
/// Chosen format: `KSh 1,250.00` — the symbol is unambiguous to a Kenyan
/// retailer, thousand separators make large totals readable, and always
/// showing two decimals keeps columns aligned and removes any doubt about
/// rounding in a financial product.
class CurrencyFormatter {
  const CurrencyFormatter._();

  /// ISO-4217 code, used where a symbol would be ambiguous.
  static const String code = 'KES';

  /// Display prefix.
  static const String symbol = 'KSh';

  static final NumberFormat _money = NumberFormat('#,##0.00', 'en');
  static final NumberFormat _whole = NumberFormat('#,##0', 'en');

  /// `KSh 1,250.00` — the standard money format.
  static String format(num? amount) => '$symbol ${_money.format(amount ?? 0)}';

  /// `KSh 1,250` — for dense contexts where cents are noise.
  static String formatWhole(num? amount) =>
      '$symbol ${_whole.format(amount ?? 0)}';

  /// `KES 1,250.00` — for exports, receipts and anywhere the ISO code is
  /// required instead of a symbol.
  static String formatWithCode(num? amount) =>
      '$code ${_money.format(amount ?? 0)}';

  /// Formats a margin, making the sign explicit so a loss is obvious.
  static String formatSigned(num? amount) {
    final num value = amount ?? 0;
    if (value < 0) return '-${format(value.abs())}';
    return '+${format(value)}';
  }

  /// `33.3%` — percentages are not money, but they always appear next to it
  /// so they live here to keep number formatting in one place.
  static String formatPercentage(num? value, {int decimals = 1}) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// `45` / `1,250` — plain integer quantities for stock columns.
  static String formatQuantity(num? quantity) =>
      _whole.format(quantity ?? 0);
}
