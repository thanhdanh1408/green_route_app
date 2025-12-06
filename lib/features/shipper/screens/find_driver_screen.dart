// lib/features/shipper/screens/find_driver_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../screens/confirm_booking_screen.dart';
import '../widgets/driver_card.dart';

class FindDriverScreen extends StatelessWidget {
  const FindDriverScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> drivers = const [
    {
      'name': 'Nguyễn Văn A',
      'phone': '0987654321',
      'vehicle': 'Xe tải trung',
      'plate': '71A-8977',
      'rating': 4.9,
      'route': 'Gia Lai → Đắk Lắk',
      'price': '3.500.000',
      'departure': '18-11-2025 08:00',
    },
    {
      'name': 'Trần Thị C',
      'phone': '0901234567',
      'vehicle': 'Xe tải 8 tấn',
      'plate': '71B-12345',
      'rating': 4.7,
      'route': 'Pleiku → Quy Nhơn',
      'price': '4.200.000',
      'departure': '19-11-2025 07:00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm tài xế'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm tài xế gần bạn...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: drivers.length,
              itemBuilder: (ctx, i) {
                final driver = drivers[i];
                return DriverCard(
                  data: driver,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConfirmBookingScreen(driver: driver),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}