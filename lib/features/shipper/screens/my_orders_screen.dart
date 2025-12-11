// lib/features/shipper/screens/my_orders_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/order_pool_service.dart';
import '../../driver/services/order_status_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Map<String, dynamic>> driverBids = [];

  @override
  void initState() {
    super.initState();
    _loadDriverBids();
  }

  Future<void> _loadDriverBids() async {
    final bids = await OrderStatusService.getShipperBids();
    if (mounted) {
      setState(() {
        driverBids = bids;
      });
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của chủ hàng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Tabs
            TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.list_alt),
                    const SizedBox(width: 8),
                    const Text('Đơn hàng'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people),
                    const SizedBox(width: 8),
                    const Text('Bids từ tài xế'),
                    if (driverBids.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${driverBids.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Đơn hàng của tôi
                _buildOrdersTab(),
                // Tab 2: Bids từ tài xế
                _buildBidsTab(),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }

  Widget _buildOrdersTab() {
    return ValueListenableBuilder<List<PooledOrder>>(
      valueListenable: OrderPoolService.instance.ordersNotifier,
      builder: (context, orders, _) {
        // Lọc ra các đơn hàng chưa hoàn thành và chưa accepted để hiển thị
        final activeOrders = orders
            .where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.accepted)
            .toList();

        if (activeOrders.isEmpty) {
          return const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 18, color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: activeOrders.length,
          itemBuilder: (_, i) {
            final o = activeOrders[i];
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
                      : status == OrderStatus.accepted || status == OrderStatus.delivering
                          ? Colors.green[100]
                          : status == OrderStatus.completed
                              ? Colors.grey[300]
                              : Colors.red[100],
                  label: Text(
                    status == OrderStatus.pending
                        ? 'Đang xử lý'
                        : status == OrderStatus.accepted || status == OrderStatus.delivering
                            ? 'Đang giao'
                            : status == OrderStatus.completed
                                ? 'Hoàn thành'
                                : 'Bị từ chối',
                    style: TextStyle(color: status == OrderStatus.pending 
                        ? Colors.orange[800] 
                        : status == OrderStatus.accepted || status == OrderStatus.delivering
                            ? Colors.green[800]
                            : status == OrderStatus.completed
                                ? Colors.black87
                                : Colors.red[800]),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBidsTab() {
    return RefreshIndicator(
      onRefresh: _loadDriverBids,
      child: driverBids.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có bids từ tài xế', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: driverBids.length,
              itemBuilder: (_, i) {
                final bid = driverBids[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Icon(Icons.person, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bid['driverName'] ?? 'Tài xế',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    bid['driverPhone'] ?? '',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                bid['status'] == 'pending' ? 'Đang chờ' : 'Đã chọn',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Bid details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Đơn hàng', style: TextStyle(color: Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Text(
                                    bid['orderId'] ?? '', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Giá đề xuất', style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                Text(
                                  bid['bidPrice'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Buttons
                        if (bid['status'] == 'pending')
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // TODO: Implement reject logic if needed in the backend
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã từ chối bid này')),
                                    );
                                    setState(() {
                                      driverBids.removeAt(i);
                                    });
                                  },
                                  child: const Text('Từ chối'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final orderId = bid['orderId'] as String;
                                    final driverPhone = bid['driverPhone'] as String;

                                    // 1. Tell service to accept this specific bid (backend call)
                                    await OrderStatusService.shipperAcceptBid(orderId, driverPhone);
                                    
                                    // 2. Update the main order pool status to reflect the change in "My Orders" tab
                                    OrderPoolService.instance.updateStatus(orderId, OrderStatus.accepted);

                                    // 3. Show feedback to the user
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã chọn ${bid['driverName']} giao hàng'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      // 4. Reload bids from service to remove the accepted one from this tab
                                      await _loadDriverBids();
                                    }
                                  },
                                  child: const Text('Chấp nhận'),
                                ),
                              ),
                            ],
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
