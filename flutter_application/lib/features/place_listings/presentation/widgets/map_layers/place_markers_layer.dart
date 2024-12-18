import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../cubit/place_listings_cubit.dart';
import '../../cubit/place_listings_state.dart';

class PlaceMarkersLayer extends StatelessWidget {
  const PlaceMarkersLayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaceListingsCubit, PlaceListingsState>(
      builder: (context, state) {
        if (state.status == PlaceListingStatus.loading) {
          return const SizedBox.shrink();
        }

        final places = state.places
            .where((place) =>
                place.hasValidLocation &&
                place.latitude != null &&
                place.longitude != null)
            .toList();

        return MarkerLayer(
          markers: places
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
