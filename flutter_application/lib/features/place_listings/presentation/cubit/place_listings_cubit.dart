import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';
import '../../../place_listings/presentation/cubit/place_listings_state.dart';
import '../../../../core/voting/domain/repositories/i_voting_repository.dart';

@injectable
class PlaceListingsCubit extends Cubit<PlaceListingsState>
    implements StateStreamable<PlaceListingsState> {
  final SupabaseClient _supabaseClient;
  final IVotingRepository _votingRepository;
  static const int _pageSize = 10; // Number of records per page
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoading = false; // Add this flag

  PlaceListingsCubit(
    this._supabaseClient,
    this._votingRepository,
  ) : super(const PlaceListingsState());

  // In place_listings_cubit.dart

  Future<void> loadCategories() async {
    try {
      final response = await _supabaseClient.rpc(
        'get_approved_place_categories',
      );

      if (response == null) {
        throw Exception('Failed to fetch categories');
      }

      AppLogger.debug('Categories response:',
          error: response); // Add this for debugging

      final categories = (response as List)
          .map((item) => CategoryCount(
                name: item['category'] as String,
                count: item['count'] as int,
              ))
          .toList();

      emit(state.copyWith(
        categories: categories,
      ));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error loading categories',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        errorMessage: 'Failed to load categories',
      ));
    }
  }

  Future<void> loadPlaceListings({bool refresh = false}) async {
    if (_isLoading && !refresh) {
      AppLogger.debug('Already loading data, skipping request');
      return;
    }

    try {
      _isLoading = true;
      AppLogger.debug('Loading Place listings:', error: {
        'refresh': refresh,
        'currentPage': _currentPage,
        'pageSize': _pageSize,
      });

      if (refresh) {
        _currentPage = 1;
        _hasMoreData = true;
        emit(state.copyWith(
          status: PlaceListingStatus.loading,
          places: [],
          filteredPlaces: [],
        ));
      }

      if (!_hasMoreData && !refresh) {
        AppLogger.debug('No more data available');
        return;
      }

      await loadCategories();

      // Use the selected category if one exists
      final selectedCategory = state.selectedCategory;
      final response = await _supabaseClient.rpc(
        selectedCategory != null && selectedCategory != 'All'
            ? 'get_places_by_category'
            : 'get_approved_places_with_votes',
        params: {
          'page_number': _currentPage,
          'entries_per_page': _pageSize,
          if (selectedCategory != null && selectedCategory != 'All')
            'category_filter': selectedCategory,
        },
      );

      // Rest of the method remains the same
      if (response == null) {
        throw Exception('Failed to fetch places');
      }

      final newPlaces =
          (response as List).map((place) => Place.fromJson(place)).toList();
      _hasMoreData = newPlaces.length >= _pageSize;

      List<Place> updatedPlaces;
      if (_currentPage == 1) {
        updatedPlaces = newPlaces;
      } else {
        final existingIds = state.places.map((b) => b.uuid).toSet();
        final uniqueNewPlaces = newPlaces
            .where((place) => !existingIds.contains(place.uuid))
            .toList();
        updatedPlaces = [...state.places, ...uniqueNewPlaces];
      }

      if (newPlaces.isNotEmpty) {
        _currentPage++;
        AppLogger.debug('Incremented page number to: $_currentPage');
      }

      emit(state.copyWith(
        status: PlaceListingStatus.success,
        places: updatedPlaces,
        filteredPlaces: updatedPlaces,
      ));
    } catch (error, stackTrace) {
      // Error handling remains the same
      AppLogger.error('Error loading places',
          error: error, stackTrace: stackTrace);
      SentryMonitoring.captureException(error, stackTrace);
      emit(state.copyWith(
        status: PlaceListingStatus.failure,
        errorMessage: 'Failed to load places: ${error.toString()}',
      ));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadMorePlaces() async {
    if (state.searchQuery.isNotEmpty) {
      return;
    }

    if (state.status != PlaceListingStatus.success ||
        !_hasMoreData ||
        _isLoading) {
      return;
    }

    emit(state.copyWith(status: PlaceListingStatus.loadingMore));
    await loadPlaceListings();
  }

  Future<void> createPlace(Place place) async {
    try {
      AppLogger.info('Creating new Place', error: place.name);
      await SentryMonitoring.addBreadcrumb(
        message: 'Creating new Place',
        data: {'PlaceName': place.name},
      );

      emit(state.copyWith(status: PlaceListingStatus.loading));

      await _supabaseClient.from('amaravati_places').insert(place.toJson());

      await loadPlaceListings();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to create Place',
        error: e,
        stackTrace: stackTrace,
      );
      await SentryMonitoring.captureException(
        e,
        stackTrace,
        tagValue: 'create_Place_error',
      );

      emit(state.copyWith(
        status: PlaceListingStatus.failure,
        errorMessage: 'Failed to create Place: ${e.toString()}',
      ));
    }
  }

  Future<void> filterByCategory(String category) async {
    try {
      // Reset pagination when changing categories
      _currentPage = 1;
      _hasMoreData = true;

      emit(state.copyWith(
        status: PlaceListingStatus.loading,
        selectedCategory: category,
        places: [], // Clear existing places
        filteredPlaces: [], // Clear filtered places
      ));

      // Use loadPlaceListings instead of separate API call
      await loadPlaceListings(refresh: true);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error filtering places by category',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        status: PlaceListingStatus.failure,
        errorMessage: 'Failed to filter places: ${error.toString()}',
      ));
    }
  }

  Future<void> handleVote(String placeId, VoteType? voteType) async {
    try {
      AppLogger.info(
          'Handling vote for Place $placeId with vote type: $voteType');

      // Get the current Place list
      final currentPlaces = [...state.places];
      final filteredPlaces = [...state.filteredPlaces];

      // Update both main list and filtered list
      void updatePlaceInLists(Place updatedPlace) {
        final mainIndex = currentPlaces.indexWhere((b) => b.uuid == placeId);
        final filteredIndex =
            filteredPlaces.indexWhere((b) => b.uuid == placeId);

        if (mainIndex != -1) {
          currentPlaces[mainIndex] = updatedPlace;
        }
        if (filteredIndex != -1) {
          filteredPlaces[filteredIndex] = updatedPlace;
        }
      }

      // Find Place in either list
      final place = currentPlaces.firstWhere(
        (b) => b.uuid == placeId,
        orElse: () => filteredPlaces.firstWhere(
          (b) => b.uuid == placeId,
          orElse: () => throw Exception('Place not found'),
        ),
      );

      final previousVote = place.userVote;

      // Update vote counts optimistically
      final updatedPlace = _updatePlaceVoteCounts(
        place: place,
        newVote: voteType,
        previousVote: previousVote,
      );

      updatePlaceInLists(updatedPlace);

      emit(state.copyWith(
        places: currentPlaces,
        filteredPlaces: filteredPlaces,
      ));

      // Make the API call
      final result = await _votingRepository.vote(
        entityId: placeId,
        entityType: EntityType.place,
        voteType: voteType,
      );

      result.fold(
        (failure) {
          // Revert on failure
          updatePlaceInLists(place);
          emit(state.copyWith(
            places: currentPlaces,
            filteredPlaces: filteredPlaces,
          ));

          AppLogger.error('Vote failed', error: failure);
        },
        (success) {
          AppLogger.info('Vote successful');
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Unexpected error while handling vote',
        error: e,
        stackTrace: stackTrace,
      );
      await SentryMonitoring.captureException(
        e,
        stackTrace,
        tagValue: 'unexpected_vote_error',
      );
    }
  }

  Place _updatePlaceVoteCounts({
    required Place place,
    required VoteType? newVote,
    required int previousVote,
  }) {
    AppLogger.debug(
        'Updating Place vote counts - Place ID: ${place.uuid}, Previous vote: $previousVote, New vote: $newVote');

    int upvotes = place.upvotes;
    int downvotes = place.downvotes;

    // Remove previous vote
    if (previousVote == 1) {
      upvotes--;
    } else if (previousVote == -1) {
      downvotes--;
    }

    // Add new vote
    if (newVote == VoteType.upvote) {
      upvotes++;
    } else if (newVote == VoteType.downvote) {
      downvotes++;
    }

    AppLogger.debug(
        'Vote counts updated - Place ID: ${place.uuid}, Upvotes: $upvotes, Downvotes: $downvotes');

    return place.copyWith(
      userVote: newVote == null ? 0 : (newVote == VoteType.upvote ? 1 : -1),
      upvotes: upvotes,
      downvotes: downvotes,
    );
  }

  Future<void> searchPlaces(String query) async {
    try {
      AppLogger.debug('Searching places with query: $query');
      emit(state.copyWith(status: PlaceListingStatus.loading));

      if (query.isEmpty) {
        // Reset search-related state but keep pagination state
        emit(state.copyWith(
          searchQuery: '',
          status: PlaceListingStatus.loading,
        ));

        // Load first page without full refresh
        await loadPlaceListings(refresh: false);
        return;
      }

      final response = await _supabaseClient.rpc(
        'search_places',
        params: {
          'search_query': query.toLowerCase(),
        },
      );

      if (response == null) {
        throw Exception('Failed to search places');
      }

      final searchResults = (response as List)
          .map((place) => Place.fromJson(place as Map<String, dynamic>))
          .toList();

      emit(state.copyWith(
        status: PlaceListingStatus.success,
        filteredPlaces: searchResults,
        searchQuery: query,
      ));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error searching places',
        error: error,
        stackTrace: stackTrace,
      );
      await SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'search_places_error',
      );

      // Don't clear the existing list on error
      emit(state.copyWith(
        status: PlaceListingStatus.failure,
        errorMessage: 'Failed to search places: ${error.toString()}',
      ));
    }
  }
}
