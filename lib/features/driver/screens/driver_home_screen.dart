// lib/features/driver/screens/driver_home_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../screens/driver_route_selection_screen.dart';
import '../screens/driver_orders_screen.dart';
import '../screens/pairing_screen.dart';
import '../screens/history_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/settings_screen.dart';


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

  // CÁC TRANG TƯƠNG ỨNG VỚI TỪNG TAB – ĐÃ THÊM PairingScreen()
  late final List<Widget> _pages = [
    _hasRoute
        ? const DriverOrdersScreen()
        : const DriverRouteSelectionScreen(),
    const PairingScreen(), 
    const HistoryScreen(),
    const WalletScreen(),
    const SettingsScreen(),
    const Center(child: Text('Ví tiền & thanh toán', style: AppTextStyle.headline2)),
    const Center(child: Text('Cài đặt tài khoản', style: AppTextStyle.headline2)),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Nếu chưa có tuyến mà bấm tab khác → vẫn bắt chọn tuyến trước
          if (!_hasRoute && index != 0) {
            setState(() => _currentIndex = 0);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vui lòng chọn tuyến hoạt động trước!')),
            );
          }
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