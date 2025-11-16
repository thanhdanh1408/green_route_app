// lib/features/driver/screens/trip_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết chuyến #${trip['id']}')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress steps
            _buildProgress(),
            const SizedBox(height: 20),
            // Map
            Container(height: 200, color: Colors.grey[300], child: Center(child: Text('Bản đồ Google Maps'))),
            const SizedBox(height: 20),
            // Thông tin
            _infoCard('Vị trí thời gian thực', 'Xe đang di chuyển trên QL14'),
            _infoCard('Thời gian dự kiến', '4 giờ 20 phút'),
            const SizedBox(height: 20),
            CustomButton(label: 'Gọi cho chủ hàng', onPressed: () {}),
            CustomButton(label: 'Tôi đã đến điểm nhận hàng', onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.info_outline, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _step('Xuất phát', true),
          _step('Nhận hàng', true),
          _step('Đang giao', true),
          _step('Hoàn tất', false),
        ],
      ),
    );
  }

  Widget _step(String label, bool done) {
    return Column(
      children: [
        CircleAvatar(radius: 20, backgroundColor: done ? Colors.green : Colors.grey, child: Icon(done ? Icons.check : Icons.access_time, color: Colors.white)),
        Text(label),
      ],
    );
  }
}