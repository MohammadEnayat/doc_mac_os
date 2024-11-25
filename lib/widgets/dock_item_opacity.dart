import 'package:flutter/material.dart';

/// This widget controls the visibility of the [DockItem].
class DockItemOpacity extends StatelessWidget {
  const DockItemOpacity({
    super.key,
    required this.opacity,
    required this.itemSize,
    required this.child,
  });

  final double opacity;
  final double itemSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: itemSize,
      width: itemSize,
      constraints: BoxConstraints(minWidth: itemSize),
      margin: itemSize == 0
          ? null
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: child,
      ),
    );
  }
}
