import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/logging/app_logger.dart';

class BoundaryLayer extends StatefulWidget {
  const BoundaryLayer({Key? key}) : super(key: key);

  @override
  State<BoundaryLayer> createState() => _BoundaryLayerState();
}

class _BoundaryLayerState extends State<BoundaryLayer> {
  List<LatLng> boundaryPoints = [];

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  Future<void> _loadGeoJson() async {
    try {
      final String geoJsonString = await rootBundle
          .loadString('assets/maps/amaravati-outline-polygon.geojson');
      final Map<String, dynamic> geoJson = json.decode(geoJsonString);

      // Updated parsing logic to handle FeatureCollection
      if (geoJson['type'] == 'FeatureCollection') {
        final features = geoJson['features'] as List;
        if (features.isNotEmpty) {
          final firstFeature = features[0];
          if (firstFeature['geometry']['type'] == 'Polygon') {
            final coordinates =
                firstFeature['geometry']['coordinates'][0] as List;
            setState(() {
              boundaryPoints = coordinates
                  .map((coord) => LatLng(
                        (coord[1] as num).toDouble(), // latitude
                        (coord[0] as num).toDouble(), // longitude
                      ))
                  .toList()
                  .cast<LatLng>();
            });
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading GeoJSON: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (boundaryPoints.isEmpty) {
      return const SizedBox();
    }

    return PolygonLayer(
      polygons: [
        Polygon(
          points: boundaryPoints,
          color: Colors.blue.withOpacity(0.2),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
          isDotted: true,
          isFilled: true, // Make sure the polygon is filled
        ),
      ],
    );
  }
}
