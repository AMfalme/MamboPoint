import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_destination.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/mambo_logo.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../features/cart/presentation/widgets/transaction_panel.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../models/product.dart';
import '../domain/product_list_state.dart';
import '../providers/product_list_provider.dart';
import 'widgets/product_card.dart';
import 'widgets/product_filters.dart';
import 'widgets/product_grid.dart';
import 'widgets/product_table.dart';
import 'widgets/product_view_toggle.dart';

/// The Product Management list screen
/// (spec sections 10, 11, 12, 13 and 26 to 30).
///
/// Responsive: a table on desktop/tablet, a card list on phones. All state
/// comes from [productListProvider], so this widget owns no data logic and the
/// loading, empty and error states can be handled exhaustively.
///
/// Navigation callbacks are optional so the list is usable on its own; the app
/// shell supplies them once the form and details screens exist.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({
    super.key,
    this.onAddProduct,
    this.onViewProduct,
    this.onEditProduct,
    this.onToggleActive,
    this.onCheckout,
    this.onSelectDestination,
    this.showSidebar = true,
    this.showTransaction = true,
  });

  final VoidCallback? onAddProduct;
  final ValueChanged<Product>? onViewProduct;
  final ValueChanged<Product>? onEditProduct;
  final ValueChanged<Product>? onToggleActive;

  /// Raised by PAY NOW. Left null the button renders disabled.
  final VoidCallback? onCheckout;

  /// Sidebar destination selection.
  final ValueChanged<AppDestination>? onSelectDestination;

  /// Both are opt-out so the page can still be embedded in a bare scaffold
  /// (tests, and the eventual per-section routes).
  final bool showSidebar;
  final bool showTransaction;

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  /// Owned here so the "clear search" action can reach the field.
  final TextEditingController _searchController = TextEditingController();

  /// Which presentation the list uses. Purely visual: both modes render the
  /// same products with the same callbacks. Grid is the default because it is
  /// the view a shopkeeper browses, and it is the only mode that works on a
  /// phone.
  ProductViewMode _viewMode = ProductViewMode.grid;

  /// Both panels start expanded and can be minimised independently, so a
  /// cashier working with one hand can reclaim either edge of the screen.
  bool _sidebarCollapsed = false;
  bool _transactionCollapsed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProductListState> listState = ref.watch(
      productListProvider,
    );
    final bool canManage = ref.watch(canManageProductsProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // The panel only exists once something has been added; an empty
            // cart has nothing to show and should not steal grid width.
            final bool hasItems = !ref.watch(cartIsEmptyProvider);
            final bool showTransaction = widget.showTransaction && hasItems;

            // Wide enough to give the panel its own column. Below this it
            // floats over the grid instead, because at that size the grid has
            // already dropped to three columns and cannot spare 340px.
            final bool inline =
                showTransaction &&
                constraints.maxWidth >=
                    AppBreakpoints.transactionInlineMinWidth;

            final Widget row = Row(
              children: <Widget>[
                if (widget.showSidebar) _buildSidebar(constraints.maxWidth),
                Expanded(child: _buildPage(context, listState, canManage)),
                if (inline) _buildTransactionPanel(),
              ],
            );

            if (!showTransaction || inline) return row;

            // Floating mode: the rail still sits in the layout so there is
            // always something to tap, but the expanded panel overlays.
            return Stack(
              children: <Widget>[
                row,
                if (_transactionCollapsed)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildTransactionPanel(),
                  )
                else
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(-4, 0),
                          ),
                        ],
                      ),
                      child: _buildTransactionPanel(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The navigation rail. Collapses to an icon strip by default on narrow
  /// windows so the product grid keeps its columns; an explicit toggle always
  /// overrides that default.
  Widget _buildSidebar(double availableWidth) {
    final bool defaultCollapsed =
        availableWidth < AppBreakpoints.sidebarRailWidth;

    return AppSidebar(
      current: AppDestination.products,
      collapsed: _sidebarCollapsed || defaultCollapsed,
      onToggleCollapsed: () =>
          setState(() => _sidebarCollapsed = !_sidebarCollapsed),
      onSelect: widget.onSelectDestination,
    );
  }

  /// The transaction panel, or the collapsed rail in its place.
  ///
  /// Minimising swaps the whole panel for the rail rather than hiding it, so the
  /// running total stays on screen — the cashier still needs to see what they are
  /// about to charge.
  Widget _buildTransactionPanel() {
    if (_transactionCollapsed) {
      return TransactionRail(
        onExpand: () => setState(() => _transactionCollapsed = false),
      );
    }

    return TransactionPanel(
      onCheckout: widget.onCheckout,
      onToggleCollapsed: () => setState(() => _transactionCollapsed = true),
    );
  }

  /// The page body: header, filters and whichever list presentation applies.
  Widget _buildPage(
    BuildContext context,
    AsyncValue<ProductListState> listState,
    bool canManage,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(productListProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _PageHeader(onAddProduct: widget.onAddProduct),
                  const SizedBox(height: AppSpacing.md),
                  ProductFilters(searchController: _searchController),
                  const SizedBox(height: AppSpacing.md),
                  _buildContent(context, listState, canManage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Resolves the list to exactly one of: skeleton, error, empty or results.
  Widget _buildContent(
    BuildContext context,
    AsyncValue<ProductListState> listState,
    bool canManage,
  ) {
    // A failed load takes precedence: Riverpod reports the initial build as
    // both loading and errored, so checking the error first is what lets the
    // error state ever render (spec section 27).
    if (listState.hasError && !listState.hasValue) {
      final AppException failure = mapError(
        listState.error!,
        fallbackMessage: ErrorMessages.loadProducts,
      );
      return _Surface(
        child: ErrorState(
          message: failure.userMessage,
          onRetry: () => ref.read(productListProvider.notifier).refresh(),
        ),
      );
    }

    // First load, with nothing to show yet: a skeleton keeps the structure
    // visible instead of a blank screen (spec section 26).
    if (listState.isLoading && !listState.hasValue) {
      return const _Surface(child: SkeletonRows(rows: 6));
    }

    final ProductListState? state = listState.value;
    if (state == null) {
      return const _Surface(child: SkeletonRows(rows: 4));
    }

    if (state.isEmpty) return _buildEmptyState(state);

    return _buildResults(context, state, canManage);
  }

  /// Spec section 28: "no products yet" and "no products found" are different
  /// situations and must read differently.
  Widget _buildEmptyState(ProductListState state) {
    if (state.isEmptyBecauseOfFilters) {
      return _Surface(
        child: EmptyState(
          icon: Icons.search_off,
          title: 'No products found',
          message:
              'Try a different product name, SKU or barcode, or clear your '
              'filters to see everything.',
          actionLabel: state.filter.hasQuery ? 'Clear search' : 'Clear filters',
          actionIcon: Icons.filter_alt_off_outlined,
          onAction: () {
            _searchController.clear();
            ref.read(productListProvider.notifier).resetAll();
          },
        ),
      );
    }

    return _Surface(
      child: EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        message:
            'Add your first product to start building your product catalogue.',
        actionLabel: widget.onAddProduct == null ? null : 'Add Product',
        actionIcon: Icons.add,
        onAction: widget.onAddProduct,
      ),
    );
  }

  /// Results: a table on wide layouts, cards on phones (spec section 10).
  Widget _buildResults(
    BuildContext context,
    ProductListState state,
    bool canManage,
  ) {
    final List<Product> products = state.products;
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // The toggle is only offered where the table can actually render.
            // Offering it below [AppBreakpoints.tableMinWidth] would leave the
            // table selected while the grid stayed on screen.
            final bool canSwitch =
                constraints.maxWidth >= AppBreakpoints.tableMinWidth;
            final bool useTable =
                canSwitch && _viewMode == ProductViewMode.table;

            return Row(
              children: <Widget>[
                Expanded(
                  child: _ResultSummary(
                    count: products.length,
                    isSearch: state.filter.hasQuery,
                    isReloading: state.isReloading,
                  ),
                ),
                if (canSwitch) ...<Widget>[
                  const SizedBox(width: AppSpacing.md),
                  ProductViewToggle(
                    mode: useTable
                        ? ProductViewMode.table
                        : ProductViewMode.grid,
                    onChanged: (ProductViewMode mode) =>
                        setState(() => _viewMode = mode),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide =
                constraints.maxWidth >= AppBreakpoints.tableMinWidth;

            if (wide && _viewMode == ProductViewMode.table) {
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ProductTable(
                  products: products,
                  canManage: canManage,
                  onView: widget.onViewProduct,
                  onEdit: widget.onEditProduct,
                  onToggleActive: widget.onToggleActive,
                ),
              );
            }

            // Wide enough for the grid: image-forward tiles. Below the grid's
            // own minimum the stacked card list is more readable than two
            // cramped columns.
            if (constraints.maxWidth >= AppBreakpoints.gridMinWidth) {
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ProductGrid(
                  products: products,
                  canManage: canManage,
                  onView: widget.onViewProduct,
                  onEdit: widget.onEditProduct,
                  onToggleActive: widget.onToggleActive,
                  // Hovering a tile reveals the add control, and the grid is
                  // the only presentation that offers it: the table and card
                  // list are inventory views, not till views.
                  onAddToCart: widget.showTransaction
                      ? ref.read(cartProvider.notifier).add
                      : null,
                ),
              );
            }

            return Column(
              children: <Widget>[
                for (int i = 0; i < products.length; i++) ...<Widget>[
                  ProductCard(
                    product: products[i],
                    canManage: canManage,
                    onView: widget.onViewProduct == null
                        ? null
                        : () => widget.onViewProduct!(products[i]),
                    onEdit: widget.onEditProduct == null
                        ? null
                        : () => widget.onEditProduct!(products[i]),
                    onToggleActive: widget.onToggleActive == null
                        ? null
                        : () => widget.onToggleActive!(products[i]),
                  ),
                  if (i != products.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
        if (state.canLoadMore) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: OutlinedButton.icon(
              onPressed: state.isLoadingMore ? null : () => _loadMore(context),
              icon: state.isLoadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more, size: 18),
              label: Text(state.isLoadingMore ? 'Loading...' : 'Load more'),
            ),
          ),
        ],
        if (state.filter.hasQuery)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Showing the closest matches. Refine your search to narrow the '
              'results.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Future<void> _loadMore(BuildContext context) async {
    try {
      await ref.read(productListProvider.notifier).loadMore();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppSnack.error(context, error.userMessage);
    }
  }
}

/// Compact POS page header.
///
/// Carries the MamboPoint POS lockup above the screen title, then the title and
/// subtitle on the left with Add Product on the right. Stacks on narrow widths
/// so Add stays reachable without consuming vertical space.
class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAddProduct});

  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow =
            constraints.maxWidth < AppBreakpoints.headerStackWidth;

        final Widget title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Products',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Manage your inventory and product information',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        );

        final Widget? addButton = onAddProduct == null
            ? null
            : narrow
            ? SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddProduct,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
            : FilledButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Product'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Align(
                alignment: Alignment.centerLeft,
                child: MamboLogo(markSize: 30),
              ),
              const SizedBox(height: AppSpacing.md),
              title,
              if (addButton != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                addButton,
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Align(
              alignment: Alignment.centerLeft,
              child: MamboLogo(markSize: 36),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: title),
                ?addButton,
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Consistent card surface for the loading, error and empty states.
class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: child,
    ),
  );
}

/// Result count plus a subtle indicator while a new filter is loading.
///
/// Reads `5 products` / `3 matches` with a muted `· Showing all` suffix so the
/// count feels like inventory software rather than a demo label.
class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.count,
    required this.isSearch,
    required this.isReloading,
  });

  final int count;
  final bool isSearch;
  final bool isReloading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Explicit plurals: appending "es" to "product" would render "productes".
    final String noun = switch ((isSearch, count)) {
      (true, 1) => 'match',
      (true, _) => 'matches',
      (false, 1) => 'product',
      (false, _) => 'products',
    };

    return Row(
      children: <Widget>[
        // Flexible, so the count yields rather than overflowing: on a phone the
        // page body is only a few hundred pixels wide once the sidebar and page
        // padding are taken out, which is not enough for both labels at their
        // natural length.
        Flexible(
          child: Text(
            '$count $noun',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
          ),
        ),
        Flexible(
          child: Text(
            isSearch ? ' · filtered results' : ' · showing all',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ),
        if (isReloading) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }
}
