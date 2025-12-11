import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../widgets/history_card.dart';
import '../../driver/services/order_status_service.dart';
import 'shipper_trip_tracking_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Tách riêng 2 loại đơn
  List<Map<String, dynamic>> regularOrders = [];      // Đơn thường
  List<Map<String, dynamic>> consolidatedOrders = []; // Đơn ghép
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Auto-reload every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final shipperId = prefs.getString('user_phone') ?? '';

    // Lấy đơn ghép từ shipper_waiting_orders (cả waiting, delivering, completed)
    final waitingOrdersJson = prefs.getStringList('shipper_waiting_orders') ?? [];
    final consolidatedOrdersList = waitingOrdersJson
        .map((orderJson) {
          try {
            final order = jsonDecode(orderJson) as Map<String, dynamic>;
            if (order['shipperId'] == shipperId && 
                (order['status'] == 'waiting' || order['status'] == 'delivering' || order['status'] == 'completed')) {
              return {
                'id': order['id'],
                'tripId': order['tripId'],
                'tripType': 'consolidated',
                'route': '${order['from']} - ${order['to']}',
                'from': order['from'],
                'to': order['to'],
                'fromDetail': order['fromDetail'] ?? '',
                'toDetail': order['toDetail'] ?? '',
                'goods': order['goods'],
                'weight': order['weight'],
                'price': order['price'],
                'driverName': order['driverName'] ?? 'Không có thông tin',
                'driverPhone': order['driverPhone'] ?? '',
                'status': order['status'] == 'waiting' 
                    ? 'Đang chờ'
                    : order['status'] == 'delivering'
                        ? 'Đang giao hàng'
                        : 'Hoàn thành',
                'statusColor': order['status'] == 'waiting'
                    ? Colors.blue
                    : order['status'] == 'delivering'
                        ? Colors.orange
                        : Colors.green,
                'date': DateTime.parse(order['createdAt'] ?? DateTime.now().toIso8601String())
                    .toString()
                    .split(' ')[0],
              };
            }
            return null;
          } catch (e) {
            debugPrint('Error parsing consolidated order: $e');
            return null;
          }
        })
        .where((order) => order != null)
        .cast<Map<String, dynamic>>()
        .toList();

    // Lấy đơn thường đã accepted/completed từ bidding system
    final acceptedBids = await OrderStatusService.getShipperAcceptedOrders(shipperId);
    debugPrint('📦 Shipper $shipperId accepted/completed bids: ${acceptedBids.length}');
    for (var bid in acceptedBids) {
      debugPrint('  - Order: ${bid['orderId']}, Status: ${bid['status']}');
    }
    
    final regularOrdersList = acceptedBids.map((bid) {
      // Hiển thị đúng trạng thái dựa vào bid status
      final isCompleted = bid['status'] == 'completed';
      
      return {
        'id': bid['orderId'],
        'tripType': 'regular',
        'route': '${bid['from']} - ${bid['to']}',
        'from': bid['from'],
        'to': bid['to'],
        'fromDetail': bid['fromDetail'] ?? '',
        'toDetail': bid['toDetail'] ?? '',
        'goods': bid['goods'],
        'weight': bid['weight'],
        'price': bid['bidPrice'],
        'driverName': bid['driverName'] ?? 'Không có thông tin',
        'driverPhone': bid['driverPhone'] ?? '',
        'status': isCompleted ? 'Hoàn thành' : 'Đang giao hàng',
        'statusColor': isCompleted ? Colors.green : Colors.orange,
        'date': DateTime.now().toString().split(' ')[0],
      };
    }).toList();

    // Kiểm tra trùng lặp bằng Set
    final regularIds = <String>{};
    final consolidatedIds = <String>{};
    
    final uniqueRegular = regularOrdersList.where((order) {
      final id = order['id'] as String;
      if (regularIds.contains(id)) {
        debugPrint('⚠️ Duplicate regular order: $id');
        return false;
      }
      regularIds.add(id);
      return true;
    }).toList();
    
    final uniqueConsolidated = consolidatedOrdersList.where((order) {
      final id = order['id'] as String;
      if (consolidatedIds.contains(id)) {
        debugPrint('⚠️ Duplicate consolidated order: $id');
        return false;
      }
      consolidatedIds.add(id);
      return true;
    }).toList();

    setState(() {
      regularOrders = uniqueRegular;
      consolidatedOrders = uniqueConsolidated;
      
      // Sắp xếp mới nhất trước
      regularOrders.sort((a, b) => b['date'].compareTo(a['date']));
      consolidatedOrders.sort((a, b) => b['date'].compareTo(a['date']));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đơn hàng', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Đơn thường'),
              Tab(text: 'Đơn ghép'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Đơn thường
            _buildOrderList(regularOrders, 'Đơn thường'),
            
            // Tab 2: Đơn ghép
            _buildOrderList(consolidatedOrders, 'Đơn ghép'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Chưa có $type', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return HistoryCard(
          order: order,
          orderNumber: index + 1,  // Sequential number trong từng tab
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShipperTripTrackingScreen(order: order),
              ),
            );
          },
        );
      },
    );
  }
}