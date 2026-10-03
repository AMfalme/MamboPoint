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
      children: <Widget>[
        SearchInput(controller: searchController, onChanged: notifier.setQuery),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Below the breakpoint the controls stack, so the filter row stays
            // usable on a phone (spec section 30).
            final bool stacked =
                constraints.maxWidth < AppBreakpoints.filterRowMinWidth;
            final double controlWidth = stacked ? double.infinity : 210;

            final List<Widget> controls = <Widget>[
              _CategoryDropdown(
                categories: categories.value ?? const <Category>[],
                categoryId: filter.categoryId,
                onChanged: notifier.setCategory,
                width: controlWidth,
              ),
              _EnumDropdown<ProductStatusFilter>(
                value: filter.status,
                values: ProductStatusFilter.values,
                labelOf: (ProductStatusFilter value) => value.label,
                label: 'Status',
                onChanged: notifier.setStatus,
                width: controlWidth,
              ),
              _EnumDropdown<ProductStockFilter>(
                value: filter.stock,
                values: ProductStockFilter.values,
                labelOf: (ProductStockFilter value) => value.label,
                label: 'Stock',
                onChanged: notifier.setStock,
                width: controlWidth,
              ),
              _EnumDropdown<ProductSortOrder>(
                value: filter.sort,
                values: ProductSortOrder.values,
                labelOf: (ProductSortOrder value) => value.label,
                label: 'Sort',
                onChanged: notifier.setSort,
                width: controlWidth,
              ),
            ];

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final Widget control in controls)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: control,
                    ),
                ],
              );
            }

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: controls,
            );
          },
        ),
        if (filter.activeFilterCount > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: notifier.clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: Text(
                'Clear ${filter.activeFilterCount} '
                'filter${filter.activeFilterCount == 1 ? '' : 's'}',
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
    child: InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: child,
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
        onChanged: (String? value) => onChanged(
          value == null || value == _allSentinel ? null : value,
        ),
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
