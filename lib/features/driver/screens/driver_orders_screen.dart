// lib/features/driver/screens/driver_orders_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/order_pool_service.dart';
import '../models/order_model.dart';
import '../services/order_status_service.dart';
import '../widgets/bid_bottom_sheet.dart';
import '../widgets/empty_orders_widget.dart';
import '../widgets/order_card.dart';
import 'booking_requests_screen.dart';
import '../services/order_status_service.dart';
import '../widgets/bid_bottom_sheet.dart';
import '../widgets/empty_orders_widget.dart';
import '../widgets/order_card.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});
  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _orderUpdateSubscription;

  // Dữ liệu cho mỗi tab
  List<PooledOrder> _availableOrders = [];
  List<OrderModel> _biddingOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Lắng nghe stream cập nhật
    _orderUpdateSubscription = OrderStatusService.orderStream.listen((_) {
      _loadAllData(); 
    });
    
    // Tải dữ liệu lần đầu
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    // Tải đơn hàng có sẵn từ order pool
    final available = await OrderPoolService.getAvailableOrders();
    
    // Tải đơn đang đấu thầu (pending bids)
    final bidding = await OrderStatusService.getBiddingOrders();
    
    if (mounted) {
      setState(() {
        _availableOrders = available;
        _biddingOrders = bidding;
      });
    }
  }

  void _handleAvailableOrderTap(PooledOrder order) {
    // Convert PooledOrder to OrderModel for BidBottomSheet
    final orderModel = OrderModel(
      id: order.id,
      from: order.from,
      to: order.to,
      fromDetail: order.fromDetail ?? '',
      toDetail: order.toDetail ?? '',
      weight: order.weight,
      goods: order.goods,
      price: order.price,
      receiveDate: order.receiveDate,
      deliverDate: order.deliverDate,
      shipperName: order.shipperName,
      shipperPhone: order.shipperPhone,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BidBottomSheet(
        order: orderModel,
        onBidSubmitted: () {
          // Stream sẽ tự động cập nhật UI
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Đơn hàng', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingRequestsScreen()),
              );
            },
            tooltip: 'Yêu cầu đặt xe',
          ),
        ],
      ),
      body: Column(
        children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppColors.primary,
            tabs: [
              _buildTab('Đề xuất', _availableOrders.length),
              _buildTab('Đang đấu thầu', _biddingOrders.length),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Đề xuất - Available orders from pool
              _buildAvailableOrdersList(),
              
              // Tab 2: Đang đấu thầu - Pending bids
              _buildBiddingOrdersList(),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildTab(String text, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          if (count > 0)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersList() {
    if (_availableOrders.isEmpty) {
      return const EmptyOrdersWidget(message: 'Chưa có đơn hàng đề xuất nào.');
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _availableOrders.length,
        itemBuilder: (context, index) {
          final order = _availableOrders[index];
          // Convert to OrderModel for display
          final orderModel = OrderModel(
            id: order.id,
            from: order.from,
            to: order.to,
            fromDetail: order.fromDetail ?? '',
            toDetail: order.toDetail ?? '',
            weight: order.weight,
            goods: order.goods,
            price: order.price,
            receiveDate: order.receiveDate,
            deliverDate: order.deliverDate,
            bidStatus: 'available',
          );
          return OrderCard(
            order: orderModel,
            onTap: () => _handleAvailableOrderTap(order),
          );
        },
      ),
    );
  }

  Widget _buildBiddingOrdersList() {
    if (_biddingOrders.isEmpty) {
      return const EmptyOrdersWidget(message: 'Chưa có đơn hàng nào đang đấu thầu.');
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _biddingOrders.length,
        itemBuilder: (context, index) {
          final order = _biddingOrders[index];
          return OrderCard(order: order);
        },
      ),
    );
  }
}
