// lib/features/driver/screens/driver_home_screen.dart
import 'package:flutter/material.dart';
import 'package:green_route_app/features/driver/screens/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/widgets/chatbot_fab.dart';
import 'driver_route_selection_screen.dart';
import 'driver_orders_screen.dart';
import 'driver_empty_trips_screen.dart';

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
    final userId = prefs.getString('user_phone') ?? '';
    
    // Check global keys first (for fresh login without logout history)
    var hasRoute = prefs.getBool('driver_has_route') ?? false;
    
    // If not found in global keys, check user-specific keys (for after logout/login)
    if (!hasRoute && userId.isNotEmpty) {
      hasRoute = prefs.getBool('driver_has_route_$userId') ?? false;
      final routeFrom = prefs.getString('driver_route_from_$userId') ?? '';
      final routeTo = prefs.getString('driver_route_to_$userId') ?? '';
      final routeWeight = prefs.getString('driver_route_weight_$userId') ?? '';
      final routeTimeRange = prefs.getString('driver_route_time_range_$userId') ?? '';
      
      // 🔒 If found in user-specific keys, restore to global keys for this session
      if (hasRoute) {
        await prefs.setBool('driver_has_route', true);
        if (routeFrom.isNotEmpty) await prefs.setString('driver_route_from', routeFrom);
        if (routeTo.isNotEmpty) await prefs.setString('driver_route_to', routeTo);
        if (routeWeight.isNotEmpty) await prefs.setString('driver_route_weight', routeWeight);
        if (routeTimeRange.isNotEmpty) await prefs.setString('driver_route_time_range', routeTimeRange);
        debugPrint('✅ Route restored from user-specific keys: $routeFrom → $routeTo');
      }
    }

    setState(() {
      _hasRoute = hasRoute;
      _isLoading = false;
    });
  }

  // CÁC TRANG CHÍNH – Sử dụng getter để rebuild khi _hasRoute thay đổi
  List<Widget> get _pages => [
    // Tab 0: Đơn hàng (nếu đã chọn tuyến) hoặc Chọn tuyến
    _hasRoute ? const DriverOrdersScreen() : DriverRouteSelectionScreen(
      onRouteSelected: () {
        // Sau khi chọn tuyến xong, reload lại
        _checkRouteStatus();
      },
    ),

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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: Stack(
        children: [
          // Chatbot button (luôn ở góc phải dưới)
          Positioned(
            bottom: 16,
            right: 16,
            child: ChatbotFAB(),
          ),
        ],
      ),

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

// 🔒 Helper widget để hiển thị thông tin tuyến đường
class _RouteInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RouteInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}