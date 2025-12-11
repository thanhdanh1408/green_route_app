// lib/features/driver/screens/available_orders_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/order_pool_service.dart';
import '../../driver/services/order_status_service.dart';

class DriverAvailableOrdersScreen extends StatelessWidget {
  const DriverAvailableOrdersScreen({super.key});

  void _showBidDialog(BuildContext context, PooledOrder order) {
    final priceController = TextEditingController(text: order.proposedPrice);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gửi giá đấu thầu', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Đơn hàng: ${order.from} → ${order.to}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Chủ hàng: ${order.shipperName}'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá bạn muốn đấu thầu (VNĐ)',
                prefixIcon: Icon(Icons.local_offer),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final bidPrice = priceController.text;
              if (bidPrice.isEmpty) return;

              // Gọi service để gửi bid
              await OrderStatusService.driverSendBid(order, bidPrice);

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã gửi giá thầu ${bidPrice}đ cho chủ hàng'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

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
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Left side: Icon and Order Info
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: o.type == OrderType.matching ? Colors.purple : AppColors.primary,
                          child: Text(
                            o.type == OrderType.matching ? 'GHÉP' : 'TÌM',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Center: Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${o.from} → ${o.to}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${o.goods} • ${o.weight} tấn', style: TextStyle(color: Colors.grey[700])),
                              const SizedBox(height: 4),
                              Text('Chủ hàng: ${o.shipperName}', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                              const SizedBox(height: 8),
                              Text(
                                'Giá đề xuất: ${o.proposedPrice}đ',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right side: Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () => _showBidDialog(context, o),
                          child: const Text('Đấu thầu'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
