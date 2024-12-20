// lib/features/home/presentation/widgets/home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:amaravati_chamber/features/settings/presentation/page/settings_page.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'Amaravati Chamber',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
