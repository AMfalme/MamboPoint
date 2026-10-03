// Smoke test for the Product Management entry point.
//
// The module requires Firebase + a signed-in session to load products, so this
// test asserts the app boots into the Products shell (app bar + filters) and
// handles the missing-session state gracefully instead of crashing. Data-path
// coverage lives in product_list_notifier_test.dart and the model/util tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mambopoint/core/utils/error_mapper.dart';
import 'package:mambopoint/features/auth/providers/session_providers.dart';
import 'package:mambopoint/features/products/data/product_reader.dart';
import 'package:mambopoint/features/products/domain/product_filter.dart';
import 'package:mambopoint/features/products/providers/product_list_provider.dart';
import 'package:mambopoint/main.dart';

/// A reader that always fails with \"no session\", mirroring what the app shows
/// when Firebase has no signed-in user.
class _NoSessionReader implements ProductReader {
  @override
  Future<ProductQueryResult> fetchProducts({
    required String businessId,
    required ProductFilter filter,
    Object? cursor,
    int limit = 50,
  }) async {
    throw const AppException(
      userMessage: 'Please sign in to manage your products.',
      code: 'no-session',
    );
  }
}

void main() {
  setUpAll(() async {
    // Mirrors main(): non-en_US date symbols must be initialized before any
    // DateFormat use, otherwise intl throws LocaleDataException.
    await initializeDateFormatting('en', null);
  });

  testWidgets('App boots into the Product Management shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productReaderProvider.overrideWithValue(_NoSessionReader()),
          requireBusinessIdProvider.overrideWithValue('preview-business'),
          currentUserRoleProvider.overrideWithValue(null),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    // The Products app bar is showing (not the old counter demo).
    // While loading, the filter card is still visible; the search input only
    // hides once the list resolves to an error state.
    expect(find.text('Products'), findsOneWidget);

    // No-session state surfaces the mapped message, not a crash.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text(
        'Please sign in to manage your products.',
        findRichText: true,
      ),
      findsWidgets,
    );
  });
}
