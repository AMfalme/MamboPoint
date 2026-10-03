import 'package:flutter/material.dart';

import '../../../../models/product.dart';

/// Fills its parent with the product photo, or a neutral placeholder.
///
/// The grid needs edge-to-edge imagery, which a fixed-size [ProductThumbnail]
/// cannot provide, so both share one placeholder and a catalogue with missing
/// photos still looks deliberate.
class ProductImageFill extends StatelessWidget {
  const ProductImageFill({
    super.key,
    required this.product,
    this.fit = BoxFit.cover,
  });

  final Product product;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final String url = (product.imageUrl ?? '').trim();

    if (url.isEmpty) return ProductThumbnail.placeholder(context);

    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => ProductThumbnail.placeholder(context),
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? progress,
      ) => progress == null ? child : ProductThumbnail.placeholder(context),
    );
  }
}

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

    if (url.isEmpty) return placeholder(context, size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(context, size),
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
        ) => progress == null ? child : placeholder(context, size),
      ),
    );
  }

  /// A neutral tile used when there is no usable photo.
  ///
  /// Exposed so the grid can reuse the exact same look at any size.
  static Widget placeholder(BuildContext context, [double? size]) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double extent = size ?? 40;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        // A grocery-friendly glyph: most MamboPoint catalogues are produce.
        Icons.shopping_basket_outlined,
        size: extent * 0.48,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
      ),
    );
  }
}
