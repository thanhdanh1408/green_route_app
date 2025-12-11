// lib/features/driver/screens/trip_tracking_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class TripTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  const TripTrackingScreen({super.key, required this.trip});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  int currentStep = 0;
  File? deliveryPhoto;
  List<LatLng> routePoints = []; // Real route from OSRM
  bool isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    currentStep = widget.trip['progress'];
    _fetchRoute(); // Fetch real route on init
  }

  // Fetch real route from OSRM (free routing service)
  Future<void> _fetchRoute() async {
    const start = LatLng(13.9833, 108.0000);
    const end = LatLng(12.6667, 108.0500);

    try {
      // OSRM public API - free, no key needed
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

        debugPrint('✅ Loaded real route with ${routePoints.length} points');
      } else {
        _useFallbackRoute();
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching route: $e');
      _useFallbackRoute();
    }
  }

  // Fallback to simulated route if OSRM fails
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

  // CHỤP ẢNH
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      setState(() {
        deliveryPhoto = File(photo.path);
      });
    }
  }

  // HIỆN DIALOG XÁC NHẬN
  void _showConfirmDialog() {
    // REMOVED: Don't reset deliveryPhoto here - causes photo to disappear!
    // setState(() {
    //   deliveryPhoto = null;
    // });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Xác nhận giao hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // NÚT CHỤP ẢNH
            CustomButton(
              label: deliveryPhoto == null ? 'Chụp ảnh giao hàng' : 'Chụp lại',
              onPressed: () async {
                await _takePhoto();
                if (mounted) Navigator.pop(context);
                _showConfirmDialog(); // Mở lại dialog để hiện ảnh
              },
            ),

            // HIỂN THỊ ẢNH
            if (deliveryPhoto != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(deliveryPhoto!, height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
            ],

            // XÁC NHẬN – CHỈ HIỆN KHI CÓ ẢNH
            if (deliveryPhoto != null)
              CustomButton(
                label: 'Xác nhận giao hàng thành công',
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    currentStep = 3;
                  });
                },
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Vui lòng chụp ảnh để xác nhận', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  final List<String> steps = ['Xuất phát', 'Nhận hàng', 'Đang giao', 'Hoàn tất'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Mã chuyến: ${widget.trip['id']}', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PROGRESS BAR WITH CONNECTORS - Evenly spaced
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (int idx = 0; idx < steps.length; idx++) ...[
                    // Step circle with label
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: idx <= currentStep ? AppColors.primary : Colors.grey[300],
                            child: idx < currentStep
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : Text('${idx + 1}', style: TextStyle(color: idx <= currentStep ? Colors.white : Colors.grey)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            steps[idx],
                            style: TextStyle(
                              fontSize: 11,
                              color: idx <= currentStep ? Colors.black : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Connector line (except after last step)
                    if (idx < steps.length - 1)
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 30, left: 4, right: 4),
                          color: idx < currentStep ? AppColors.primary : Colors.grey[300],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BẢN ĐỒ - Using VietMap (Vietnam)
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
                      // Using OpenStreetMap (works reliably)
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.green_route_app',
                      
                      // VietMap - To enable later when API key is fully activated
                      // Contact VietMap support for correct URL format
                      // Your API Key: 3a141d0814ed5d76db2b40f8b01fbef208d785344fcdc545
                      // Possible formats to try:
                      // - https://maps.vietmap.vn/api/tm/{z}/{x}/{y}.png?apikey=YOUR_KEY
                      // - Contact: support@vietmap.vn or check https://docs.vietmap.vn/
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
                    // Real road routing using OSRM API
                    // Shows actual roads, not straight line
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
                    // Loading indicator while fetching route
                    if (isLoadingRoute)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // HÀNH ĐỘNG
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),

                    if (currentStep == 1) ...[
                      _actionItem('Xác nhận thông tin hàng hóa', 'Loại hàng và khối lượng đúng như mô tả', true),
                      const SizedBox(height: 16),
                      Center(
                        child: CustomButton(
                          label: 'Xác nhận và bắt đầu giao hàng',
                          onPressed: () => setState(() => currentStep = 2),
                        ),
                      ),
                    ] else if (currentStep == 2) ...[
                      CustomButton(label: 'Gọi cho chủ hàng', onPressed: () {}),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _showConfirmDialog, // GỌI DIALOG MỚI
                          child: const Text('Tôi đã đến điểm nhận hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else if (currentStep == 3) ...[
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Colors.green),
                            const SizedBox(height: 16),
                            const Text('Giao hàng thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('Chuyến hàng đã hoàn tất', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _paymentDetail(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: CustomButton(label: 'Tải hóa đơn', onPressed: () {})),
                          const SizedBox(width: 12),
                          Expanded(child: CustomButton(label: 'Hoàn tất', onPressed: () => Navigator.pop(context))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(String title, String subtitle, bool checked) {
    return Row(
      children: [
        Icon(checked ? Icons.check_circle : Icons.radio_button_unchecked, color: checked ? Colors.green : Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentDetail() {
    final tripId = widget.trip['id'];
    final shortId = tripId.length > 20 ? '${tripId.substring(0, 20)}...' : tripId;
    
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Chi tiết thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            // Trip ID row with copy button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mã chuyến:'),
                  Row(
                    children: [
                      Text(shortId, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: tripId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép mã chuyến'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Icon(Icons.copy, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _row('Giá cước:', '3.500.000 đ'),
            _row('Phí sàn (8%):', '-280.000 đ', Colors.red),
            const Divider(),
            _row('Số tiền thực nhận:', '3.220.000 đ', Colors.green, true),
            const SizedBox(height: 8),
            const Text('Tiền sẽ được chuyển vào tài khoản ngân hàng\ndã liên kết trong vòng 24h', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, [Color? color, bool bold = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : null))],
      ),
    );
  }
}