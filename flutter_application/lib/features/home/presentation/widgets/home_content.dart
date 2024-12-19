import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/gesture_wrapper.dart'; // New shared component

class HomeContent extends StatelessWidget {
  final int selectedIndex;
  final List<TabItem> tabs;

  const HomeContent({
    super.key,
    required this.selectedIndex,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureWrapper(
        // New shared component
        onHorizontalDragEnd: (details) => _handleDragEnd(context, details),
        child: tabs[selectedIndex].content,
      ),
    );
  }

  void _handleDragEnd(BuildContext context, DragEndDetails details) {
    // ... existing drag handling logic
  }
}
