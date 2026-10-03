import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/preview/preview_data.dart';
import 'core/preview/preview_products_page.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/session_providers.dart';
import 'features/products/providers/category_providers.dart';
import 'features/products/providers/product_list_provider.dart';
import 'firebase_options.dart';
import 'models/category.dart';
import 'models/user_role.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Date symbols for non-en_US locales must be initialized before any
  // DateFormat use, otherwise intl throws LocaleDataException. The local
  // build bundles every locale, so one call covers the whole app.
  await initializeDateFormatting('en', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ProviderScope(
      overrides: [
        // Review mode: show the built Product Management screens backed by
        // an in-memory catalogue, so no signed-in session or Firestore data
        // is needed to review what has been built so far.
        productReaderProvider.overrideWithValue(PreviewProductReader()),
        requireBusinessIdProvider.overrideWithValue(PreviewCatalog.businessId),
        currentUserRoleProvider.overrideWithValue(UserRole.manager),
        categoriesProvider.overrideWith(
          (ref) => Stream<List<Category>>.value(PreviewCatalog.categories),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MamboPoint',
      theme: AppTheme.light(),
      // Temporary review entry point: only the built Product Management
      // module is shown. Auth-gated routing lands with the next phase; the
      // overrides above stand in for the signed-in session.
      home: const PreviewProductsPage(),
    );
  }
}
