// lib/features/shipper/screens/shipper_home_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'find_driver_screen.dart';
import 'match_cargo_screen.dart';
import 'my_orders_screen.dart';
import 'history_screen.dart';
import '../../driver/screens/wallet_screen.dart';
import 'settings_screen.dart';
import 'create_order_screen.dart';

class ShipperHomeScreen extends StatefulWidget {
  const ShipperHomeScreen({super.key});
  @override
  State<ShipperHomeScreen> createState() => _ShipperHomeScreenState();
}

class _ShipperHomeScreenState extends State<ShipperHomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    FindDriverScreen(),     // Tab 0: Tìm tài xế
    MatchCargoScreen(),     // Tab 1: Ghép hàng
    MyOrdersScreen(),       // Tab 2: Đơn hàng
    const HistoryScreen(),  // Tab 3: Lịch sử
    const WalletScreen(),   // Tab 4: Ví tiền
    const SettingsScreen(), // Tab 5: Cài đặt
  ];

  // FAB: ĐĂNG TÌM TÀI XẾ (chờ tài xế nhận)
  Future<void> _showRegisterOrderConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng tìm tài xế', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn muốn đăng đơn để các tài xế gần nhất nhận không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng ngay'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
      );
      if (result == true) {
        setState(() => _selectedIndex = 2); // Chuyển sang Đơn hàng
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showRegisterOrderConfirm, // ← Đăng tìm tài xế (chờ nhận)
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Đăng tìm tài xế',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm tài xế'),
          BottomNavigationBarItem(icon: Icon(Icons.sync_alt), label: 'Ghép hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ví tiền'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}