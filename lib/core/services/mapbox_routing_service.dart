import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class MapboxRoutingService {
  // Mapbox Access Token (Secret Key)
  static const String _mapboxToken = 'sk.eyJ1IjoiZGFuaHBpZ2xpbiIsImEiOiJjbWo2dm44dGkwMGg1M2dyMHJrMjZsYzQ0In0.BTnAhJENnkMksk5elg0R4Q';
  
  // Mapbox Directions API endpoint
  static const String _mapboxUrl = 'https://api.mapbox.com/directions/v5/mapbox/driving';

  /// Fetch route from Mapbox Directions API
  /// Returns list of LatLng points representing the route
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      debugPrint('🗺️ [Mapbox] Fetching route from ${start.latitude},${start.longitude} to ${end.latitude},${end.longitude}');
      
      // Build request URL
      final url = Uri.parse(
        '$_mapboxUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson&access_token=$_mapboxToken'
      );

      debugPrint('🔗 [Mapbox] Request URL: ${url.toString().substring(0, 100)}...');

      // Make request with timeout
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ [Mapbox] Request timeout');
          throw Exception('Timeout');
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Mapbox] Response received (200 OK)');
        final data = jsonDecode(response.body);
        
        // Check for errors in response
        if (data['code'] != 'Ok') {
          debugPrint('❌ [Mapbox] Error code: ${data['code']}');
          throw Exception('Mapbox error: ${data['code']}');
        }

        // Extract routes
        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          debugPrint('⚠️ [Mapbox] No routes found in response');
          throw Exception('No routes found');
        }

        final route = data['routes'][0];
        final geometry = route['geometry'];

        if (geometry == null || geometry['coordinates'] == null) {
          debugPrint('⚠️ [Mapbox] Invalid geometry in response');
          throw Exception('Invalid geometry');
        }

        final coords = geometry['coordinates'] as List;
        
        if (coords.isEmpty) {
          debugPrint('⚠️ [Mapbox] Empty coordinates in response');
          throw Exception('Empty coordinates');
        }

        // Convert GeoJSON coordinates [lng, lat] to LatLng [lat, lng]
        List<LatLng> points = [];
        for (var coord in coords) {
          try {
            final lat = (coord[1] as num).toDouble();
            final lng = (coord[0] as num).toDouble();
            points.add(LatLng(lat, lng));
          } catch (e) {
            debugPrint('⚠️ [Mapbox] Error parsing coordinate: $coord - $e');
            continue;
          }
        }

        if (points.isEmpty) {
          debugPrint('⚠️ [Mapbox] No valid coordinates parsed');
          throw Exception('No valid coordinates');
        }

        debugPrint('✅ [Mapbox] Successfully loaded route with ${points.length} points');
        debugPrint('📍 [Mapbox] Distance: ${route['distance']}m, Duration: ${route['duration']}s');
        
        return points;
      } else {
        debugPrint('❌ [Mapbox] HTTP error ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [Mapbox] Error: $e');
      rethrow;
    }
  }

  /// Test Mapbox connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.mapbox.com/directions/v5/mapbox/driving/0,0;1,1?access_token=$_mapboxToken')
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [Mapbox] Connection test failed: $e');
      return false;
    }
  }
}
