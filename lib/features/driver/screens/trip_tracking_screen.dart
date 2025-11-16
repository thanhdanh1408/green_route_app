// lib/features/driver/screens/trip_tracking_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  void initState() {
    super.initState();
    currentStep = widget.trip['progress'];
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
    setState(() {
      deliveryPhoto = null; // Reset ảnh
    });

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
            // PROGRESS BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: steps.asMap().entries.map((e) {
                int idx = e.key;
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: idx <= currentStep ? AppColors.primary : Colors.grey[300],
                      child: idx < currentStep
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text('${idx + 1}', style: TextStyle(color: idx <= currentStep ? Colors.white : Colors.grey)),
                    ),
                    const SizedBox(height: 8),
                    Text(e.value, style: TextStyle(fontSize: 12, color: idx <= currentStep ? Colors.black : Colors.grey)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

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
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            const LatLng(13.9833, 108.0000),
                            const LatLng(12.6667, 108.0500),
                          ],
                          color: AppColors.primary,
                          strokeWidth: 5,
                        ),
                      ],
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
                      Center(child: Icon(Icons.check_circle, size: 64, color: Colors.green)),
                      const SizedBox(height: 16),
                      const Text('Giao hàng thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text('Chuyến hàng đã hoàn tất', style: TextStyle(color: Colors.grey)),
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
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Chi tiết thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            _row('Mã chuyến:', widget.trip['id']),
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