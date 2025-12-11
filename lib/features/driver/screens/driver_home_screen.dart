// lib/features/driver/screens/driver_home_screen.dart
import 'package:flutter/material.dart';
import 'package:green_route_app/features/driver/screens/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import 'driver_route_selection_screen.dart';
import 'driver_orders_screen.dart';
import 'driver_empty_trips_screen.dart';
import 'create_empty_trip_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;
  bool _hasRoute = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRouteStatus();
  }

  Future<void> _checkRouteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRoute = prefs.getBool('driver_has_route') ?? false;

    setState(() {
      _hasRoute = hasRoute;
      _isLoading = false;
    });
  }

  // CÁC TRANG CHÍNH – ĐÃ CẬP NHẬT ĐÚNG THỨ TỰ
  late final List<Widget> _pages = [
    // Tab 0: Đơn hàng (nếu đã chọn tuyến) hoặc Chọn tuyến
    _hasRoute ? const DriverOrdersScreen() : const DriverRouteSelectionScreen(),

    // Tab 1: Ghép hàng → CHUYẾN CỦA TÀI XẾ
    DriverEmptyTripsScreen(
      onNeedHistoryTab: () {
        setState(() {
          _currentIndex = 2; // Switch to History tab
        });
      },
    ),

    // Tab 2: Lịch sử
    const HistoryScreen(),

    // Tab 3: Ví tiền
    const WalletScreen(),

    // Tab 4: Cài đặt
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      floatingActionButton: _currentIndex == 1 // Chỉ hiện ở tab Ghép hàng
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEmptyTripScreen()),
                );
              },
              tooltip: 'Tạo chuyến ghép hàng',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          // Nếu chưa chọn tuyến → chỉ được ở tab 0
          if (!_hasRoute && index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vui lòng chọn tuyến hoạt động trước!')),
            );
            return;
          }

          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.handshake), label: 'Ghép hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ví tiền'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}