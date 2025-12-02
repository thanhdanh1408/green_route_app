// lib/features/shipper/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:green_route_app/features/shipper/models/order.dart';
import 'package:green_route_app/features/shipper/services/shipper_service.dart';
import '../../../core/theme/app_theme.dart';

// history_screen.dart
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final orders = ShipperService.instance.historyOrders;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: orders.isEmpty
          ? const Center(child: Text('Chưa có lịch sử'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];
                return Card(
                  color: o.status == OrderStatus.completed ? Colors.green[50] : Colors.red[50],
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: o.status == OrderStatus.completed ? Colors.green : Colors.red, child: Icon(o.status == OrderStatus.completed ? Icons.check : Icons.close)),
                    title: Text('${o.from} → ${o.to}'),
                    subtitle: Text('Hoàn thành lúc: ${o.postedAt.day}/${o.postedAt.month}'),
                    trailing: Text(o.price, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
    );
  }
}