import 'package:flutter/material.dart';

/// A compact pill that communicates a state.
///
/// Presentational only — callers supply the colours, which keeps this reusable
/// outside the products feature. Spec section 31 forbids communicating status
/// by colour alone, so [label] is always rendered and the optional [icon] adds
/// a second, redundant signal.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  /// Compact variant for dense table cells.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 7 : 9,
          vertical: dense ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: foreground.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: dense ? 11 : 13, color: foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: dense ? 11 : 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
