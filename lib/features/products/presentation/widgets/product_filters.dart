import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_input.dart';
import '../../../../models/category.dart';
import '../../domain/product_filter.dart';
import '../../providers/category_providers.dart';
import '../../providers/product_list_provider.dart';

/// Search box plus category, status, stock and sort controls
/// (spec sections 11, 12 and 13).
///
/// Purely a controller of [ProductListNotifier] — it holds no filter state of
/// its own, so the list and the controls can never disagree.
///
/// Compact POS toolbar: a dominant search field with a wrapping row of small
/// dropdown controls underneath. No large surrounding card — the page owns
/// spacing, this widget only owns the controls.
class ProductFilters extends ConsumerWidget {
  const ProductFilters({super.key, required this.searchController});

  /// Owned by the page so the empty state can clear the search box too.
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProductFilter filter = ref.watch(productFilterProvider);
    final ProductListNotifier notifier = ref.read(productListProvider.notifier);
    final AsyncValue<List<Category>> categories = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SearchInput(
            controller: searchController,
            onChanged: notifier.setQuery,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Wide toolbar: search-aligned filter row. Narrow: horizontally
            // scrollable filter chips-row so nothing stacks into a tall wall.
            final bool compact =
                constraints.maxWidth < AppBreakpoints.filterRowMinWidth;

            final List<Widget> controls = <Widget>[
              _CategoryDropdown(
                categories: categories.value ?? const <Category>[],
                categoryId: filter.categoryId,
                onChanged: notifier.setCategory,
                width: compact ? 160 : 168,
              ),
              _EnumDropdown<ProductStatusFilter>(
                value: filter.status,
                values: ProductStatusFilter.values,
                labelOf: (ProductStatusFilter value) => value.label,
                label: 'Status',
                onChanged: notifier.setStatus,
                width: compact ? 132 : 140,
              ),
              _EnumDropdown<ProductStockFilter>(
                value: filter.stock,
                values: ProductStockFilter.values,
                labelOf: (ProductStockFilter value) => value.label,
                label: 'Stock',
                onChanged: notifier.setStock,
                width: compact ? 132 : 140,
              ),
              _EnumDropdown<ProductSortOrder>(
                value: filter.sort,
                values: ProductSortOrder.values,
                labelOf: (ProductSortOrder value) => value.label,
                label: 'Sort',
                onChanged: notifier.setSort,
                width: compact ? 176 : 200,
              ),
            ];

            if (compact) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < controls.length; i++) ...<Widget>[
                      controls[i],
                      if (i != controls.length - 1)
                        const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
              );
            }

            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: controls,
            );
          },
        ),
        if (filter.activeFilterCount > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              // Clears refinements only and keeps the chosen sort order, via
              // ProductFilter.cleared(). Search text is separate state owned
              // by the page and is cleared from its own control/empty state.
              onPressed: notifier.clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
              label: Text(
                'Clear ${filter.activeFilterCount} '
                'filter${filter.activeFilterCount == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shared shell so every filter control has identical label treatment.
///
/// A plain [DropdownButton] inside an [InputDecorator] is used rather than
/// `DropdownButtonFormField` because the controls are fully controlled by the
/// notifier — the form-field variant only honours `initialValue` on first
/// build and would drift out of sync with the applied filter.
class _FilterShell extends StatelessWidget {
  const _FilterShell({
    required this.label,
    required this.width,
    required this.child,
  });

  final String label;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    // Compact height keeps the toolbar scannable; label is shrunk so the
    // value text dominates.
    height: 44,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.labelSmall
            ?.copyWith(fontSize: 11),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w500),
        child: child,
      ),
    ),
  );
}

/// Category selector.
///
/// Uses an empty string as the "all categories" sentinel so the dropdown value
/// type stays non-nullable, which is what [DropdownButton] requires.
class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.categoryId,
    required this.onChanged,
    required this.width,
  });

  final List<Category> categories;
  final String? categoryId;
  final ValueChanged<String?> onChanged;
  final double width;

  static const String _allSentinel = '';

  @override
  Widget build(BuildContext context) => _FilterShell(
    label: 'Category',
    width: width,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: categoryId ?? _allSentinel,
        isExpanded: true,
        isDense: true,
        items: <DropdownMenuItem<String>>[
          const DropdownMenuItem<String>(
            value: _allSentinel,
            child: Text('All categories', overflow: TextOverflow.ellipsis),
          ),
          for (final Category category in categories)
            DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (String? value) =>
            onChanged(value == null || value == _allSentinel ? null : value),
      ),
    ),
  );
}

/// Generic selector for the status, stock and sort enums.
class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.value,
    required this.values,
    required this.labelOf,
    required this.label,
    required this.onChanged,
    required this.width,
  });

  final T value;
  final List<T> values;
  final String Function(T value) labelOf;
  final String label;
  final ValueChanged<T> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) => _FilterShell(
    label: label,
    width: width,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        isDense: true,
        items: <DropdownMenuItem<T>>[
          for (final T item in values)
            DropdownMenuItem<T>(
              value: item,
              child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (T? next) {
          if (next != null) onChanged(next);
        },
      ),
    ),
  );
}
