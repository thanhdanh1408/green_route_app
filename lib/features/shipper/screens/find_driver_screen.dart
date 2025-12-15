// lib/features/shipper/screens/find_driver_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/verification_status_banner.dart';
import '../screens/confirm_booking_screen.dart';
import '../screens/edit_profile_screen.dart';

import '../widgets/driver_card.dart';

class FindDriverScreen extends StatefulWidget {
  const FindDriverScreen({Key? key}) : super(key: key);

  @override
  State<FindDriverScreen> createState() => _FindDriverScreenState();
}

class _FindDriverScreenState extends State<FindDriverScreen> {
  String _userId = '';
  List<Map<String, dynamic>> drivers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_phone') ?? '';
    
    // 🚗 Driver Nguyễn Văn Nam có tuyến cố định: Đà Nẵng → Khánh Hòa
    // Trong thực tế, dữ liệu này sẽ đến từ database của driver
    if (mounted) {
      setState(() {
        _userId = userId;
        drivers = [
          {
            'name': 'Nguyễn Văn Nam',
            'phone': '0987654321',
            'vehicle': 'Xe tải 5 tấn',
            'plate': '81C-12345',
            'rating': 4.8,
            'route': 'Đà Nẵng → Khánh Hòa',
            'fromAddress': 'Đà Nẵng',
            'toAddress': 'Khánh Hòa',
            'price': '3.200.000',
            'departure': '18-11-2025 08:00',
          },
        ];
      });
      debugPrint('✅ Loaded drivers: fromAddress=${drivers[0]['fromAddress']}, toAddress=${drivers[0]['toAddress']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm tài xế'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Verification status banner
          if (_userId.isNotEmpty)
            VerificationStatusBanner(
              userId: _userId,
              userType: 'shipper',
              onTapEditProfile: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) => _loadData());
              },
            ),
          
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