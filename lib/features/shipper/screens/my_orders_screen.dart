// lib/features/shipper/screens/my_orders_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/order_pool_service.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  void _showOrderResult(BuildContext context, PooledOrder order) {
    if (order.hasSeenResult) return;

    OrderPoolService.instance.markAsSeen(order.id);

    if (order.status == OrderStatus.accepted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text('Đặt xe thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Tài xế ${order.shipperName} đã chấp nhận đơn của bạn'),
              Text('Tổng chi phí: ${order.proposedPrice}đ'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Theo dõi')),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Quay về đơn hàng'), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (order.status == OrderStatus.rejected) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 80),
              const SizedBox(height: 16),
              const Text('Yêu cầu đặt xe bị từ chối', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              const Text('Rất tiếc, tài xế không nhận đơn này'),
              const Text('Vui lòng thử điều chỉnh giá hoặc tìm tài xế khác'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Điều chỉnh giá')),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Tìm tài xế khác'), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PooledOrder>>(
      valueListenable: OrderPoolService.instance.ordersNotifier,
      builder: (context, orders, _) {
        if (orders.isEmpty) {
          return const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 18, color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (_, i) {
            final o = orders[i];
            final isMatching = o.type == OrderType.matching;
            final status = o.status;

            return Card(
              child: ListTile(
                onTap: () => _showOrderResult(context, o),
                leading: CircleAvatar(
                  backgroundColor: isMatching ? Colors.purple : AppColors.primary,
                  child: Text(isMatching ? 'GH' : 'TX', style: const TextStyle(color: Colors.white)),
                ),
                title: Text('${o.from} → ${o.to}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${o.goods} • ${o.weight} tấn'),
                trailing: Chip(
                  backgroundColor: status == OrderStatus.pending
                      ? Colors.orange[100]
                      : status == OrderStatus.accepted
                          ? Colors.green[100]
                          : Colors.red[100],
                  label: Text(
                    status == OrderStatus.pending
                        ? 'Đang xử lý'
                        : status == OrderStatus.accepted
                            ? 'Đang giao'
                            : 'Bị từ chối',
                    style: TextStyle(color: status == OrderStatus.pending ? Colors.orange[800] : status == OrderStatus.accepted ? Colors.green[800] : Colors.red[800]),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}