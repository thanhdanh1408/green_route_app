// lib/features/driver/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'trip_tracking_screen.dart'; // MỚI

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  final List<Map<String, dynamic>> trips = const [
    {
      'id': 'GH999',
      'route': 'Gia Lai - Đắk Lắk',
      'cargo': 'Cà phê - 5 tấn',
      'date': '03-11-2025',
      'status': 'Hoàn thành',
      'statusColor': Colors.green,
      'price': '3.500.000 đ',
      'progress': 4,
    },
    {
      'id': 'GH998',
      'route': 'Gia Lai - Đắk Lắk',
      'cargo': 'Tiêu xanh - 5 tấn',
      'date': '02-11-2025',
      'status': 'Đang vận chuyển',
      'statusColor': Colors.orange,
      'price': '2.500.000 đ',
      'progress': 2,
    },
    {
      'id': 'GH997',
      'route': 'Gia Lai - Đắk Lắk',
      'cargo': 'Hàng hóa',
      'date': '02-11-2025',
      'status': 'Thất bại',
      'statusColor': Colors.red,
      'price': '2.500.000 đ',
      'progress': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Lịch sử chuyến', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Danh sách các chuyến đã hoàn thành', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: trips.length,
              itemBuilder: (context, i) {
                final trip = trips[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripTrackingScreen(trip: trip),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(trip['id'][3], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(trip['route'], style: AppTextStyle.headline2.copyWith(fontWeight: FontWeight.bold)),
                                    Text(trip['cargo'], style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: trip['statusColor'] == Colors.green
                                      ? Colors.green[100]
                                      : trip['statusColor'] == Colors.orange
                                          ? Colors.orange[100]
                                          : Colors.red[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  trip['status'],
                                  style: TextStyle(
                                    color: trip['statusColor'] == Colors.green
                                        ? Colors.green[800]
                                        : trip['statusColor'] == Colors.orange
                                            ? Colors.orange[800]
                                            : Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Ngày hoàn thành: ${trip['date']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Thu nhập: ${trip['price']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}