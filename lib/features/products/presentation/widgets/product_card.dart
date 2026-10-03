import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/product.dart';
import 'product_status_badge.dart';
import 'product_thumbnail.dart';

/// Card representation of a product, used on phone widths.
///
/// Compact POS card: 44px identity row, scannable price/stock row, muted
/// badges + updated stamp. Tapping anywhere views the product.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onView,
    this.onEdit,
    this.onToggleActive,
    this.canManage = false,
    this.isBusy = false,
  });

  final Product product;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final bool canManage;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isBusy ? null : onView,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ProductThumbnail(product: product, size: 40),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        Text(
                          product.hasBarcode
                              ? '${product.sku}  •  ${product.barcode}'
                              : product.sku,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                        Text(
                          product.categoryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        CurrencyFormatter.format(product.sellingPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.formatQuantity(product.stockQuantity)} '
                        '${product.unit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  if (isBusy)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (onEdit != null || onToggleActive != null)
                    _CardActions(
                      product: product,
                      canManage: canManage,
                      onEdit: onEdit,
                      onToggleActive: onToggleActive,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ProductActiveBadge(isActive: product.isActive, dense: true),
                  StockStatusBadge(status: product.stockStatus, dense: true),
                  Text(
                    'Updated ${DateFormatter.relative(product.updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overflow menu for the card. Mirrors the table actions so behaviour is
/// identical on every screen size.
class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.product,
    required this.canManage,
    this.onEdit,
    this.onToggleActive,
  });

  final Product product;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final bool canToggle = canManage && onToggleActive != null;

    return PopupMenuButton<String>(
      tooltip: 'Product actions',
      icon: const Icon(Icons.more_vert, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onSelected: (String action) {
        switch (action) {
          case 'edit':
            onEdit?.call();
          case 'toggle':
            onToggleActive?.call();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (canManage && onEdit != null)
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: <Widget>[
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: AppSpacing.sm),
                Text('Edit'),
              ],
            ),
          ),
        if (canToggle)
          PopupMenuItem<String>(
            value: 'toggle',
            child: Row(
              children: <Widget>[
                Icon(
                  product.isActive
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(product.isActive ? 'Deactivate' : 'Activate'),
              ],
            ),
          ),
      ],
    );
  }
}
