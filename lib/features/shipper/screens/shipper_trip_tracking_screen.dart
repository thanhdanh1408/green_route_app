// lib/features/shipper/screens/shipper_trip_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/mapbox_routing_service.dart';

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

    debugPrint('🗺️ [Mapbox-Shipper] Fetching route from ${start.latitude},${start.longitude} to ${end.latitude},${end.longitude}');

    try {
      final points = await MapboxRoutingService.getRoute(start, end);
      
      if (points.isEmpty) {
        debugPrint('⚠️ [Mapbox-Shipper] Empty route, using fallback');
        _useFallbackRoute(start, end);
        return;
      }

      if (!mounted) return;
      setState(() {
        routePoints = points;
        isLoadingRoute = false;
      });

      debugPrint('✅ [Mapbox-Shipper] Loaded route with ${routePoints.length} points');
    } catch (e) {
      debugPrint('❌ [Mapbox-Shipper] Error: $e, using fallback');
      _useFallbackRoute(start, end);
    }
  }

  void _useFallbackRoute(LatLng start, LatLng end) {
    if (!mounted) return;
    
    // Improved fallback: interpolate 5+ waypoints instead of just 3
    final points = <LatLng>[];
    points.add(start);
    
    const int waypoints = 6; // 6 waypoints = 5 segments
    for (int i = 1; i < waypoints; i++) {
      final t = i / waypoints;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      points.add(LatLng(lat, lng));
    }
    
    points.add(end);
    
    setState(() {
      routePoints = points;
      isLoadingRoute = false;
    });
    debugPrint('⚠️ [Mapbox-Shipper] Using improved fallback route with ${points.length} waypoints');
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
