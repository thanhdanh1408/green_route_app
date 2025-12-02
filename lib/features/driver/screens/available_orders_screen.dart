// lib/features/driver/screens/available_orders_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/order_pool_service.dart';

class DriverAvailableOrdersScreen extends StatelessWidget {
  const DriverAvailableOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = OrderPoolService.instance.availableOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng đang chờ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: o.type == OrderType.matching ? Colors.purple : AppColors.primary,
                      child: Text(o.type == OrderType.matching ? 'GHÉP' : 'TÌM', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    title: Text('${o.from} → ${o.to}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${o.goods} • ${o.weight} tấn'),
                        Text('Chủ hàng: ${o.shipperName}'),
                        Text('Giá đề xuất: ${o.proposedPrice}đ'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã gửi giá thầu cho đơn ${o.id.substring(0, 8)}')),
                        );
                      },
                      child: const Text('Đấu thầu', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}