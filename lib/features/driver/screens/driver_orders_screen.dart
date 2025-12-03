// lib/features/driver/screens/driver_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../widgets/order_card.dart';
import '../models/order_model.dart';
import '../services/driver_service.dart';
import '../widgets/bid_bottom_sheet.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});
  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  List<OrderModel> orders = [];
  Set<String> biddingOrders = {};
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
    final acceptedJson = prefs.getStringList('accepted_orders') ?? [];

    final data = await DriverService().getAvailableOrders();
    final acceptedOrdersList = acceptedJson.map((e) => OrderModel.fromJson(e)).toList();

    setState(() {
      orders = data;
      biddingOrders = biddingIds.toSet();
      acceptedOrders = acceptedOrdersList;
    });
  }

  Future<void> _saveBidding(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    biddingOrders.add(orderId);
    await prefs.setStringList('bidding_orders', biddingOrders.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.1),
          child: const Text(
            'Đơn hàng phù hợp với tuyến của bạn',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadAllData();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final isBidding = biddingOrders.contains(order.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OrderCard(
                    order: order,
                    isBidding: isBidding,
                    onBid: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BidBottomSheet(
                          order: order,
                          onBidSubmitted: () async {
                            await _saveBidding(order.id);
                            setState(() => biddingOrders.add(order.id));
                          },
                          onBidAccepted: () async {
                            final prefs = await SharedPreferences.getInstance();
                            acceptedOrders.add(order);
                            await prefs.setStringList(
                              'accepted_orders',
                              acceptedOrders.map((e) => e.toJson()).toList(),
                            );
                            setState(() {});
                          },
                        ),
                      );
                    },
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