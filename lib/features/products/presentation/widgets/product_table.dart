import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/product.dart';
import 'product_status_badge.dart';
import 'product_thumbnail.dart';

/// Professional product table for tablet and desktop widths
/// (spec section 10).
///
/// Compact POS list: one subtle card, tight rows, strong product identity on
/// the left and scannable price/stock/status columns. Row separation comes
/// from hairline dividers, not heavy cell borders.
class ProductTable extends StatelessWidget {
  const ProductTable({
    super.key,
    required this.products,
    this.onView,
    this.onEdit,
    this.onToggleActive,
    this.canManage = false,
    this.busyProductIds = const <String>{},
  });

  final List<Product> products;

  /// Row tap. Also called by the "View" action.
  final ValueChanged<Product>? onView;
  final ValueChanged<Product>? onEdit;
  final ValueChanged<Product>? onToggleActive;

  /// Hides mutating actions for roles that may not perform them
  /// (spec section 23). The security rules enforce this independently.
  final bool canManage;

  /// Products with an in-flight mutation, so their row can show progress.
  final Set<String> busyProductIds;

  bool get _showActions =>
      onView != null || onEdit != null || onToggleActive != null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 880),
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 20,
          headingRowHeight: 40,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 68,
          columns: <DataColumn>[
            const DataColumn(label: Text('Product')),
            const DataColumn(label: Text('SKU / Barcode')),
            const DataColumn(label: Text('Category')),
            const DataColumn(label: Text('Price'), numeric: true),
            const DataColumn(label: Text('Stock'), numeric: true),
            const DataColumn(label: Text('Status')),
            const DataColumn(label: Text('Updated')),
            if (_showActions) const DataColumn(label: Text('')),
          ],
          rows: <DataRow>[
            for (final Product product in products)
              DataRow(
                onSelectChanged: onView == null
                    ? null
                    : (bool? _) => onView!(product),
                cells: <DataCell>[
                  DataCell(_ProductCell(product: product)),
                  DataCell(_SkuCell(product: product)),
                  DataCell(
                    Text(
                      product.categoryLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        CurrencyFormatter.format(product.sellingPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DataCell(_StockCell(product: product)),
                  DataCell(_StatusCell(product: product)),
                  DataCell(
                    Tooltip(
                      message: DateFormatter.dateTime(product.updatedAt),
                      child: Text(
                        DateFormatter.relative(product.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  if (_showActions)
                    DataCell(
                      _RowActions(
                        product: product,
                        canManage: canManage,
                        isBusy: busyProductIds.contains(product.id),
                        onView: onView,
                        onEdit: onEdit,
                        onToggleActive: onToggleActive,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Product name with its thumbnail, plus the category as a muted secondary
/// line. SKU/barcode get their own column so this cell stays scannable.
class _ProductCell extends StatelessWidget {
  const _ProductCell({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 230,
      child: Row(
        children: <Widget>[
          ProductThumbnail(product: product, size: 36, borderRadius: 7),
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
                  product.categoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// SKU primary, barcode muted underneath. Keeps identifier hierarchy
/// SKU > barcode without widening the product column.
class _SkuCell extends StatelessWidget {
  const _SkuCell({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          product.sku,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            height: 1.25,
          ),
        ),
        Text(
          product.hasBarcode ? product.barcode! : '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

/// Quantity in its unit, paired with the derived stock badge.
///
/// Showing both the number and the status keeps the column meaningful without
/// relying on colour (spec section 31).
class _StockCell extends StatelessWidget {
  const _StockCell({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${CurrencyFormatter.formatQuantity(product.stockQuantity)} '
          '${product.unit}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            height: 1.25,
          ),
        ),
        const SizedBox(height: 3),
        StockStatusBadge(status: product.stockStatus, dense: true),
      ],
    );
  }
}

/// Single status column: active/inactive first, then the stock signal.
/// Two dots would be noisy, so inactive rows keep the neutral badge and the
/// stock signal stays on the quantity column.
class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ProductActiveBadge(isActive: product.isActive, dense: true);
  }
}

enum _RowAction { view, edit, toggleActive }

/// Row action menu. Mutating entries are hidden unless the role allows them,
/// and the security rules enforce the same restriction server-side
/// (spec section 23: hiding a button is not a security measure).
class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.product,
    required this.canManage,
    required this.isBusy,
    this.onView,
    this.onEdit,
    this.onToggleActive,
  });

  final Product product;
  final bool canManage;
  final bool isBusy;
  final ValueChanged<Product>? onView;
  final ValueChanged<Product>? onEdit;
  final ValueChanged<Product>? onToggleActive;

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final bool canToggle = canManage && onToggleActive != null;

    return PopupMenuButton<_RowAction>(
      tooltip: 'Product actions',
      icon: const Icon(Icons.more_vert, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onSelected: (_RowAction action) {
        switch (action) {
          case _RowAction.view:
            onView?.call(product);
          case _RowAction.edit:
            onEdit?.call(product);
          case _RowAction.toggleActive:
            onToggleActive?.call(product);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_RowAction>>[
        if (onView != null)
          const PopupMenuItem<_RowAction>(
            value: _RowAction.view,
            child: _MenuRow(icon: Icons.visibility_outlined, label: 'View'),
          ),
        if (canManage && onEdit != null)
          const PopupMenuItem<_RowAction>(
            value: _RowAction.edit,
            child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
          ),
        if (canToggle)
          PopupMenuItem<_RowAction>(
            value: _RowAction.toggleActive,
            child: _MenuRow(
              icon: product.isActive
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
              label: product.isActive ? 'Deactivate' : 'Activate',
            ),
          ),
      ],
    );
  }
}

/// Compact icon + label used inside the action menu.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, size: 18),
      const SizedBox(width: AppSpacing.sm),
      Text(label),
    ],
  );
}
