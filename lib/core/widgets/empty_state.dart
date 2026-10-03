import 'package:flutter/material.dart';

/// An intentional empty state: it explains what is missing and offers the
/// next action (spec section 28).
///
/// Used for both "nothing exists yet" and "nothing matched your search"; the
/// caller supplies the copy so the distinction stays meaningful.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Primary action. Only shown when both this and [onAction] are provided.
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  /// Tighter layout for use inside a card rather than a full page.
  final bool compact;

  bool get _hasAction =>
      actionLabel != null && actionLabel!.isNotEmpty && onAction != null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(compact ? 14 : 18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: compact ? 26 : 32,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: compact ? 14 : 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    (compact
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.titleLarge)
                        ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (_hasAction) ...<Widget>[
                SizedBox(height: compact ? 18 : 24),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon ?? Icons.add),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
