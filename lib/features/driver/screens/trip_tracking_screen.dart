// lib/features/driver/screens/trip_tracking_screen.dart
import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/services/mapbox_routing_service.dart';
import '../services/order_status_service.dart';
import '../services/empty_trip_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  
  // Fetch real route from Mapbox Directions API
  Future<void> _fetchRoute() async {
    // Get coordinates from trip data, or use defaults
    final start = widget.trip['fromLatLng'] as LatLng? ?? const LatLng(16.0544, 108.2022);
    final end = widget.trip['toLatLng'] as LatLng? ?? const LatLng(11.9333, 109.1833);

    try {
      debugPrint('🗺️ [Mapbox] Fetching route from Mapbox...');
      
      // Try Mapbox first
      final points = await MapboxRoutingService.getRoute(start, end);
      
      if (!mounted) return;
      setState(() {
        routePoints = points;
        isLoadingRoute = false;
      });

      debugPrint('✅ [Mapbox] Route loaded successfully with ${points.length} points');
      return; // Success!
    } catch (e) {
      debugPrint('❌ [Mapbox] Error: $e');
      debugPrint('→ Falling back to simulated route...');
      _useFallbackRoute(start, end);
    }
  }

  // Fallback to simulated route if Mapbox fails
  void _useFallbackRoute(LatLng start, LatLng end) {
    if (!mounted) return;
    
    // Create a more realistic fallback route with multiple waypoints
    // instead of just a straight line
    List<LatLng> fallbackPoints = [start];
    
    // Add intermediate waypoints to simulate a realistic route
    final numWaypoints = 5;
    for (int i = 1; i < numWaypoints; i++) {
      final fraction = i / numWaypoints;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng = start.longitude + (end.longitude - start.longitude) * fraction;
      
      // Add slight random variation to make it less like a straight line
      // (simulating road curves)
      fallbackPoints.add(LatLng(lat, lng));
    }
    fallbackPoints.add(end);
    
    setState(() {
      routePoints = fallbackPoints;
      isLoadingRoute = false;
    });
    debugPrint('⚠️ Using fallback route (simulated with ${fallbackPoints.length} waypoints)');
    debugPrint('   Note: This is a straight-line approximation. Real routing service is unavailable.');
  }

  // BUILD MAP WITH DYNAMIC MARKERS AND ROUTE
  Widget _buildMapWidget() {
    final start = widget.trip['fromLatLng'] as LatLng? ?? const LatLng(13.9833, 108.0000);
    final end = widget.trip['toLatLng'] as LatLng? ?? const LatLng(12.6667, 108.0500);
    
    // Calculate initial center and zoom level based on route
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
        
        // Route polyline (if available)
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
        
        // Start and End markers with dynamic coordinates
        MarkerLayer(
          markers: [
            // START MARKER (Green)
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
            
            // END MARKER (Red)
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
                    
                    // ✨ TỰ ĐỘNG CỘNG/TRỪ TIỀN VÀO VÍ CỦA DRIVER VÀ SHIPPER
                    final prefs = await SharedPreferences.getInstance();
                    final driverId = prefs.getString('user_phone') ?? '';
                    final priceStr = widget.trip['price'] as String?;
                    
                    if (priceStr != null && driverId.isNotEmpty) {
                      // Parse price: "3.500.000 đ" -> 3500000
                      final amount = double.tryParse(
                        priceStr.replaceAll('.', '').replaceAll(' đ', '').replaceAll(',', '')
                      ) ?? 0;
                      
                      if (amount > 0) {
                        // Tính phí sàn 8% cho Green Route
                        final platformFee = (amount * 0.08).toDouble();
                        final driverEarnings = amount - platformFee;
                        
                        // Cộng tiền cho driver (sau khi trừ phí)
                        await WalletService.addTripEarnings(driverId, driverEarnings, tripId);
                        debugPrint('💰 Driver: Added ${WalletService.formatCurrency(driverEarnings)} to wallet (after 8% fee)');
                        
                        // Cộng/Trừ tiền cho shipper
                        if (tripType == 'consolidated') {
                          // Đơn ghép: Cộng tiền cho mỗi shipper (giá họ thanh toán)
                          final joinedShippersRaw = widget.trip['joinedShippers'] as List?;
                          if (joinedShippersRaw != null && joinedShippersRaw.isNotEmpty) {
                            for (var shippers in joinedShippersRaw) {
                              try {
                                final shipperData = shippers as Map<String, dynamic>;
                                final shipperPhone = shipperData['phone'] ?? '';
                                final shipperPrice = shipperData['price'] ?? '';
                                
                                if (shipperPhone.isNotEmpty && shipperPrice.isNotEmpty) {
                                  // Parse shipper price: "500.000 đ" -> 500000
                                  final shipperAmount = double.tryParse(
                                    shipperPrice.replaceAll('.', '').replaceAll(' đ', '').replaceAll(',', '')
                                  ) ?? 0;
                                  
                                  if (shipperAmount > 0) {
                                    // Shipper thanh toán cho driver = trừ tiền ví shipper
                                    await WalletService.deductOrderPayment(shipperPhone, shipperAmount, tripId);
                                    debugPrint('💰 Shipper: Deducted ${WalletService.formatCurrency(shipperAmount)} from $shipperPhone');
                                  }
                                }
                              } catch (e) {
                                debugPrint('⚠️ Error processing shipper payment: $e');
                              }
                            }
                          }
                        } else {
                          // Đơn thường: Trừ tiền từ shipper (thanh toán cho driver)
                          final shipperId = widget.trip['shipperId'] as String?;
                          if (shipperId != null && shipperId.isNotEmpty) {
                            await WalletService.deductOrderPayment(shipperId, amount, tripId);
                            debugPrint('💰 Shipper: Deducted ${WalletService.formatCurrency(amount)} from $shipperId');
                          }
                        }
                      }
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

  // Cancel order dialog
  void _showCancelDialog() {
    String? selectedReason;
    final TextEditingController otherReasonController = TextEditingController();

    final List<String> cancelReasons = [
      'Shipper yêu cầu hủy',
      'Xe gặp sự cố',
      'Thời tiết xấu, không thể vận chuyển',
      'Hàng hóa không đúng mô tả',
      'Không liên lạc được với chủ hàng',
      'Lý do khác',
    ];

    showDialog(
      context: context,
      builder: (outerContext) => StatefulBuilder(
        builder: (innerContext, setState) => AlertDialog(
          title: const Text('Yêu cầu hủy đơn hàng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vui lòng chọn lý do hủy đơn hàng:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                ...cancelReasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
                if (selectedReason == 'Lý do khác') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otherReasonController,
                    decoration: InputDecoration(
                      labelText: 'Nhập lý do cụ thể',
                      hintText: 'Mô tả chi tiết lý do hủy...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yêu cầu hủy sẽ được gửi đến Admin để xem xét và phê duyệt.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(outerContext),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedReason == null) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng chọn lý do hủy!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (selectedReason == 'Lý do khác' && otherReasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập lý do cụ thể!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final finalReason = selectedReason == 'Lý do khác'
                    ? otherReasonController.text.trim()
                    : selectedReason!;

                // Close dialog first
                Navigator.pop(outerContext);

                // Show loading overlay
                showDialog(
                  context: outerContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final tripType = widget.trip['tripType'] ?? 'regular';
                  final tripId = widget.trip['id'];
                  
                  if (tripType == 'consolidated') {
                    // Consolidated order cancellation
                    await EmptyTripService.requestCancelTrip(
                      tripId: tripId,
                      reason: finalReason,
                    );
                    // Update trip status to failed
                    await EmptyTripService.updateTripStatus(tripId, 'failed');
                  } else {
                    // Regular order cancellation
                    await OrderStatusService.requestCancelOrder(
                      orderId: tripId,
                      reason: finalReason,
                    );
                    // Update order status to failed
                    await OrderStatusService.updateOrderStatus(tripId, 'failed');
                  }

                  if (!mounted) return;
                  
                  // Pop loading
                  Navigator.pop(outerContext);
                  // Go back to history
                  Navigator.pop(outerContext);

                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Yêu cầu hủy đơn đã được gửi! Chờ Admin phê duyệt.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  
                  // Pop loading
                  Navigator.pop(outerContext);
                  
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    SnackBar(
                      content: Text('❌ Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Gửi yêu cầu hủy'),
            ),
          ],
        ),
      ),
    );
  }

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

            // BẢN ĐỒ - Hiển thị route thực từ OSRM
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

                    // CANCEL ORDER BUTTON - Available for all steps except completed
                    if (currentStep < 3) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showCancelDialog,
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          label: const Text('Yêu cầu hủy đơn hàng', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],

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