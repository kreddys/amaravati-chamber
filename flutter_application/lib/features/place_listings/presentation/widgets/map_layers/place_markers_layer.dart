import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cubit/place_listings_state.dart';
import '../../../../../core/logging/app_logger.dart';

class PlaceMarkersLayer extends StatefulWidget {
  const PlaceMarkersLayer({Key? key}) : super(key: key);

  @override
  State<PlaceMarkersLayer> createState() => _PlaceMarkersLayerState();
}

class _PlaceMarkersLayerState extends State<PlaceMarkersLayer> {
  final _supabaseClient = Supabase.instance.client;
  List<Place> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApprovedPlaces();
  }

  Future<void> _loadApprovedPlaces() async {
    try {
      final response = await _supabaseClient.rpc(
        'get_approved_places_with_votes',
        params: {
          'page_number': 1,
          'entries_per_page': 100, // Adjust this number as needed
        },
      );

      if (response == null) {
        throw Exception('Failed to fetch places');
      }

      final places = (response as List)
          .map((place) => Place.fromJson(place))
          .where((place) =>
              place.hasValidLocation &&
              place.latitude != null &&
              place.longitude != null)
          .toList();

      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (error) {
      AppLogger.error('Error loading places:', error: error);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: _places
          .map(
            (place) => Marker(
              point: LatLng(place.latitude!, place.longitude!),
              width: 30,
              height: 30,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.displayName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            place.displayAddress,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (place.category != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Category: ${place.category}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 1, // Set a small fixed width for the dot
                  height: 1, // Set a small fixed height for the dot
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape
                        .rectangle, // Changed from circle to rectangle for square shape
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
