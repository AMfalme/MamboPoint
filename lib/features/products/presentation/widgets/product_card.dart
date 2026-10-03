import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/product.dart';
import 'product_status_badge.dart';
import 'product_thumbnail.dart';

/// Card representation of a product, used on phone widths.
///
/// Spec section 10 requires the table to become a readable card list on small
/// screens rather than becoming unusable, and spec section 30 requires mobile
/// users to still see stock, prices and status.
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ProductThumbnail(product: product, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.sku}  •  ${product.categoryLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isBusy)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Metric(
                      label: 'Selling price',
                      value: CurrencyFormatter.format(product.sellingPrice),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Stock',
                      value:
                          '${CurrencyFormatter.formatQuantity(product.stockQuantity)} '
                          '${product.unit}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ProductActiveBadge(isActive: product.isActive, dense: true),
                  StockStatusBadge(status: product.stockStatus, dense: true),
                  Text(
                    DateFormatter.relative(product.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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

/// A label/value pair, so prices and stock stay scannable on a phone.
class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
      icon: const Icon(Icons.more_vert),
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
