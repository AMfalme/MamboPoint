import 'package:flutter/material.dart';

import '../../../../models/product.dart';

/// Product image with a graceful fallback.
///
/// Spec section 20 requires a default placeholder when an image is missing and
/// a graceful failure when one cannot load, so this widget never shows a
/// broken image icon.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    required this.product,
    this.size = 40,
    this.borderRadius = 8,
  });

  final Product product;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final String url = (product.imageUrl ?? '').trim();

    if (url.isEmpty) return _placeholder(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(context),
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? progress) =>
            progress == null ? child : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(
        // A grocery-friendly glyph: most MamboPoint catalogues are produce.
        Icons.shopping_basket_outlined,
        size: size * 0.5,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
