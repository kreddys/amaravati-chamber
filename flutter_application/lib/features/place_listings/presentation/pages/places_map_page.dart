import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './../widgets/map_layers/base_map_layer.dart';
import '../widgets/map_layers/boundary_layer.dart';
import '../widgets/map_layers/map_zoom_controls.dart';
import '../widgets/map_layers/place_markers_layer.dart';
import '../cubit/place_listings_cubit.dart';
import '../../../../dependency_injection.dart';

// Separate widget class for the page
class PlacesMapPage extends StatelessWidget {
  const PlacesMapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<PlaceListingsCubit>(),
      child: const PlacesMapView(),
    );
  }
}

// Separate view class for the content
class PlacesMapView extends StatefulWidget {
  const PlacesMapView({Key? key}) : super(key: key);

  @override
  State<PlacesMapView> createState() => _PlacesMapViewState();
}

class _PlacesMapViewState extends State<PlacesMapView> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(16.393872, 80.512708),
              initialZoom: 10.0,
            ),
            children: const [
              BaseMapLayer(),
              BoundaryLayer(),
              PlaceMarkersLayer(),
            ],
          ),
          MapZoomControls(mapController: _mapController),
        ],
      ),
    );
  }
}
