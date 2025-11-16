// lib/features/driver/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  final List<Map<String, dynamic>> transactions = const [
    {'id': 'GH999', 'route': 'Gia Lai - Đắk Lắk', 'date': '03-11-2025', 'amount': '+3.500.000 đ', 'color': Colors.green},
    {'id': 'GH998', 'route': 'Gia Lai - Đắk Lắk', 'date': '02-11-2025', 'amount': '+2.500.000 đ', 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Ví tiền', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SỐ DƯ
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Tổng thu nhập', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.green[700], size: 32),
                        const SizedBox(width: 12),
                        const Text('5.560.000 đ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CHỜ THANH TOÁN
            _statusCard('Chờ thanh toán', '0 đ', Icons.access_time, Colors.orange),
            const SizedBox(height: 12),

            // ĐÃ RÚT
            _statusCard('Đã rút', '5.457.000 đ', Icons.check_circle, Colors.green),
            const SizedBox(height: 24),

            // LỊCH SỬ GIAO DỊCH
            const Align(alignment: Alignment.centerLeft, child: Text('Lịch sử giao dịch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 12),
            ...transactions.map((t) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.directions_car, color: t['color']),
                    title: Text(t['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(t['route']),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(t['amount'], style: TextStyle(color: t['color'], fontWeight: FontWeight.bold)),
                        Text(t['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(String title, String amount, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}