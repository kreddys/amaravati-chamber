import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../logging/app_logger.dart';
import '../monitoring/sentry_monitoring.dart';

class GeojsonUtils {
  /// Loads and parses a GeoJSON file from assets
  static Future<List<LatLng>> loadGeoJsonFromAsset(String assetPath) async {
    try {
      // Load the GeoJSON file content
      final String jsonString = await rootBundle.loadString(assetPath);

      // Parse the JSON
      final Map<String, dynamic> geoJson = json.decode(jsonString);

      // Extract coordinates from the first feature's geometry
      // Assuming the GeoJSON contains a single polygon feature
      final List<dynamic> coordinates =
          geoJson['features'][0]['geometry']['coordinates'][0];

      // Convert coordinates to LatLng list
      // Note: GeoJSON coordinates are [longitude, latitude]
      return coordinates.map<LatLng>((coord) {
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }).toList();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error parsing GeoJSON file',
        error: error,
        stackTrace: stackTrace,
      );
      SentryMonitoring.captureException(error, stackTrace);
      rethrow;
    }
  }

  /// Parses a list of coordinates into LatLng objects
  static List<LatLng> parseGeoJsonCoordinates(List<List<double>> coordinates) {
    return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
  }
}
