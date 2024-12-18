import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cubit/place_listings_state.dart';
import '../../../../../core/logging/app_logger.dart';
import 'dart:math';

class HeatMapLayer extends StatefulWidget {
  const HeatMapLayer({Key? key}) : super(key: key);

  @override
  State<HeatMapLayer> createState() => _HeatMapLayerState();
}

class _HeatMapLayerState extends State<HeatMapLayer> {
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
          'entries_per_page': 500,
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

  Color _getGradientColor(double intensity) {
    // Beautiful gradient colors
    if (intensity < 0.2) {
      return Color.fromRGBO(135, 206, 250, 0.3); // Light blue
    } else if (intensity < 0.4) {
      return Color.fromRGBO(30, 144, 255, 0.4); // Dodger blue
    } else if (intensity < 0.6) {
      return Color.fromRGBO(0, 191, 255, 0.5); // Deep sky blue
    } else if (intensity < 0.8) {
      return Color.fromRGBO(0, 127, 255, 0.6); // Azure blue
    } else {
      return Color.fromRGBO(0, 0, 255, 0.7); // Pure blue
    }
  }

  List<CircleMarker> _generateHeatMapPoints() {
    const double baseRadius = 800.0; // Slightly smaller base radius
    const double maxRadius = 2000.0; // Maximum radius for dense areas
    List<CircleMarker> markers = [];

    // Create density map
    Map<String, int> densityMap = {};
    for (final place in _places) {
      for (double lat = -0.01; lat <= 0.01; lat += 0.002) {
        for (double lng = -0.01; lng <= 0.01; lng += 0.002) {
          final key =
              '${(place.latitude! + lat).toStringAsFixed(3)},${(place.longitude! + lng).toStringAsFixed(3)}';
          densityMap[key] = (densityMap[key] ?? 0) + 1;
        }
      }
    }

    // Find maximum density
    final maxDensity = densityMap.values.reduce(max);

    // Generate multiple circles for each point with different radiuses
    for (final place in _places) {
      final basePoint = LatLng(place.latitude!, place.longitude!);
      final density = densityMap[
              '${place.latitude!.toStringAsFixed(3)},${place.longitude!.toStringAsFixed(3)}'] ??
          1;
      final intensity = density / maxDensity;

      // Add multiple overlapping circles with different radiuses and opacities
      for (double radiusFactor = 0.3;
          radiusFactor <= 1.0;
          radiusFactor += 0.2) {
        final radius =
            baseRadius + (maxRadius - baseRadius) * intensity * radiusFactor;
        final opacity = (0.7 - (radiusFactor * 0.5)) * intensity;

        markers.add(CircleMarker(
          point: basePoint,
          radius: radius,
          color: _getGradientColor(intensity).withOpacity(opacity),
          borderColor: Colors.transparent,
          borderStrokeWidth: 0,
          useRadiusInMeter: true,
        ));
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        CircleLayer(
          circles: _generateHeatMapPoints(),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Place Density',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _LegendItem(color: _getGradientColor(1.0), label: 'Very High'),
          _LegendItem(color: _getGradientColor(0.75), label: 'High'),
          _LegendItem(color: _getGradientColor(0.5), label: 'Medium'),
          _LegendItem(color: _getGradientColor(0.25), label: 'Low'),
          _LegendItem(color: _getGradientColor(0.1), label: 'Very Low'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
