import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import './../widgets/map_layers/base_map_layer.dart';
import '../widgets/map_layers/boundary_layer.dart';
import '../widgets/map_layers/map_zoom_controls.dart';

class PlacesMapPage extends StatefulWidget {
  const PlacesMapPage({Key? key}) : super(key: key);

  @override
  State<PlacesMapPage> createState() => _PlacesMapPageState();
}

class _PlacesMapPageState extends State<PlacesMapPage> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        centerTitle: true,
      ),
      body: Stack(
        // Wrap with Stack
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
            ],
          ),
          MapZoomControls(
              mapController:
                  _mapController), // Move outside FlutterMap but inside Stack
        ],
      ),
    );
  }
}
