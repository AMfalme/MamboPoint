import 'package:flutter/material.dart';

import '../widgets/app_snack.dart';
import '../../models/product.dart';
import '../../features/products/presentation/products_page.dart';

/// Review entry point around [ProductsPage].
///
/// Supplies the navigation callbacks the list screen leaves optional, so the
/// preview exercises the full shell (including the "Add Product" action).
/// Real navigation lands with the form/details phases; until then each action
/// explains itself with a toast so nothing looks dead.
class PreviewProductsPage extends StatelessWidget {
  const PreviewProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductsPage(
      onAddProduct: () => AppSnack.info(
        context,
        'Preview: the product form lands in the next phase.',
      ),
      onViewProduct: (Product product) => AppSnack.info(
        context,
        'Preview: details for "${product.name}" land in the next phase.',
      ),
      onEditProduct: (Product product) => AppSnack.info(
        context,
        'Preview: editing "${product.name}" lands in the next phase.',
      ),
      onToggleActive: (Product product) => AppSnack.info(
        context,
        'Preview: status changes are disabled in the review build.',
      ),
    );
  }
}
