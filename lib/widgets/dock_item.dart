import 'package:flutter/material.dart';

/// Widget representing the single item of the [Dock].
class DockItem extends StatelessWidget {
  const DockItem({
    super.key,
    required this.iconData,
    required this.itemSize,
    required this.yTranslationValue,
  });

  final IconData iconData;
  final double itemSize;
  final double yTranslationValue;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      // transform duration

      constraints: BoxConstraints(minWidth: itemSize),
      alignment: AlignmentDirectional.topCenter,
      curve: TreeSliver.defaultAnimationCurve,
      transform: Matrix4.translationValues(0, yTranslationValue, 0),
      height: itemSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.primaries[iconData.hashCode % Colors.primaries.length],
      ),
      child: Center(child: Icon(iconData, color: Colors.white)),
    );
  }
}
