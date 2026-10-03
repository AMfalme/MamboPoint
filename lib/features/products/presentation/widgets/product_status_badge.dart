import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/product.dart';

/// Active/Inactive state of a product (spec section 9).
///
/// Maps domain state onto the presentational [StatusBadge] so colour choices
/// live in one place instead of being repeated in the table and card widgets.
class ProductActiveBadge extends StatelessWidget {
  const ProductActiveBadge({
    super.key,
    required this.isActive,
    this.dense = false,
  });

  final bool isActive;
  final bool dense;

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: isActive ? 'Active' : 'Inactive',
    foreground: isActive
        ? AppColors.successForeground
        : AppColors.neutralForeground,
    background: isActive
        ? AppColors.successBackground
        : AppColors.neutralBackground,
    icon: isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
    dense: dense,
  );
}

/// Derived stock state of a product (spec section 8).
class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({super.key, required this.status, this.dense = false});

  final StockStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) => switch (status) {
    StockStatus.inStock => StatusBadge(
      label: 'In Stock',
      foreground: AppColors.successForeground,
      background: AppColors.successBackground,
      icon: Icons.inventory_2_outlined,
      dense: dense,
    ),
    StockStatus.lowStock => StatusBadge(
      label: 'Low Stock',
      foreground: AppColors.warningForeground,
      background: AppColors.warningBackground,
      icon: Icons.warning_amber_outlined,
      dense: dense,
    ),
    StockStatus.outOfStock => StatusBadge(
      label: 'Out of Stock',
      foreground: AppColors.dangerForeground,
      background: AppColors.dangerBackground,
      icon: Icons.remove_shopping_cart_outlined,
      dense: dense,
    ),
  };
}
