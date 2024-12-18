import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../place_listings/presentation/cubit/place_listings_cubit.dart';
import '../../../place_listings/presentation/cubit/place_listings_state.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/widgets/tag_filter.dart';
import '../../../place_listings/presentation/widgets/place_card.dart';
import 'package:amaravati_chamber/dependency_injection.dart';
import '../../../../core/logging/app_logger.dart';
import 'dart:async';
import './places_map_page.dart';

class PlaceListingsPage extends StatelessWidget {
  const PlaceListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlaceListingsCubit>()..loadPlaceListings(),
      child: const PlaceListingsView(),
    );
  }
}

class PlaceListingsView extends StatefulWidget {
  const PlaceListingsView({super.key});

  @override
  State<PlaceListingsView> createState() => _PlaceListingsViewState();
}

class _PlaceListingsViewState extends State<PlaceListingsView> {
  Timer? _debounceTimer;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<PlaceListingsCubit>().loadMorePlaces();
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<PlaceListingsCubit>().searchPlaces('');
      }
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _toggleSearch,
            )
          : null,
      centerTitle: true,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search Places...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
              onChanged: (value) {
                // Debounce the search to avoid too many requests
                if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    context.read<PlaceListingsCubit>().searchPlaces(value);
                  }
                });
              },
            )
          : Text(
              'Places Directory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.clear : Icons.search,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: _isSearching
              ? () {
                  _searchController.clear();
                  context.read<PlaceListingsCubit>().searchPlaces('');
                }
              : _toggleSearch,
        ),
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PlacesMapPage(),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          if (!_isSearching)
            if (!_isSearching)
              BlocBuilder<PlaceListingsCubit, PlaceListingsState>(
                builder: (context, state) {
                  // Add this for debugging
                  AppLogger.debug('Current categories:',
                      error: state.categories);

                  final categoryNames =
                      state.categories.map((c) => c.name).toList();
                  categoryNames.insert(0, 'All');

                  return TagFilter(
                    tags: categoryNames,
                    selectedTag: state.selectedCategory ?? 'All',
                    onTagSelected: (category) {
                      context
                          .read<PlaceListingsCubit>()
                          .filterByCategory(category);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.s8),
                  );
                },
              ),
          if (!_isSearching) const SizedBox(height: 8.0),
          Expanded(
            child: BlocBuilder<PlaceListingsCubit, PlaceListingsState>(
              builder: (context, state) {
                switch (state.status) {
                  case PlaceListingStatus.initial:
                    return const Center(child: CircularProgressIndicator());
                  case PlaceListingStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case PlaceListingStatus.loadingMore:
                  case PlaceListingStatus.success:
                    if (state.filteredPlaces.isEmpty) {
                      return const Center(child: Text('No Places found'));
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: state.filteredPlaces.length +
                          (state.status == PlaceListingStatus.loadingMore
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.filteredPlaces.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final place = state.filteredPlaces[index];
                        return PlaceCard(
                          place: place,
                          onVote: (placeId, voteType) {
                            context
                                .read<PlaceListingsCubit>()
                                .handleVote(placeId, voteType);
                          },
                        );
                      },
                    );
                  case PlaceListingStatus.failure:
                    return Center(
                      child: Text(state.errorMessage ?? 'Something went wrong'),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
