import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../models/product.dart';
import '../domain/product_list_state.dart';
import '../providers/product_list_provider.dart';
import 'widgets/product_card.dart';
import 'widgets/product_filters.dart';
import 'widgets/product_table.dart';

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
  });

  final VoidCallback? onAddProduct;
  final ValueChanged<Product>? onViewProduct;
  final ValueChanged<Product>? onEditProduct;
  final ValueChanged<Product>? onToggleActive;

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  /// Owned here so the "clear search" action can reach the field.
  final TextEditingController _searchController = TextEditingController();

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
        child: RefreshIndicator(
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
        ),
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
        _ResultSummary(
          count: products.length,
          isSearch: state.filter.hasQuery,
          isReloading: state.isReloading,
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth >= AppBreakpoints.tableMinWidth) {
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
              onPressed: state.isLoadingMore
                  ? null
                  : () => _loadMore(context),
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

/// Compact POS page header: strong title + muted subtitle on the left,
/// prominent but not oversized Add action on the right. Stacks on narrow
/// widths so Add stays reachable without consuming vertical space.
class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAddProduct});

  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 560;

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

        if (onAddProduct == null) return title;

        final Widget addButton = narrow
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
            children: <Widget>[title, const SizedBox(height: AppSpacing.sm), addButton],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[Expanded(child: title), addButton],
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
    final String noun = isSearch ? 'match' : 'product';

    return Row(
      children: <Widget>[
        Text(
          '$count $noun${count == 1 ? '' : 'es'}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        Text(
          isSearch ? ' · filtered results' : ' · showing all',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.2,
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

