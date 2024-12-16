import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class PlacesMapPage extends StatefulWidget {
  const PlacesMapPage({Key? key}) : super(key: key);

  @override
  State<PlacesMapPage> createState() => _PlacesMapPageState();
}

class _PlacesMapPageState extends State<PlacesMapPage> {
  late final Future<PmTilesVectorTileProvider> _futureTileProvider;
  List<LatLng> boundaryPoints = [];

  @override
  void initState() {
    super.initState();
    _futureTileProvider = PmTilesVectorTileProvider.fromSource(
      'https://kmisqlvoiofymxicxiwv.supabase.co/storage/v1/object/public/maps/amaravati2.pmtiles',
    );
    _loadGeoJson();
  }

  Future<void> _loadGeoJson() async {
    try {
      AppLogger.info('Loading GeoJSON file');
      final String geoJsonString = await rootBundle
          .loadString('assets/maps/amaravati-outline-polygon.geojson');

      AppLogger.debug(
          'GeoJSON content: ${geoJsonString.substring(0, 100)}...'); // Log first 100 chars

      final Map<String, dynamic> geoJson = json.decode(geoJsonString);

      AppLogger.debug('GeoJSON type: ${geoJson['type']}');
      AppLogger.debug('Geometry type: ${geoJson['geometry']?['type']}');

      // Extract coordinates from GeoJSON
      if (geoJson['type'] == 'Feature' &&
          geoJson['geometry']['type'] == 'Polygon') {
        final coordinates = geoJson['geometry']['coordinates'][0] as List;
        boundaryPoints = coordinates
            .map((coord) {
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            })
            .toList()
            .cast<LatLng>();

        AppLogger.info(
            'Successfully loaded boundary points: ${boundaryPoints.length} points');
        AppLogger.debug(
            'First point: ${boundaryPoints.first}, Last point: ${boundaryPoints.last}');

        if (mounted) {
          setState(() {});
        }
      } else {
        AppLogger.warning('Unexpected GeoJSON structure');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading GeoJSON: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        centerTitle: true,
      ),
      body: FutureBuilder<PmTilesVectorTileProvider>(
        future: _futureTileProvider,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            AppLogger.error('Error loading tile provider: ${snapshot.error}');
            return Center(child: Text('Error loading map'));
          }

          if (snapshot.hasData) {
            return FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(16.393872, 80.512708),
                initialZoom: 10.0,
                debugMultiFingerGestureWinner:
                    true, // Helps with debugging gestures
              ),
              children: [
                VectorTileLayer(
                  tileProviders: TileProviders({
                    'protomaps': snapshot.data!,
                  }),
                  theme: ProtomapsThemes.light(),
                ),
                if (boundaryPoints.isNotEmpty) // Only show if we have points
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: boundaryPoints,
                        color: Colors.blue.withOpacity(0.2),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 3, // Made thicker for visibility
                        isDotted:
                            true, // Makes the border dotted for better visibility
                      ),
                    ],
                  ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
