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
    const start = LatLng(13.9833, 108.0000);
    const end = LatLng(12.6667, 108.0500);

    try {
      final url = 'http://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          routePoints = coords.map((coord) => LatLng(coord[1], coord[0])).toList();
          isLoadingRoute = false;
        });
      } else {
        _useFallbackRoute();
      }
    } catch (e) {
      _useFallbackRoute();
    }
  }

  void _useFallbackRoute() {
    setState(() {
      routePoints = [
        const LatLng(13.9833, 108.0000),
        const LatLng(13.7, 108.02),
        const LatLng(13.4, 108.05),
        const LatLng(13.1, 108.06),
        const LatLng(12.9, 108.055),
        const LatLng(12.6667, 108.0500),
      ];
      isLoadingRoute = false;
    });
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
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(13.9833, 108.0000),
                    initialZoom: 8.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.green_route_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: const LatLng(13.9833, 108.0000),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                        ),
                        Marker(
                          point: const LatLng(12.6667, 108.0500),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: AppColors.primary,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    if (isLoadingRoute)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
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
