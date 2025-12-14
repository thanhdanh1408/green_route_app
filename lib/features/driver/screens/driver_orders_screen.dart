// lib/features/driver/screens/driver_orders_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/verification_status_banner.dart';
import '../../../core/services/order_pool_service.dart';
import '../models/order_model.dart';
import '../services/order_status_service.dart';
import '../widgets/bid_bottom_sheet.dart';
import '../widgets/empty_orders_widget.dart';
import '../widgets/order_card.dart';
import 'booking_requests_screen.dart';
import 'driver_route_selection_screen.dart';
import 'edit_profile_screen.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});
  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _orderUpdateSubscription;
  String _userId = '';

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
    
    // Load user ID and verification status
    _loadUserInfo();
    
    // Tải dữ liệu lần đầu
    _loadAllData();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_phone') ?? '';
    
    if (mounted) {
      setState(() {
        _userId = userId;
      });
    }
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

  void _handleEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    
    // If changes were saved, trigger rebuild to refresh verification banner
    if (result == true && mounted) {
      // Wait a bit for documents to be saved to SharedPreferences
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Trigger rebuild of the entire screen to refresh the banner
      setState(() {});
      
      debugPrint('✅ Refreshed screen after edit profile');
    }
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
          // Verification status banner
          if (_userId.isNotEmpty)
            VerificationStatusBanner(
              userId: _userId,
              userType: 'driver',
              onTapEditProfile: _handleEditProfile,
            ),
          
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
          
          // Route info card - displayed below tabs
          _buildRouteCard(),
          
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

  Widget _buildRouteCard() {
    // Load route info from SharedPreferences
    return FutureBuilder<Map<String, String>>(
      future: _loadRouteInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        
        final routeFrom = snapshot.data!['from'] ?? '';
        final routeTo = snapshot.data!['to'] ?? '';
        final routeWeight = snapshot.data!['weight'] ?? '';
        final routeTimeRange = snapshot.data!['timeRange'] ?? '';
        
        if (routeFrom.isEmpty || routeTo.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tuyến hoạt động',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '$routeFrom → $routeTo',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverRouteSelectionScreen()),
                      );
                    },
                    child: const Text('Đổi'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('$routeWeight tấn', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(routeTimeRange, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<Map<String, String>> _loadRouteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'from': prefs.getString('driver_route_from') ?? '',
      'to': prefs.getString('driver_route_to') ?? '',
      'weight': prefs.getString('driver_route_weight') ?? '',
      'timeRange': prefs.getString('driver_route_time_range') ?? '',
    };
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
