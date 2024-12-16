import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/features/home/presentation/bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart';

class WelcomeContent extends StatelessWidget {
  const WelcomeContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NewsHeader(),
              const SizedBox(height: Spacing.s16),
              _FeaturedCategories(),
              const SizedBox(height: Spacing.s16),
              _QuickLinks(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome!',
              style: context.textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.s16),
            Text(
              'Amaravati Chamber is your trusted source for local news and updates from Amaravati, Andhra Pradesh',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCategories extends StatelessWidget {
  final List<Map<String, dynamic>> categories = const [
    {
      'title': 'News',
      'icon': '📰',
      'isActive': true,
      'isNews': true,
    },
    {
      'title': 'Place',
      'icon': '🏢',
      'isActive': true,
      'isNews': false,
    },
    {
      'title': 'Development',
      'icon': '🏗',
      'isActive': false,
      'isNews': true,
    },
    {
      'title': 'Education',
      'icon': '📚',
      'isActive': false,
      'isNews': true,
    },
    {
      'title': 'Culture',
      'icon': '🎭',
      'isActive': false,
      'isNews': true,
    },
    {
      'title': 'Events',
      'icon': '📅',
      'isActive': false,
      'isNews': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: Spacing.s8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isActive = category['isActive'] as bool;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isActive
                    ? () {
                        final cubit = context.read<BottomNavigationBarCubit>();
                        if (isActive) {
                          // Set the tab type (News/Place) before switching
                          cubit
                            ..emit(cubit.state.copyWith(
                              isNewsSelected: category['isNews'] as bool,
                            ))
                            ..switchTab(1);
                        }
                      }
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category['icon'] as String,
                      style: TextStyle(
                        fontSize: 24,
                        color: isActive ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive ? category['title'] as String : 'Coming Soon',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isActive ? null : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickLinks extends StatelessWidget {
  final List<Map<String, dynamic>> links = const [
    {
      'title': 'Latest Updates',
      'icon': Icons.newspaper,
      'description': 'Most recent news from Amaravati'
    },
    {
      'title': 'Emergency Contacts',
      'icon': Icons.phone,
      'description': 'Important contact numbers'
    },
    {
      'title': 'Public Services',
      'icon': Icons.place,
      'description': 'Government services information'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: Spacing.s8),
        ...links.map((link) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  context.read<BottomNavigationBarCubit>().switchTab(1);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(link['icon'] as IconData),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link['title'] as String,
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              link['description'] as String,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
