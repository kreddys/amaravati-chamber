// lib/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/dependency_injection.dart';
import '../bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart';
import '../widgets/home_navigation_bar.dart';
import '../widgets/home_app_bar.dart';
import '../../../news/presentation/bloc/news_cubit.dart';
import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/monitoring/sentry_monitoring.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building HomePage');
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            AppLogger.debug('Creating BottomNavigationBarCubit');
            return getIt<BottomNavigationBarCubit>();
          },
        ),
        BlocProvider(
          create: (context) {
            AppLogger.debug('Creating NewsCubit');
            return getIt<NewsCubit>();
          },
        ),
      ],
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationBarCubit, BottomNavigationBarState>(
      buildWhen: (previous, current) {
        final changed = current.selectedIndex != previous.selectedIndex;
        if (changed) {
          AppLogger.info(
              'Navigation changed from ${previous.selectedIndex} to ${current.selectedIndex}');
          SentryMonitoring.addBreadcrumb(
            message: 'Tab navigation changed to ${current.selectedIndex}',
            category: 'navigation',
          );
        }
        return changed;
      },
      builder: (context, state) {
        return Scaffold(
          appBar: state.selectedIndex == 0 ? const HomeAppBar() : null,
          body: SafeArea(
            child: GestureDetector(
              onHorizontalDragEnd: (DragEndDetails details) {
                if (details.primaryVelocity == null) return;

                final cubit = context.read<BottomNavigationBarCubit>();
                final currentIndex = state.selectedIndex;

                if (details.primaryVelocity! > 0) {
                  if (currentIndex == 2) {
                    cubit.switchTab(1);
                  } else if (currentIndex == 1) {
                    cubit.switchTab(0);
                  }
                } else if (details.primaryVelocity! < 0) {
                  if (currentIndex == 0) {
                    cubit.switchTab(1);
                  } else if (currentIndex == 1) {
                    cubit.switchTab(2);
                  }
                }
              },
              child: state.tabs[state.selectedIndex].content,
            ),
          ),
          bottomNavigationBar: HomeNavigationBar(
            selectedIndex: state.selectedIndex,
            tabs: state.tabs,
          ),
        );
      },
    );
  }
}
