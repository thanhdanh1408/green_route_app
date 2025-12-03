// lib/features/driver/screens/driver_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<OrderModel> orders = [];
  Set<String> biddingOrders = {};
  List<OrderModel> waitingOrders = [];
  List<OrderModel> acceptedOrders = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    // Reload dữ liệu mỗi 2 giây để kiểm tra xem chủ hàng có chấp nhận bid hay không
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
    final prefs = await SharedPreferences.getInstance();
    final biddingIds = prefs.getStringList('bidding_orders') ?? [];

    // Load từ OrderStatusService (chứa waiting_orders và accepted_orders)
    final waitingOrdersList = await OrderStatusService.getWaitingOrders();
    final acceptedOrdersList = await OrderStatusService.getAcceptedOrders();

    // Load available orders từ DriverService
    final data = await DriverService().getAvailableOrders();

    setState(() {
      orders = data;
      biddingOrders = biddingIds.toSet();
      waitingOrders = waitingOrdersList;
      acceptedOrders = acceptedOrdersList;
    });

    debugPrint('DriverOrdersScreen - Available: ${orders.length}, Waiting: ${waitingOrders.length}, Accepted: ${acceptedOrders.length}');
  }

  @override
  Widget build(BuildContext context) {
    // Combine available, waiting và accepted orders
    // Available orders = chưa đặt giá
    // Waiting orders = đang chờ phản hồi (đã đặt giá, chưa chấp nhận)
    // Accepted orders = đã chấp nhận (trúng thầu)
    
    final allOrders = <OrderModel>[
      ...orders, // Available orders
      ...waitingOrders, // Waiting orders (đang chờ phản hồi)
      ...acceptedOrders, // Accepted orders (trúng thầu)
    ];

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
                    'Khả dụng: ${orders.length} • Chờ phản hồi: ${waitingOrders.length} • Chấp nhận: ${acceptedOrders.length}',
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
                      final isWaiting = waitingOrders.contains(order);
                      final isAccepted = acceptedOrders.contains(order);

                      // Xác định status
                      String status = 'Khả dụng';
                      Color statusBgColor = Colors.blue[100]!;
                      Color statusTextColor = Colors.blue[800]!;

                      if (isWaiting) {
                        status = 'Đang chờ phản hồi';
                        statusBgColor = Colors.orange[100]!;
                        statusTextColor = Colors.orange[800]!;
                      } else if (isAccepted) {
                        status = 'Đã chấp nhận';
                        statusBgColor = Colors.green[100]!;
                        statusTextColor = Colors.green[800]!;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusBgColor,
                              child: Text(
                                isAccepted
                                    ? '✓'
                                    : isWaiting
                                        ? '⏳'
                                        : '?',
                                style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold),
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
                                status,
                                style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            onTap: isAccepted
                                ? null
                                : () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => BidBottomSheet(
                                        order: order,
                                        onBidSubmitted: () async {
                                          await _loadAllData();
                                        },
                                        onBidAccepted: () async {
                                          await _loadAllData();
                                        },
                                      ),
                                    );
                                  },
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
}