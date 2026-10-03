import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Switches the product list between its grid and table presentations.
///
/// Deliberately not a [SegmentedButton]: the default Material control is heavy
/// for what is a two-way preference, and this reads like the professional POS
/// toolbar the rest of the page uses.
class ProductViewToggle extends StatelessWidget {
  const ProductViewToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ProductViewMode mode;
  final ValueChanged<ProductViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ToggleButton(
            icon: Icons.grid_view_rounded,
            tooltip: 'Grid view',
            selected: mode == ProductViewMode.grid,
            onTap: () => onChanged(ProductViewMode.grid),
          ),
          _ToggleButton(
            icon: Icons.view_list_outlined,
            tooltip: 'Table view',
            selected: mode == ProductViewMode.table,
            onTap: () => onChanged(ProductViewMode.table),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            width: 38,
            height: double.infinity,
            decoration: BoxDecoration(
              // A mint wash reads as "active" without shouting.
              color: selected
                  ? AppColors.brandMint.withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 18,
              color: selected ? AppColors.brandTeal : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
