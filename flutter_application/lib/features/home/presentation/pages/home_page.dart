// lib/features/home/presentation/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/core/widgets/app_bar.dart';
import 'package:amaravati_chamber/dependency_injection.dart';
import '../widgets/home_content.dart';
import 'widgets/home_navigation_bar.dart';
import '../../news/presentation/bloc/news_cubit.dart';
import '../bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: _createBlocProviders(),
      child: const _HomeView(),
    );
  }

  List<BlocProvider> _createBlocProviders() {
    return [
      BlocProvider(create: (_) => getIt<BottomNavigationBarCubit>()),
      BlocProvider(create: (_) => getIt<NewsCubit>()),
    ];
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationBarCubit, BottomNavigationBarState>(
      builder: (context, state) {
        return Scaffold(
          appBar: state.selectedIndex == 0
              ? AppBarWidget(
                  title: 'Amaravati Chamber',
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => _navigateToSettings(context),
                    ),
                  ],
                )
              : null,
          body: HomeContent(
            selectedIndex: state.selectedIndex,
            tabs: state.tabs,
          ),
          bottomNavigationBar: HomeNavigationBar(
            selectedIndex: state.selectedIndex,
            tabs: state.tabs,
          ),
        );
      },
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }
}
