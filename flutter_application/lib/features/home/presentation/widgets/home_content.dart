import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart';
import '../bloc/bottom_navigation_bar/tab_item.dart';

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
      child: GestureDetector(
        onHorizontalDragEnd: (details) => _handleDragEnd(context, details),
        child: tabs[selectedIndex].content,
      ),
    );
  }

  void _handleDragEnd(BuildContext context, DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    final cubit = context.read<BottomNavigationBarCubit>();

    if (details.primaryVelocity! > 0) {
      if (selectedIndex == 2) {
        cubit.switchTab(1);
      } else if (selectedIndex == 1) {
        cubit.switchTab(0);
      }
    } else if (details.primaryVelocity! < 0) {
      if (selectedIndex == 0) {
        cubit.switchTab(1);
      } else if (selectedIndex == 1) {
        cubit.switchTab(2);
      }
    }
  }
}
