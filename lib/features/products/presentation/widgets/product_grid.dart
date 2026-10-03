import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../models/product.dart';
import 'product_status_badge.dart';
import 'product_thumbnail.dart';

/// Image-forward product grid for tablet and desktop widths.
///
/// The merchandising view a shopkeeper scans at the till: the photo carries the
/// tile, with the name and selling price on a scrim so they stay legible over any
/// image. Everything the table shows in columns that matter (price, stock,
/// status) is still present, just layered rather than aligned.
///
/// Presentation only — it consumes the same [products] list as the table and
/// raises the same callbacks, so switching views changes nothing but layout.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    this.onView,
    this.onEdit,
    this.onToggleActive,
    this.onAddToCart,
    this.canManage = false,
    this.busyProductIds = const <String>{},
    this.canSell = true,
  });

  final List<Product> products;

  /// Tile tap. Also called by the "View details" action.
  final ValueChanged<Product>? onView;
  final ValueChanged<Product>? onEdit;
  final ValueChanged<Product>? onToggleActive;

  /// Raised by the tile's add-to-cart control. Null hides the control, which is
  /// how a read-only reviewer gets a merchandising grid with no till actions.
  final ValueChanged<Product>? onAddToCart;

  /// Hides mutating actions for roles that may not perform them (spec 23).
  final bool canManage;
  final Set<String> busyProductIds;

  /// Whether this user may add items to a sale. Inactive products and
  /// out-of-stock lines are excluded regardless.
  final bool canSell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Column count follows the available width, so a wide desktop fills the
        // space and a tablet drops to three without hard breakpoints.
        final int columns = _columnsFor(constraints.maxWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            // Taller than wide: the photo needs room and the scrim adds a third.
            childAspectRatio: 0.78,
          ),
          itemCount: products.length,
          itemBuilder: (BuildContext context, int index) {
            final Product product = products[index];
            return ProductGridTile(
              product: product,
              canManage: canManage,
              isBusy: busyProductIds.contains(product.id),
              onView: onView == null ? null : () => onView!(product),
              onEdit: onEdit == null ? null : () => onEdit!(product),
              onToggleActive: onToggleActive == null
                  ? null
                  : () => onToggleActive!(product),
              onAddToCart: onAddToCart == null
                  ? null
                  : () => onAddToCart!(product),
              canSell: canSell,
            );
          },
        );
      },
    );
  }

  /// Picks a column count that keeps every tile in a readable 200-230px band.
  ///
  /// The page only reaches this with at least [AppBreakpoints.gridMinWidth] of
  /// space, so the lowest branch is two comfortable columns rather than one.
  static int _columnsFor(double width) {
    if (width >= 1500) return 6;
    if (width >= 1200) return 5;
    if (width >= 950) return 4;
    if (width >= 700) return 3;
    return 2;
  }
}

/// A single product tile: photo, scrim with name and price, stock signal, and
/// the overflow menu.
class ProductGridTile extends StatefulWidget {
  const ProductGridTile({
    super.key,
    required this.product,
    this.onView,
    this.onEdit,
    this.onToggleActive,
    this.onAddToCart,
    this.canManage = false,
    this.isBusy = false,
    this.canSell = true,
  });

  final Product product;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  /// Adds this product to the open transaction. Null hides the add control.
  final VoidCallback? onAddToCart;

  final bool canManage;
  final bool isBusy;

  /// Gates the add control for roles that may not sell.
  final bool canSell;

  @override
  State<ProductGridTile> createState() => _ProductGridTileState();
}

class _ProductGridTileState extends State<ProductGridTile> {
  bool _hovered = false;

  /// A product can only go in the basket while it is active and in stock, so
  /// the control is hidden rather than shown disabled: a dimmed button on every
  /// sold-out tile reads as clutter.
  bool get _canAddToCart {
    if (widget.onAddToCart == null || !widget.canSell) return false;
    if (!widget.product.isActive) return false;
    return widget.product.stockStatus != StockStatus.outOfStock;
  }

  /// On a touch device there is no hover, so the control stays on. A pointer
  /// device reveals it on hover to keep the resting grid clean.
  bool get _showAddControl => _canAddToCart && (_hovered || _isTouchDevice);

  bool get _isTouchDevice => switch (Theme.of(context).platform) {
    TargetPlatform.iOS || TargetPlatform.android => true,
    _ => false,
  };

  bool get _showActions =>
      widget.onView != null ||
      widget.onEdit != null ||
      widget.onToggleActive != null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Product product = widget.product;

    return MouseRegion(
      // Cursor: pointer only over the add control itself, so the tile keeps the
      // affordance of a plain link everywhere else.
      cursor: _showAddControl
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.isBusy ? null : widget.onView,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Photo, or the shared neutral placeholder.
                  Positioned.fill(child: ProductImageFill(product: product)),

                  // Scrim: keeps white text readable over any photo without
                  // dimming the whole tile the way a flat overlay would.
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: <Color>[
                            Color(0xCC000000),
                            Color(0x40000000),
                            Color(0x00000000),
                          ],
                          stops: <double>[0, 0.45, 0.75],
                        ),
                      ),
                    ),
                  ),

                  // Stock state sits top-left, away from the menu.
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: _ScrimBadge(
                      child: StockStatusBadge(
                        status: product.stockStatus,
                        dense: true,
                      ),
                    ),
                  ),

                  if (widget.isBusy)
                    const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  if (_showActions)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: _GridActions(
                        product: product,
                        canManage: widget.canManage,
                        onView: widget.onView,
                        onEdit: widget.onEdit,
                        onToggleActive: widget.onToggleActive,
                      ),
                    ),

                  // Identity and price on the scrim.
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            shadows: <Shadow>[
                              // Guarantees contrast over bright photos.
                              Shadow(blurRadius: 6, color: Color(0x99000000)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.sku,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Row(
                          children: <Widget>[
                            // Price is the number a cashier looks for, so it leads.
                            Flexible(
                              child: Text(
                                CurrencyFormatter.format(product.sellingPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.brandMint,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  fontFeatures: <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                '${CurrencyFormatter.formatQuantity(product.stockQuantity)} '
                                '${product.unit}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xCCFFFFFF),
                                  fontSize: 12,
                                  height: 1.2,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // The add-to-cart control sits outside the InkWell so tapping it
          // adds the product instead of opening its details.
          if (_showAddControl)
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: _AddToCartButton(
                product: product,
                onPressed: widget.onAddToCart!,
              ),
            ),
        ],
      ),
    );
  }
}

/// The circular mint "+" revealed on hover.
///
/// Positioned bottom-right, over the price block: the top corners are already
/// taken by the stock badge and the overflow menu, and the centre of the photo
/// is the part a shopkeeper is actually looking at.
class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.product, required this.onPressed});

  final Product product;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add ${product.name} to transaction',
      child: Material(
        color: AppColors.brandMint,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.add_rounded,
              size: 26,
              color: AppColors.brandTealDeep,
            ),
          ),
        ),
      ),
    );
  }
}

/// Gives a status badge a readable backdrop over a photo without hiding it.
class _ScrimBadge extends StatelessWidget {
  const _ScrimBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(999),
    ),
    child: child,
  );
}

enum _TileAction { view, edit, toggleActive }

/// Tile overflow menu. Mirrors the table and card menus exactly, including the
/// permission rules, so behaviour never depends on the chosen view.
class _GridActions extends StatelessWidget {
  const _GridActions({
    required this.product,
    required this.canManage,
    this.onView,
    this.onEdit,
    this.onToggleActive,
  });

  final Product product;
  final bool canManage;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final bool canToggle = canManage && onToggleActive != null;

    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(999),
      child: PopupMenuButton<_TileAction>(
        tooltip: 'Product actions',
        icon: const Icon(Icons.more_vert, size: 18, color: Colors.white),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        onSelected: (_TileAction action) {
          switch (action) {
            case _TileAction.view:
              onView?.call();
            case _TileAction.edit:
              onEdit?.call();
            case _TileAction.toggleActive:
              onToggleActive?.call();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_TileAction>>[
          if (onView != null)
            const PopupMenuItem<_TileAction>(
              value: _TileAction.view,
              child: _MenuRow(
                icon: Icons.visibility_outlined,
                label: 'View details',
              ),
            ),
          if (canManage && onEdit != null)
            const PopupMenuItem<_TileAction>(
              value: _TileAction.edit,
              child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
            ),
          if (canToggle)
            PopupMenuItem<_TileAction>(
              value: _TileAction.toggleActive,
              child: _MenuRow(
                icon: product.isActive
                    ? Icons.block_outlined
                    : Icons.check_circle_outline,
                label: product.isActive ? 'Deactivate' : 'Activate',
              ),
            ),
        ],
      ),
    );
  }
}

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
