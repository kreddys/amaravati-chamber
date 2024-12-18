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

      if (geoJson['type'] == 'Feature' &&
          geoJson['geometry']['type'] == 'Polygon') {
        final coordinates = geoJson['geometry']['coordinates'][0] as List;
        setState(() {
          boundaryPoints = coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList()
              .cast<LatLng>();
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading GeoJSON: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (boundaryPoints.isEmpty) return const SizedBox();

    return PolygonLayer(
      polygons: [
        Polygon(
          points: boundaryPoints,
          color: Colors.blue.withOpacity(0.2),
          borderColor: Colors.blue,
          borderStrokeWidth: 3,
          isDotted: true,
        ),
      ],
    );
  }
}
