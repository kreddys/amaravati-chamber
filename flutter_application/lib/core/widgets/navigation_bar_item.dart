// lib/core/widgets/navigation_bar_item.dart
import 'package:flutter/material.dart';

class NavigationBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const NavigationBarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
      tooltip: tooltip,
    );
  }
}
