// lib/features/shipper/screens/shipper_trip_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_theme.dart';

class ShipperTripTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const ShipperTripTrackingScreen({super.key, required this.order});

  @override
  State<ShipperTripTrackingScreen> createState() => _ShipperTripTrackingScreenState();
}

class _ShipperTripTrackingScreenState extends State<ShipperTripTrackingScreen> {
  List<LatLng> routePoints = [];
  bool isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    // Get coordinates from order data with fallback defaults
    final start = widget.order['fromLatLng'] as LatLng? ?? const LatLng(13.9833, 108.0000);
    final end = widget.order['toLatLng'] as LatLng? ?? const LatLng(12.6667, 108.0500);

    // Multiple OSRM servers for reliability
    final osrmServers = [
      'https://router.project-osrm.org',  // Primary (HTTPS)
      'http://router.project-osrm.org',   // HTTP fallback
      'https://routing.openstreetmap.de', // European backup
    ];

    debugPrint('🗺️ [OSRM-Shipper] Fetching route from ${start.latitude},${start.longitude} to ${end.latitude},${end.longitude}');

    for (var i = 0; i < osrmServers.length; i++) {
      try {
        final server = osrmServers[i];
        final url = '$server/route/v1/driving/'
            '${start.longitude},${start.latitude};'
            '${end.longitude},${end.latitude}'
            '?overview=full&geometries=geojson';

        debugPrint('🔄 [OSRM-Shipper] Trying server ${i + 1}/${osrmServers.length}: $server');
        
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⏱️ [OSRM-Shipper] Timeout on server ${i + 1}');
            throw Exception('Timeout');
          },
        );

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            
            if (data['routes'] == null || (data['routes'] as List).isEmpty) {
              debugPrint('⚠️ [OSRM-Shipper] No routes found');
              continue;
            }
            
            final route = data['routes'][0];
            final geometry = route['geometry'];
            
            if (geometry == null || geometry['coordinates'] == null) {
              debugPrint('⚠️ [OSRM-Shipper] Invalid geometry');
              continue;
            }
            
            final coords = geometry['coordinates'] as List;
            
            if (coords.isEmpty) {
              debugPrint('⚠️ [OSRM-Shipper] Empty coordinates');
              continue;
            }

            // Convert GeoJSON [lng, lat] to LatLng [lat, lng]
            List<LatLng> points = [];
            for (var coord in coords) {
              try {
                final lat = (coord[1] as num).toDouble();
                final lng = (coord[0] as num).toDouble();
                points.add(LatLng(lat, lng));
              } catch (e) {
                continue;
              }
            }

            if (points.isEmpty) {
              debugPrint('⚠️ [OSRM-Shipper] No valid coordinates parsed');
              continue;
            }

            if (!mounted) return;
            setState(() {
              routePoints = points;
              isLoadingRoute = false;
            });

            debugPrint('✅ [OSRM-Shipper] Loaded route with ${routePoints.length} points');
            return;
          } catch (parseError) {
            debugPrint('❌ [OSRM-Shipper] Parse error: $parseError');
            continue;
          }
        } else {
          debugPrint('⚠️ [OSRM-Shipper] Server returned ${response.statusCode}');
          continue;
        }
      } catch (e) {
        debugPrint('❌ [OSRM-Shipper] Error: $e');
        continue;
      }
    }

    // All servers failed
    debugPrint('❌ [OSRM-Shipper] All servers failed, using fallback');
    _useFallbackRoute(start, end);
  }

  void _useFallbackRoute(LatLng start, LatLng end) {
    if (!mounted) return;
    
    setState(() {
      routePoints = [
        start,
        LatLng((start.latitude + end.latitude) / 2, (start.longitude + end.longitude) / 2),
        end,
      ];
      isLoadingRoute = false;
    });
    debugPrint('⚠️ [Shipper] Using fallback route');
  }

  // BUILD MAP WITH DYNAMIC MARKERS AND ROUTE
  Widget _buildMapWidget() {
    final start = widget.order['fromLatLng'] as LatLng? ?? const LatLng(13.9833, 108.0000);
    final end = widget.order['toLatLng'] as LatLng? ?? const LatLng(12.6667, 108.0500);
    
    // Calculate center and zoom level based on route
    final centerLat = (start.latitude + end.latitude) / 2;
    final centerLng = (start.longitude + end.longitude) / 2;
    
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: 9.0,
      ),
      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.green_route_app',
          maxNativeZoom: 19,
          tileSize: 256,
        ),
        
        // Route polyline
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: AppColors.primary,
                strokeWidth: 4,
                borderColor: AppColors.primary.withOpacity(0.5),
                borderStrokeWidth: 1,
              ),
            ],
          ),
        
        // Start and End markers
        MarkerLayer(
          markers: [
            // START MARKER
            Marker(
              point: start,
              width: 50,
              height: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                  ),
                  const Text('Xuất phát', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            // END MARKER
            Marker(
              point: end,
              width: 50,
              height: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.flag, color: Colors.white, size: 24),
                  ),
                  const Text('Đích đến', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        
        // Loading indicator
        if (isLoadingRoute)
          const Positioned(
            top: 12,
            right: 12,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Theo dõi đơn hàng: ${widget.order['id']}', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // BẢN ĐỒ
            Container(
              height: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, spreadRadius: 2),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildMapWidget(),
              ),
            ),
            const SizedBox(height: 24),

            // THÔNG TIN CHUYẾN HÀNG
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Thông tin chuyến hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),

                    _infoRow('Loại chuyến:', widget.order['tripType'] == 'regular' ? 'Đơn thường' : 'Đơn ghép', 
                        icon: widget.order['tripType'] == 'regular' ? Icons.assignment : Icons.layers,
                        color: widget.order['tripType'] == 'regular' ? Colors.blue : Colors.orange),
                    _infoRow('Tuyến đường:', widget.order['route'], icon: Icons.route),
                    _infoRow('Loại hàng:', widget.order['goods'] ?? 'N/A', icon: Icons.inventory_2),
                    _infoRow('Khối lượng:', widget.order['weight'] ?? 'N/A', icon: Icons.scale),
                    if ((widget.order['fromDetail'] ?? '').isNotEmpty)
                      _infoRow('Điểm nhận:', widget.order['fromDetail'], icon: Icons.location_on),
                    if ((widget.order['toDetail'] ?? '').isNotEmpty)
                      _infoRow('Điểm giao:', widget.order['toDetail'], icon: Icons.flag),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // THÔNG TIN TÀI XẾ
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Thông tin tài xế', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(Icons.person, color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order['driverName'] ?? 'Không có thông tin',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.order['driverPhone'] ?? 'N/A',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        if ((widget.order['driverPhone'] ?? '').isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement phone call using url_launcher
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gọi ${widget.order['driverPhone']}')),
                              );
                            },
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Gọi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _infoRow('Giá cước:', widget.order['price'] ?? 'N/A', 
                        icon: Icons.attach_money, color: Colors.red),
                    _infoRow('Trạng thái:', widget.order['status'] ?? 'N/A',
                        icon: Icons.info, color: widget.order['statusColor']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {IconData? icon, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: label, style: const TextStyle(color: Colors.grey)),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: value,
                    style: TextStyle(fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
