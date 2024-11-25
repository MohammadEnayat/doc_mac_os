import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final _iconItemsList = const [
    Icons.person,
    Icons.message,
    Icons.call,
    Icons.camera,
    Icons.photo,
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Dock(
            items: _iconItemsList,
            builder: (iconData, itemSize) => DockItem(
              iconData: iconData,
              itemSize: itemSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T, double) builder;

  /// Global key to track the correct [RenderBox].
  final GlobalKey _dockKey = GlobalKey();

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// The item currently being dragged.
  T? _draggingItem;

  /// Check whether the item is dropped outside the [Dock].
  bool _isDroppedOutside = false;

  /// The index of the hovered item.
  int? _hoveredIndex;

  /// Default item size when not hovered.
  double baseItemSize = 48;

  /// Item size when hovered.
  double hoverItemSize = 60;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      key: widget._dockKey,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black12,
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            // Dynamic scale factor
            final scaleFactor =
                _hoveredIndex != null ? _getMagnificationFactor(index) : 1.0;

            // Check if the item is being dragged.
            final isDragging = _draggingItem == item;

            // Check if the item is being hovered.
            final isHovering = _hoveredIndex == index;

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: ((event) {
                setState(() {
                  _hoveredIndex = index;
                });
              }),
              onExit: (event) {
                setState(() {
                  _hoveredIndex = null;
                });
              },
              child: Draggable<T>(
                data: item,
                feedback: widget.builder(item, baseItemSize * scaleFactor),
                childWhenDragging: _isDroppedOutside
                    ? const SizedBox.shrink() // Shrink if dragged outside
                    : DockItemOpacity(
                        opacity: isHovering || isDragging ? 0 : 1,
                        itemSize: baseItemSize,
                        itemIndex: index,
                        hoveredIndex: _hoveredIndex,
                        child: widget.builder(item, baseItemSize * scaleFactor),
                      ),
                onDragStarted: () => setState(() {
                  _draggingItem = item;
                  _hoveredIndex = index;
                }),
                onDragUpdate: (details) {
                  //Global used to find the RenderBox of the Dock container.
                  final RenderBox dockBox = widget._dockKey.currentContext
                      ?.findRenderObject() as RenderBox;

                  // The global bounds of the dock.
                  final Offset dockTopLeft = dockBox.localToGlobal(Offset.zero);
                  final Size dockSize = dockBox.size;

                  // The current global position of the dragged item.
                  final Offset dragPosition = details.globalPosition;

                  // Check if the drag position is outside the dock's bounds.
                  final bool isOutside = dragPosition.dx < dockTopLeft.dx ||
                      dragPosition.dx > dockTopLeft.dx + dockSize.width ||
                      dragPosition.dy < dockTopLeft.dy ||
                      dragPosition.dy > dockTopLeft.dy + dockSize.height;

                  setState(() {
                    _isDroppedOutside = isOutside;
                  });
                },
                onDragEnd: (_) {
                  setState(() {
                    _draggingItem = null;
                    _hoveredIndex = null;
                    _isDroppedOutside = false;
                  });
                },
                child: DragTarget<T>(
                  onMove: (details) {
                    final RenderBox renderBox = widget._dockKey.currentContext
                        ?.findRenderObject() as RenderBox;

                    // The local position of the dragged item.
                    final localPosition =
                        renderBox.globalToLocal(details.offset);

                    // The position of each item within the container.
                    final double itemWidth =
                        (renderBox.size.width / _items.length) - 10;

                    // Get the new index for item placement.
                    final newIndex = (localPosition.dx / itemWidth)
                        .floor()
                        .clamp(-1, _items.length - 1);

                    if (!_isDroppedOutside &&
                        newIndex != _hoveredIndex &&
                        newIndex != -1) {
                      setState(() {
                        _reorderItem(
                          item: _draggingItem ?? details.data,
                          newIndex: newIndex,
                          itemsList: _items,
                        );
                        _hoveredIndex = newIndex;
                      });
                    }
                  },
                  onLeave: (_) {
                    setState(() {
                      _isDroppedOutside = false;
                    });
                  },
                  builder: (_, __, ___) {
                    final isDraggedToNewIndex = (_draggingItem != null &&
                        _hoveredIndex != null &&
                        _items[_hoveredIndex!] == _draggingItem);

                    return DockItemOpacity(
                      opacity:
                          ((isHovering || isDragging) && isDraggedToNewIndex)
                              ? 0
                              : 1,
                      itemIndex: index,
                      itemSize: baseItemSize,
                      hoveredIndex: _hoveredIndex,
                      child: widget.builder(item, baseItemSize * scaleFactor),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Reorders the item in the list by moving it to the specified index.
  void _reorderItem({
    required T item,
    required int newIndex,
    required List<T?> itemsList,
  }) {
    final oldIndex = itemsList.indexOf(item);

    if (oldIndex != -1 && newIndex != oldIndex) {
      itemsList.removeAt(oldIndex);
      itemsList.insert(newIndex, item);
    }
  }

  /// Calculates the magnification factor based on proximity to the hovered index.
  double _getMagnificationFactor(int index) {
    if (_hoveredIndex == null) return 1.0;

    const double proximityScaling = 0.4;
    final int distance = (index - (_hoveredIndex ?? 0)).abs();

    // Only apply magnification for the dragged item and its immediate neighbors.
    return lerpDouble(
          1.0,
          hoverItemSize / baseItemSize,
          max(0, 1 - distance * proximityScaling),
        ) ??
        1.0;
  }
}

/// Widget representing the single item of the [Dock].
class DockItem extends StatelessWidget {
  const DockItem({
    super.key,
    required this.iconData,
    required this.itemSize,
  });

  final IconData iconData;
  final double itemSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      constraints: BoxConstraints(minWidth: itemSize),
      alignment: AlignmentDirectional.topCenter,
      curve: Curves.linearToEaseOut,
      height: itemSize,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.primaries[iconData.hashCode % Colors.primaries.length],
      ),
      child: Center(child: Icon(iconData, color: Colors.white)),
    );
  }
}

/// This widget controls the visibility of the [DockItem].
///
/// It also animates the translation of the item when it is hovered or dragged.

class DockItemOpacity extends StatelessWidget {
  const DockItemOpacity({
    super.key,
    required this.opacity,
    required this.itemIndex,
    required this.hoveredIndex,
    required this.itemSize,
    required this.child,
  });

  final double opacity;
  final int itemIndex;
  final int? hoveredIndex;
  final double itemSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        transform: Matrix4.translationValues(
          0,
          _shouldTranslate(itemIndex, hoveredIndex) ? -itemSize / 10 : 0,
          0,
        ),
        child: child,
      ),
    );
  }

  bool _shouldTranslate(int index, int? hoveredIndex) {
    if (hoveredIndex == null) return false;

    // Allow translation for the dragged item and its immediate neighbors.
    final int distance = (hoveredIndex - index).abs();
    return distance <= 1;
  }
}
