// lib/features/driver/screens/driver_orders_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../models/order_model.dart';
import '../services/driver_service.dart';
import '../services/order_status_service.dart';
import '../widgets/bid_bottom_sheet.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});
  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  List<OrderModel> allOrders = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    // 1. Load available orders từ DriverService
    final availableOrders = await DriverService().getAvailableOrders();

    // 2. Load stored driver orders (với bidStatus)
    final storedOrders = await OrderStatusService.getAllOrders();

    // 3. Merge: Thay thế available orders bằng stored nếu tồn tại, giữ lại các orders khác
    final mergedOrders = <OrderModel>[];

    // Thêm stored orders trước (với bidStatus khác 'available')
    for (final stored in storedOrders) {
      mergedOrders.add(stored);
    }

    // Thêm available orders (chỉ những cái chưa bid)
    for (final available in availableOrders) {
      if (!storedOrders.any((s) => s.id == available.id)) {
        mergedOrders.add(available.copyWith(bidStatus: 'available'));
      }
    }

    setState(() {
      allOrders = mergedOrders;
    });

    debugPrint('DriverOrdersScreen - Total orders: ${allOrders.length}');
    for (final o in allOrders) {
      debugPrint('  - ${o.id}: ${o.bidStatus}');
    }
  }

  void _handleOrderTap(OrderModel order) {
    if (order.bidStatus == 'available') {
      // Hiển thị BidBottomSheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BidBottomSheet(
          order: order,
          onBidSubmitted: () async {
            await _loadAllData();
          },
        ),
      );
    } else if (order.bidStatus == 'waiting') {
      // Hiển thị chi tiết đơn hàng
      _showOrderDetails(order);
    } else if (order.bidStatus == 'accepted') {
      // Hiển thị thông báo và chuyển sang history
      _showAcceptedNotification(order);
    }
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết đơn hàng'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Mã chuyến:', order.id),
              _detailRow('Tuyến:', '${order.from} → ${order.to}'),
              _detailRow('Chi tiết từ:', order.fromDetail),
              _detailRow('Chi tiết đến:', order.toDetail),
              _detailRow('Khối lượng:', order.weight),
              _detailRow('Giá đề xuất:', order.price),
              _detailRow('Ngày nhận:', order.receiveDate),
              _detailRow('Ngày giao:', order.deliverDate),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Đơn hàng đang chờ phản hồi từ chủ hàng...',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAcceptedNotification(OrderModel order) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Chúc mừng!'),
        content: const Text(
          'Đơn hàng này đã được chủ hàng xác nhận.\nĐơn hàng sẽ được chuyển vào mục "Lịch sử" với trạng thái "Đang vận chuyển".',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Chuyển accepted -> completed (Đang vận chuyển)
              await OrderStatusService.completeOrder(order.id);
              if (mounted) {
                Navigator.pop(context);
                await _loadAllData();
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = allOrders.where((o) => o.bidStatus == 'available').length;
    final waitingCount = allOrders.where((o) => o.bidStatus == 'waiting').length;
    final acceptedCount = allOrders.where((o) => o.bidStatus == 'accepted').length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đơn hàng phù hợp với tuyến của bạn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (allOrders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Khả dụng: $availableCount • Chờ phản hồi: $waitingCount • Chấp nhận: $acceptedCount',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadAllData();
            },
            child: allOrders.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có đơn hàng nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allOrders.length,
                    itemBuilder: (context, index) {
                      final order = allOrders[index];

                      // Xác định status UI
                      String statusText = 'Khả dụng';
                      Color statusBgColor = Colors.blue[100]!;
                      Color statusTextColor = Colors.blue[800]!;
                      String icon = '?';

                      if (order.bidStatus == 'waiting') {
                        statusText = 'Đang chờ phản hồi';
                        statusBgColor = Colors.orange[100]!;
                        statusTextColor = Colors.orange[800]!;
                        icon = '⏳';
                      } else if (order.bidStatus == 'accepted') {
                        statusText = 'Đã chấp nhận';
                        statusBgColor = Colors.green[100]!;
                        statusTextColor = Colors.green[800]!;
                        icon = '✓';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusBgColor,
                              child: Text(
                                icon,
                                style: TextStyle(
                                  color: statusTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${order.from} → ${order.to}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${order.weight} tấn • ${order.price}'),
                            trailing: Chip(
                              backgroundColor: statusBgColor,
                              label: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            onTap: () => _handleOrderTap(order),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    ),
  );
}