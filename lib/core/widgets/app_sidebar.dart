import 'package:flutter/material.dart';

import '../navigation/app_destination.dart';
import '../theme/app_colors.dart';
import 'mambo_logo.dart';

/// The persistent navigation rail that frames the product list.
///
/// Follows the POS reference layout: the brand lockup sits at the top, the
/// destinations run down the left edge, and the active one is filled with the
/// mint accent so the current screen is unmistakable at a glance.
///
/// The rail can be minimised to a 72px strip of icons. It is a [Row] child
/// rather than a [Drawer] because a POS runs on a tablet all day — the shell
/// must never be able to cover the products it is selling.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    this.current = AppDestination.products,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.onSelect,
  });

  /// The destination currently on screen.
  final AppDestination current;

  /// Renders as an icon-only rail when true.
  final bool collapsed;

  /// Called when the minimise/expand control is pressed.
  final VoidCallback? onToggleCollapsed;

  /// Called when a destination is chosen. Only the current destination is
  /// enabled, because the other modules are not built yet.
  final ValueChanged<AppDestination>? onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: collapsed
          ? AppBreakpoints.sidebarRailWidthCollapsed
          : AppBreakpoints.sidebarWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Brand(collapsed: collapsed),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          const SizedBox(height: AppSpacing.sm),
          // Expanded so a longer list of destinations would scroll rather than
          // overflow if more are added later.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              children: <Widget>[
                for (final AppDestination destination in AppDestination.values)
                  _DestinationTile(
                    destination: destination,
                    isCurrent: destination == current,
                    collapsed: collapsed,
                    onTap: onSelect == null
                        ? null
                        : () => onSelect!(destination),
                  ),
              ],
            ),
          ),
          if (onToggleCollapsed != null)
            _CollapseControl(
              collapsed: collapsed,
              onPressed: onToggleCollapsed!,
            ),
        ],
      ),
    );
  }
}

/// Brand lockup at the top of the rail. Centred and always shown — collapsing
/// the sidebar must not hide which application this is.
class _Brand extends StatelessWidget {
  const _Brand({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: MamboLogo(markSize: 34, showWordmark: false)),
      );
    }

    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Center(child: MamboLogo(markSize: 40)),
    );
  }
}

/// One destination row.
///
/// The active row carries the mint fill from the reference design; every other
/// row stays flat until hovered, so the accent only ever means "you are here".
class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.destination,
    required this.isCurrent,
    required this.collapsed,
    this.onTap,
  });

  final AppDestination destination;
  final bool isCurrent;
  final bool collapsed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    // The current screen is not a link: it is already displayed.
    final bool enabled = !isCurrent && onTap != null;

    final Color background = isCurrent
        ? AppColors.brandMint.withValues(alpha: 0.28)
        : Colors.transparent;
    final Color foreground = isCurrent
        ? AppColors.brandTeal
        : enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurfaceVariant.withValues(alpha: 0.55);

    final Widget label = Text(
      destination.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
        color: foreground,
        height: 1.2,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Tooltip(
        // Only meaningful once the label itself is hidden.
        message: collapsed ? destination.label : '',
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: <Widget>[
                  Icon(destination.icon, size: 20, color: foreground),
                  if (!collapsed) ...<Widget>[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: label),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimise / expand control, pinned to the bottom of the rail.
class _CollapseControl extends StatelessWidget {
  const _CollapseControl({required this.collapsed, required this.onPressed});

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Tooltip(
        message: collapsed ? 'Expand menu' : 'Minimise menu',
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    collapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  if (!collapsed) ...<Widget>[
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Minimise',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
