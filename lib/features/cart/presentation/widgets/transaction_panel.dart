import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../providers/cart_provider.dart';

/// The open sale, pinned to the right of the product list.
///
/// Mirrors the reference design: a titled header with an info affordance, a
/// Quantity/Price column header, one row per line item showing quantity, name,
/// unit price and line total, then the running total above a single primary
/// PAY NOW action.
///
/// Presentation only. It reads and writes [cartProvider], which is in-memory
/// state; taking payment, decrementing stock and recording the sale belong to
/// the Sales module and are deliberately out of scope here.
class TransactionPanel extends ConsumerWidget {
  const TransactionPanel({
    super.key,
    this.onCheckout,
    this.onToggleCollapsed,
    this.infoTooltip = 'Checkout is not wired up in the review build.',
  });

  /// Raised by PAY NOW. Left null the button is disabled rather than pretending
  /// to take a payment.
  final VoidCallback? onCheckout;

  /// Raised by the minimise control.
  final VoidCallback? onToggleCollapsed;

  final String infoTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CartLine> lines = ref.watch(cartProvider);
    final double total = ref.watch(cartTotalProvider);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color divider = scheme.outlineVariant.withValues(alpha: 0.6);

    return Container(
      width: AppBreakpoints.transactionWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: divider)),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(
              infoTooltip: infoTooltip,
              onToggleCollapsed: onToggleCollapsed,
            ),
            Divider(color: divider),
            const _ColumnHeader(),
            Divider(color: divider),
            Expanded(
              child: lines.isEmpty
                  ? const _EmptyTransaction()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: lines.length,
                      separatorBuilder: (BuildContext _, int _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (BuildContext context, int index) =>
                          _LineTile(line: lines[index]),
                    ),
            ),
            Divider(color: divider),
            _TotalRow(total: total),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: FilledButton.icon(
                onPressed: onCheckout,
                icon: const Icon(Icons.point_of_sale_rounded, size: 20),
                label: const Text('PAY NOW'),
                style: FilledButton.styleFrom(
                  // The mint fill is the loudest element in the panel, which is
                  // correct: it is the one action that ends the sale.
                  backgroundColor: AppColors.brandMint,
                  foregroundColor: AppColors.brandTealDeep,
                  disabledBackgroundColor: AppColors.brandMint.withValues(
                    alpha: 0.45,
                  ),
                  disabledForegroundColor: AppColors.brandTealDeep.withValues(
                    alpha: 0.6,
                  ),
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title row with the info affordance and the minimise control.
class _Header extends StatelessWidget {
  const _Header({required this.infoTooltip, this.onToggleCollapsed});

  final String infoTooltip;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Transaction',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Tooltip(
            message: infoTooltip,
            child: IconButton(
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (onToggleCollapsed != null)
            Tooltip(
              message: 'Minimise transaction',
              child: IconButton(
                onPressed: onToggleCollapsed,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}

/// The "Quantity / Price" column header from the reference layout.
class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text('Quantity', style: style)),
          const SizedBox(width: AppSpacing.sm),
          Text('Price', style: style),
        ],
      ),
    );
  }
}

/// Shown when nothing has been added yet. The panel is normally hidden in this
/// state, so this is the safety net for the first frame and for a cart that has
/// just been emptied.
class _EmptyTransaction extends StatelessWidget {
  const _EmptyTransaction();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.shopping_cart_outlined,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No items yet',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap the + on a product to start a sale.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One cart line: quantity, product name, unit price and line total.
///
/// Quantity is a stepper rather than plain text so the cashier can correct a
/// miscount without leaving the panel. The reference design shows the same
/// numbers without the controls, so this is the one place it deliberately
/// departs in favour of a working till.
class _LineTile extends ConsumerWidget {
  const _LineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final CartNotifier cart = ref.read(cartProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Stepper(
            quantity: line.quantity,
            onIncrement: () => cart.add(line.product),
            onDecrement: () => cart.removeOne(line.product.id),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.format(line.unitPrice)} each',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                CurrencyFormatter.format(line.lineTotal),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => cart.remove(line.product.id),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 24,
                  height: 24,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Remove ${line.product.name}',
                icon: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Plus / count / minus control for a single line.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _StepperButton(
          icon: Icons.add_rounded,
          tooltip: 'Increase quantity',
          onPressed: onIncrement,
        ),
        SizedBox(
          height: 22,
          child: Center(
            child: Text(
              '$quantity',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.remove_rounded,
          tooltip: 'Decrease quantity',
          onPressed: onDecrement,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 16, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Running total, sitting directly above PAY NOW.
class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Text(
            'Total',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            CurrencyFormatter.format(total),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.brandTeal,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The minimised stand-in for [TransactionPanel]: a narrow rail carrying the
/// unit count and the running total.
///
/// The cart is the one panel a cashier must never lose sight of — it is what
/// they are about to charge — so collapsing it never hides it. The rail keeps
/// both numbers on screen and the expand control always visible.
///
/// Presentation only, same as the panel: it reads [cartProvider] through
/// [cartCountProvider] and [cartTotalProvider] and never mutates anything.
class TransactionRail extends ConsumerWidget {
  const TransactionRail({super.key, this.onExpand});

  /// Raised by the expand control. Left null the rail renders read-only, which
  /// is what a bare scaffold wants.
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(cartCountProvider);
    final double total = ref.watch(cartTotalProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      width: AppBreakpoints.transactionRailWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          left: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          children: <Widget>[
            _RailButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Expand transaction',
              onPressed: onExpand,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _VerticalTotal(total: total, onExpand: onExpand),
            ),
            _RailBadge(count: count),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// The expand/minimise control at the head of the rail.
///
/// A plain icon button rather than the sidebar's pill, because the rail is only
/// 60px wide and the label would not fit.
class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;

  /// Null disables the control, which is how a rail with no host looks inert
  /// rather than tappable.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 22),
      ),
    );
  }
}

/// Unit count, stacked under a cart glyph.
///
/// The glyph is paired with the number rather than replacing it: colour and
/// shape alone are not a reliable signal (spec section 31).
class _RailBadge extends StatelessWidget {
  const _RailBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.shopping_cart_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The running total, set vertically so it fits the rail's width.
///
/// Rotated rather than abbreviated: a cashier must read the exact figure
/// payable, so the full amount is shown and only the orientation changes.
///
/// The total doubles as the expand target, which makes the single most
/// important number on screen the one that restores the full panel.
class _VerticalTotal extends StatelessWidget {
  const _VerticalTotal({required this.total, this.onExpand});

  final double total;

  /// Null renders the total as plain text with no tap affordance.
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget label = Text(
      CurrencyFormatter.format(total),
      // One line, however long the amount, because a wrapped vertical number
      // is unreadable.
      maxLines: 1,
      softWrap: false,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.brandTeal,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );

    return RotatedBox(
      // Bottom-to-top: the digits read naturally when the head is tilted right.
      quarterTurns: 3,
      child: Center(
        child: onExpand == null
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: label,
              )
            : Tooltip(
                message: 'Expand transaction',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onExpand,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: label,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
