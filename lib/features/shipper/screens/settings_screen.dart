// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:green_route_app/core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _infoCard('Thông tin cá nhân', ['Tên doanh nghiệp: ABC', 'SĐT: 0987654321', 'Địa chỉ: Quy Nhơn Bình Định']),
        const SizedBox(height: 16),
        _infoCard('Tài khoản ngân hàng', ['Số tài khoản: 123xxxxxxx', 'Ngân hàng: Vietcombank', 'Tên: Trần C']),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () async {
            await AuthService.instance.logout();
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ]),
    );
  }
  Widget _infoCard(String title, List<String> items) => Card(child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: items.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(e))).toList())));
}
