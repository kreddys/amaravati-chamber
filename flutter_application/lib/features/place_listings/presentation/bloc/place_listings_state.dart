import 'package:equatable/equatable.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';

enum PlaceListingStatus { initial, loading, loadingMore, success, failure }

class CategoryCount {
  final String name;
  final int count;

  CategoryCount({
    required this.name,
    required this.count,
  });
}

class PlaceListingsState extends Equatable {
  const PlaceListingsState({
    this.status = PlaceListingStatus.initial,
    this.places = const [],
    this.filteredPlaces = const [],
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.errorMessage,
  });

  final PlaceListingStatus status;
  final List<Place> places;
  final List<Place> filteredPlaces;
  final List<CategoryCount> categories;
  final String? selectedCategory;
  final String searchQuery;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        status,
        places,
        filteredPlaces,
        categories,
        selectedCategory,
        searchQuery,
        errorMessage,
      ];

  PlaceListingsState copyWith({
    PlaceListingStatus? status,
    List<Place>? places,
    List<Place>? filteredPlaces,
    List<CategoryCount>? categories,
    String? selectedCategory,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PlaceListingsState(
      status: status ?? this.status,
      places: places ?? this.places,
      filteredPlaces: filteredPlaces ?? this.filteredPlaces,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class Point {
  final double x;
  final double y;

  Point({required this.x, required this.y});

  @override
  String toString() => '($x,$y)';
}

class Place {
  final String uuid;
  final String? name;
  final String? address;
  final String? category;
  final String? website;
  final String? social;
  final String? contactNumber;
  final double? latitude;
  final double? longitude;
  final int upvotes;
  final int downvotes;
  final int userVote;

  Place({
    required this.uuid,
    this.name,
    this.address,
    this.category,
    this.website,
    this.social,
    this.contactNumber,
    this.latitude,
    this.longitude,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userVote = 0,
  });

  // Helper getter for location
  Point? get location => (latitude != null && longitude != null)
      ? Point(x: longitude!, y: latitude!)
      : null;

  // Helper getters for valid contact methods
  List<String> get validWebsites =>
      website != null && website!.isNotEmpty ? [website!] : [];

  List<String> get validSocials =>
      social != null && social!.isNotEmpty ? [social!] : [];

  List<String> get validPhones =>
      contactNumber != null && contactNumber!.isNotEmpty
          ? [contactNumber!]
          : [];

  // Helper getter for categories
  List<String> get categoryList =>
      category != null && category!.isNotEmpty ? [category!] : [];

  Place copyWith({
    String? uuid,
    String? name,
    String? address,
    String? category,
    String? website,
    String? social,
    String? contactNumber,
    double? latitude,
    double? longitude,
    int? upvotes,
    int? downvotes,
    int? userVote,
  }) {
    return Place(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      address: address ?? this.address,
      category: category ?? this.category,
      website: website ?? this.website,
      social: social ?? this.social,
      contactNumber: contactNumber ?? this.contactNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      userVote: userVote ?? this.userVote,
    );
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    try {
      // Handle user vote conversion from string to int
      int userVoteValue = 0;
      final userVote = json['user_vote'];
      if (userVote is int) {
        userVoteValue = userVote;
      } else if (userVote is String) {
        userVoteValue = switch (userVote.toLowerCase()) {
          'upvote' => 1,
          'downvote' => -1,
          _ => 0,
        };
      }

      // Handle numeric values that might come as strings
      double? parseLat(dynamic value) {
        if (value == null) return null;
        return value is String ? double.tryParse(value) : value?.toDouble();
      }

      double? parseLong(dynamic value) {
        if (value == null) return null;
        return value is String ? double.tryParse(value) : value?.toDouble();
      }

      int parseVoteCount(dynamic value) {
        if (value == null) return 0;
        return value is String ? int.tryParse(value) ?? 0 : value as int? ?? 0;
      }

      return Place(
        uuid: json['uuid'] as String,
        name: json['name'] as String?,
        address: json['address'] as String?,
        category: json['category'] as String?,
        website: json['website'] as String?,
        social: json['social'] as String?,
        contactNumber: json['contact_number'] as String?,
        latitude: parseLat(json['latitude']),
        longitude: parseLong(json['longitude']),
        upvotes: parseVoteCount(json['upvotes']),
        downvotes: parseVoteCount(json['downvotes']),
        userVote: userVoteValue,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error parsing Place from JSON: ${json.toString()}',
        error: e,
        stackTrace: stackTrace,
      );
      SentryMonitoring.captureException(e, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'address': address,
      'category': category,
      'website': website,
      'social': social,
      'contact_number': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'user_vote': userVote,
    };
  }

  // Helper getter for display name
  String get displayName => name ?? 'Unnamed Place';

  // Helper getter for display address
  String get displayAddress => address ?? 'No address available';

  // Helper method to check if Place has valid location
  bool get hasValidLocation =>
      latitude != null && longitude != null && latitude != 0 && longitude != 0;
}
