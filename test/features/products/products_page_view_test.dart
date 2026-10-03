// Presentation tests for the Products list.
//
// The redesign added two presentations (grid and table) behind a toggle, so
// these tests assert the view actually swaps, that the products survive the
// swap, and that neither presentation overflows at the widths a shop might use.
// Data-path coverage lives in product_list_notifier_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mambopoint/core/preview/preview_data.dart';
import 'package:mambopoint/core/theme/app_theme.dart';
import 'package:mambopoint/features/auth/providers/session_providers.dart';
import 'package:mambopoint/features/products/presentation/products_page.dart';
import 'package:mambopoint/features/products/providers/category_providers.dart';
import 'package:mambopoint/features/products/providers/product_list_provider.dart';
import 'package:mambopoint/models/category.dart';
import 'package:mambopoint/models/user_role.dart';

/// Pumps the Products page at a fixed logical size and waits for the list.
Future<void> pumpProducts(
  WidgetTester tester, {
  Size size = const Size(1400, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productReaderProvider.overrideWithValue(PreviewProductReader()),
        requireBusinessIdProvider.overrideWithValue(PreviewCatalog.businessId),
        currentUserRoleProvider.overrideWithValue(UserRole.manager),
        categoriesProvider.overrideWith(
          (ref) => Stream<List<Category>>.value(PreviewCatalog.categories),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const ProductsPage()),
    ),
  );

  // The preview reader waits 150ms before returning.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  testWidgets('shows the grid by default and can switch to the table', (
    WidgetTester tester,
  ) async {
    await pumpProducts(tester);

    // Both toggle buttons are offered on a wide screen.
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    expect(find.byIcon(Icons.view_list_outlined), findsOneWidget);
    expect(find.text('SKU / Barcode'), findsNothing);

    await tester.tap(find.byIcon(Icons.view_list_outlined));
    await tester.pumpAndSettle();

    expect(find.text('SKU / Barcode'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
  });

  testWidgets('the same products render in both views', (
    WidgetTester tester,
  ) async {
    await pumpProducts(tester);

    final String firstProduct = PreviewCatalog.products.first.name;
    expect(find.text(firstProduct), findsWidgets);

    await tester.tap(find.byIcon(Icons.view_list_outlined));
    await tester.pumpAndSettle();

    // The catalogue is identical after switching; only the layout changed.
    expect(find.text(firstProduct), findsWidgets);
  });

  testWidgets('the brand lockup is rendered', (WidgetTester tester) async {
    await pumpProducts(tester);

    expect(find.text('MamboPoint'), findsOneWidget);
    expect(find.text('POS'), findsOneWidget);
  });

  testWidgets('no overflow on a narrow phone', (WidgetTester tester) async {
    // Below the grid breakpoint the stacked card list is used, and the toggle
    // is hidden because a table cannot fit.
    await pumpProducts(tester, size: const Size(400, 900));

    expect(find.byIcon(Icons.view_list_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow on a wide desktop', (WidgetTester tester) async {
    await pumpProducts(tester, size: const Size(1600, 1200));

    expect(tester.takeException(), isNull);
  });
}