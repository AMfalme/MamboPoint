import 'package:flutter/material.dart';

/// A soft pulsing block used to build skeleton loaders.
///
/// Skeletons keep the page structure visible while Firebase responds, which
/// spec section 26 requires instead of a blank screen.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.surfaceContainerHighest;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// A stack of skeleton rows, used where a list or table is loading.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key, this.rows = 6, this.rowHeight = 52});

  final int rows;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < rows; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                const SkeletonBox(width: 40, height: 40, borderRadius: 8),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: SkeletonBox(height: rowHeight * 0.3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SkeletonBox(height: rowHeight * 0.3),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  flex: 1,
                  child: SkeletonBox(height: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
