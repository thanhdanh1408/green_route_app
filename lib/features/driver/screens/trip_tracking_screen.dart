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
import '../services/order_status_service.dart';
import '../services/empty_trip_service.dart';

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

  
  // Fetch real route from OSRM with retry and multiple servers
  Future<void> _fetchRoute() async {
    // Lấy coordinates thực từ trip data
    final start = widget.trip['fromLatLng'] as LatLng? ?? const LatLng(13.9833, 108.0000);
    final end = widget.trip['toLatLng'] as LatLng? ?? const LatLng(12.6667, 108.0500);

    // Multiple OSRM servers for fallback
    final osrmServers = [
      'https://router.project-osrm.org',  // Primary (HTTPS)
      'http://router.project-osrm.org',   // HTTP fallback
      'https://routing.openstreetmap.de', // European backup
    ];

    debugPrint('🗺️ Fetching route from ${start.latitude},${start.longitude} to ${end.latitude},${end.longitude}');

    for (var i = 0; i < osrmServers.length; i++) {
      try {
        final server = osrmServers[i];
        final url = '$server/route/v1/driving/'
            '${start.longitude},${start.latitude};'
            '${end.longitude},${end.latitude}'
            '?overview=full&geometries=geojson';

        debugPrint('  🔄 Trying server ${i + 1}/${osrmServers.length}: $server');
        
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('  ⏱️ Timeout on server ${i + 1}');
            throw Exception('Timeout');
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final coords = data['routes'][0]['geometry']['coordinates'] as List;

          if (!mounted) return;
          setState(() {
            routePoints = coords.map((coord) => LatLng(coord[1], coord[0])).toList();
            isLoadingRoute = false;
          });

          debugPrint('✅ Loaded real route with ${routePoints.length} points from server ${i + 1}');
          return; // Success! Exit
        } else {
          debugPrint('  ⚠️ Server ${i + 1} returned status ${response.statusCode}');
          if (i < osrmServers.length - 1) {
            debugPrint('  → Trying next server...');
            continue; // Try next server
          }
        }
      } catch (e) {
        debugPrint('  ❌ Error with server ${i + 1}: $e');
        if (i < osrmServers.length - 1) {
          debugPrint('  → Trying next server...');
          continue; // Try next server
        }
      }
    }

    // All servers failed
    debugPrint('❌ All OSRM servers failed, using fallback route');
    _useFallbackRoute(start, end);
  }

  // Fallback to simulated route if OSRM fails
  void _useFallbackRoute(LatLng start, LatLng end) {
    if (!mounted) return; // FIX: Check mounted trước khi setState
    
    // Tạo route đơn giản bằng cách nội suy giữa start và end
    setState(() {
      routePoints = [
        start,
        LatLng((start.latitude + end.latitude) / 2, (start.longitude + end.longitude) / 2),
        end,
      ];
      isLoadingRoute = false;
    });
    debugPrint('⚠️ Using fallback route (straight line)');
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
                onPressed: () async {
                  Navigator.pop(context);
                  
                  // LƯU TRẠNG THÁI HOÀN THÀNH VÀO DATABASE
                  final tripType = widget.trip['tripType'];
                  final tripId = widget.trip['id'];
                  
                  try {
                    if (tripType == 'consolidated') {
                      // Đơn ghép - cập nhật EmptyTrip
                      await EmptyTripService.completeTrip(tripId);
                      debugPrint('✅ Completed consolidated trip: $tripId');
                    } else {
                      // Đơn thường - cập nhật Order
                      await OrderStatusService.completeOrder(tripId);
                      debugPrint('✅ Completed regular order: $tripId');
                    }
                    
                    // Cập nhật UI
                    if (mounted) {
                      setState(() {
                        currentStep = 3;
                      });
                      
                      // Hiển thị thông báo thành công
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã hoàn thành chuyến hàng!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      // BỎ AUTO-NAVIGATE để user xem payment detail và tự back
                    }
                  } catch (e) {
                    debugPrint('❌ Error completing trip: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi khi hoàn thành: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
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

            // THÔNG TIN CHI TIẾT CHUYẾN HÀNG
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

                    // Kiểm tra loại đơn
                    if (widget.trip['tripType'] == 'consolidated') ...[
                      // ĐƠN GHÉP - Hiển thị danh sách nhiều shipper
                      _infoRow('Loại chuyến:', 'Đơn ghép', icon: Icons.layers, color: Colors.orange),
                      _infoRow('Loại xe:', widget.trip['containerType'] ?? 'N/A', icon: Icons.local_shipping),
                      _infoRow('Tải trọng:', widget.trip['capacity'] ?? 'N/A', icon: Icons.scale),
                      const SizedBox(height: 12),
                      const Text('Danh sách chủ hàng:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...((widget.trip['joinedShippers'] as List?) ?? []).asMap().entries.map((entry) {
                        final index = entry.key;
                        final shipper = entry.value as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary,
                                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(shipper['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(shipper['phone'] ?? 'N/A', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: Colors.green),
                                    onPressed: () {
                                      // TODO: Implement phone call
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              _smallInfoRow('Loại hàng:', shipper['cargoType'] ?? 'N/A'),
                              _smallInfoRow('Khối lượng:', '${shipper['weight']} tấn'),
                              _smallInfoRow('Giá:', shipper['price'] ?? 'N/A'),
                              if ((shipper['fromDetail'] ?? '').isNotEmpty)
                                _smallInfoRow('Điểm nhận:', shipper['fromDetail']),
                              if ((shipper['toDetail'] ?? '').isNotEmpty)
                                _smallInfoRow('Điểm giao:', shipper['toDetail']),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      // ĐƠN THƯỜNG - Một shipper
                      _infoRow('Loại chuyến:', 'Đơn thường', icon: Icons.assignment, color: Colors.blue),
                      const SizedBox(height: 12),
                      const Text('Thông tin hàng hóa:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      _infoRow('Loại hàng:', widget.trip['goods'] ?? 'N/A', icon: Icons.inventory_2),
                      _infoRow('Khối lượng:', widget.trip['weight'] ?? 'N/A', icon: Icons.scale),
                      const Divider(height: 24),
                      const Text('Thông tin chủ hàng:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow('Tên:', widget.trip['shipperName'] ?? 'N/A', icon: Icons.person),
                                _infoRow('SĐT:', widget.trip['shipperPhone'] ?? 'N/A', icon: Icons.phone_android),
                              ],
                            ),
                          ),
                          if ((widget.trip['shipperPhone'] ?? '').isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Implement phone call
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
                      if ((widget.trip['fromDetail'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _infoRow('Điểm nhận:', widget.trip['fromDetail'] ?? 'N/A', icon: Icons.location_on),
                      ],
                      if ((widget.trip['toDetail'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _infoRow('Điểm giao:', widget.trip['toDetail'] ?? 'N/A', icon: Icons.flag),
                      ],
                    ],
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
    
    // Lấy giá thực tế từ trip data
    final priceString = widget.trip['price'] ?? '0';
    // Remove any formatting characters (commas, spaces, đ, etc.)
    final cleanPrice = priceString.toString().replaceAll(RegExp(r'[^\d]'), '');
    final totalPrice = int.tryParse(cleanPrice) ?? 0;
    
    // Tính phí sàn 8%
    final platformFee = (totalPrice * 0.08).round();
    final netAmount = totalPrice - platformFee;
    
    // Format numbers with thousands separator
    String formatCurrency(int amount) {
      return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    }
    
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
            _row('Giá cước:', '${formatCurrency(totalPrice)} đ'),
            _row('Phí sàn (8%):', '-${formatCurrency(platformFee)} đ', Colors.red),
            const Divider(),
            _row('Số tiền thực nhận:', '${formatCurrency(netAmount)} đ', Colors.green, true),
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

  Widget _smallInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}