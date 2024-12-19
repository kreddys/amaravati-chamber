import 'package:flutter/material.dart';

class GestureWrapper extends StatelessWidget {
  final Widget child;
  final Function(DragEndDetails)? onHorizontalDragEnd;

  const GestureWrapper({
    super.key,
    required this.child,
    this.onHorizontalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: child,
    );
  }
}
