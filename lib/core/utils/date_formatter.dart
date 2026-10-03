import 'package:intl/intl.dart';

/// Consistent date and time display.
///
/// Kept next to [CurrencyFormatter] so all formatting lives in one layer
/// rather than being scattered through widgets.
class DateFormatter {
  const DateFormatter._();

  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy', 'en');
  static final DateFormat _dayMonthYearTime = DateFormat(
    'd MMM yyyy, HH:mm',
    'en',
  );

  /// `4 Oct 2026`
  static String date(DateTime? value) =>
      value == null ? '—' : _dayMonthYear.format(value);

  /// `4 Oct 2026, 14:32`
  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dayMonthYearTime.format(value);

  /// Compact relative label for dense table cells: `Just now`, `12m ago`,
  /// `3h ago`, `5d ago`, falling back to an absolute date after a week.
  ///
  /// Callers should pair this with [dateTime] in a tooltip so the exact time is
  /// always reachable.
  static String relative(DateTime? value) {
    if (value == null) return '—';

    final Duration elapsed = DateTime.now().difference(value);
    if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
    return date(value);
  }
}
