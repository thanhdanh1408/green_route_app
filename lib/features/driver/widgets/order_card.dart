import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusText = _getStatusText(order.bidStatus);
    final statusColor = _getStatusColor(order.bidStatus);
    final icon = _getStatusIcon(order.bidStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                child: Text(icon, style: TextStyle(color: statusColor, fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.from} → ${order.to}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('${order.goods} • ${order.weight} tấn', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Chip(
                label: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                backgroundColor: statusColor.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'accepted':
        return 'Đang giao';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Khả dụng';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'accepted':
        return '🚚';
      case 'completed':
        return '✓';
      default:
        return '💡';
    }
  }
}
