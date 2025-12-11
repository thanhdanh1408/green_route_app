// lib/features/driver/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/vietnam_coordinates.dart';
import 'trip_tracking_screen.dart';
import '../services/order_status_service.dart';
import '../services/empty_trip_service.dart';

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
    _loadData();
    // Auto-reload every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('user_phone') ?? '';

    // Lấy đơn đang chờ (ĐƠN THƯỜNG)
    final waitingOrders = await OrderStatusService.getWaitingOrders();
    final waiting = waitingOrders.map((order) {
      // Get coordinates from province names
      final fromCoord = VietnamCoordinates.getCoordinatesOrDefault(order.from);
      final toCoord = VietnamCoordinates.getCoordinatesOrDefault(order.to);
      
      return {
        'id': order.id,
        'tripType': 'regular',
        'route': '${order.from} - ${order.to}',
        'cargo': order.weight,
        'date': DateTime.now().toString().split(' ')[0],
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'Đang chờ',
        'statusColor': Colors.blue,
        'price': order.price,
        'progress': 0,
        'from': order.from,
        'to': order.to,
        'fromDetail': order.fromDetail,
        'toDetail': order.toDetail,
        'goods': order.goods,
        'weight': order.weight,
        'shipperName': order.shipperName ?? 'Không có thông tin',
        'shipperPhone': order.shipperPhone ?? '',
        'fromLatLng': fromCoord,
        'toLatLng': toCoord,
      };
    }).toList();

    // Lấy đơn đã hoàn tất (từ completed_orders) - ĐƠN THƯỜNG
    final completedOrders = await OrderStatusService.getCompletedOrders();
    final completed = completedOrders.map((order) {
      // Get coordinates from province names
      final fromCoord = VietnamCoordinates.getCoordinatesOrDefault(order.from);
      final toCoord = VietnamCoordinates.getCoordinatesOrDefault(order.to);
      
      return {
        'id': order.id,
        'tripType': 'regular',
        'route': '${order.from} - ${order.to}',
        'cargo': order.weight,
        'date': DateTime.now().toString().split(' ')[0],
        'createdAt': order.completedAt ?? DateTime.now().toIso8601String(),
        'status': order.bidStatus == 'transporting' ? 'Đang vận chuyển' : 'Hoàn thành',
        'statusColor': order.bidStatus == 'transporting' ? Colors.orange : Colors.green,
        'price': order.price,
        'progress': order.bidStatus == 'transporting' ? 2 : 4,
        'from': order.from,
        'to': order.to,
        'fromDetail': order.fromDetail,
        'toDetail': order.toDetail,
        'goods': order.goods,
        'weight': order.weight,
        'shipperName': order.shipperName ?? 'Không có thông tin',
        'shipperPhone': order.shipperPhone ?? '',
        'fromLatLng': fromCoord,
        'toLatLng': toCoord,
      };
    }).toList();

    // Lấy chế độ GHÉP HÀNG đang giao (delivering) - ĐƠN GHÉP
    final deliveringTrips = await EmptyTripService.getMyDeliveringTrips(driverId);
    final delivering = deliveringTrips.map((trip) {
      // Get coordinates from province names
      final fromCoord = VietnamCoordinates.getCoordinatesOrDefault(trip.from);
      final toCoord = VietnamCoordinates.getCoordinatesOrDefault(trip.to);
      
      return {
        'id': trip.id,
        'tripType': 'consolidated',
        'route': '${trip.from} - ${trip.to}',
        'cargo': '${trip.joinedShippers.length} chủ hàng',
        'date': DateTime.now().toString().split(' ')[0],
        'createdAt': DateTime.now().toIso8601String(),
        'status': trip.status == 'delivering' ? 'Đang giao hàng' : 'Hoàn thành',
        'statusColor': trip.status == 'delivering' ? Colors.orange : Colors.green,
        'price': trip.proposedPrice,
        'progress': trip.status == 'delivering' ? 1 : 3,
        'from': trip.from,
        'to': trip.to,
        'fromDetail': trip.fromAddress,
        'toDetail': trip.toAddress,
        'fromLatLng': fromCoord,  // ADD coordinates
        'toLatLng': toCoord,      // ADD coordinates
        'containerType': trip.containerType,
        'capacity': trip.capacity,
        'joinedShippers': trip.joinedShippers.map((s) => {
          'name': s.shipperName,
          'phone': s.shipperPhone,
          'cargoType': s.cargoType,
          'weight': s.cargoWeight,
          'price': s.price,
          'fromDetail': s.fromDetail,
          'toDetail': s.toDetail,
        }).toList(),
      };
    }).toList();

    // Lấy đơn từ BOOKING REQUESTS đã được chấp nhận - ĐƠN ĐẶT XE TRỰC TIẾP
    final driverBidsJson = prefs.getStringList('driver_bids') ?? [];
    debugPrint('📦 Driver $driverId has ${driverBidsJson.length} bids in driver_bids');
    
    final bookingOrders = driverBidsJson
        .map((bidJson) {
          try {
            final bid = jsonDecode(bidJson) as Map<String, dynamic>;
            if (bid['driverId'] == driverId && bid['status'] == 'accepted') {
              debugPrint('  ✓ Found accepted booking: ${bid['orderId']}');
              
              final createdAt = bid['createdAt'] ?? bid['acceptedAt'] ?? DateTime.now().toIso8601String();
              
              // Get coordinates from province names
              final fromCoord = VietnamCoordinates.getCoordinatesOrDefault(bid['from'] ?? '');
              final toCoord = VietnamCoordinates.getCoordinatesOrDefault(bid['to'] ?? '');
              
              return {
                'id': bid['orderId'],
                'tripType': 'regular',
                'route': '${bid['from']} - ${bid['to']}',
                'cargo': bid['weight'],
                'date': DateTime.now().toString().split(' ')[0],
                'createdAt': createdAt,
                'status': 'Đang giao hàng',
                'statusColor': Colors.orange,
                'price': bid['bidPrice'],
                'progress': 1,
                'from': bid['from'],
                'to': bid['to'],
                'fromDetail': bid['fromDetail'] ?? '',
                'toDetail': bid['toDetail'] ?? '',
                'fromLatLng': fromCoord,
                'toLatLng': toCoord,
                'goods': bid['goods'],
                'weight': bid['weight'],
                'shipperName': bid['shipperName'] ?? 'Không có thông tin',
                'shipperPhone': bid['shipperPhone'] ?? '',
              };
            }
            return null;
          } catch (e) {
            debugPrint('Error parsing booking bid: $e');
            return null;
          }
        })
        .where((order) => order != null)
        .cast<Map<String, dynamic>>()
        .toList();
    
    debugPrint('📦 Loaded ${bookingOrders.length} accepted bookings for driver');

    setState(() {
      // Tách đơn thường và đơn ghép
      final allOrders = [...waiting, ...bookingOrders, ...delivering, ...completed];
      
      // Regular orders: waiting + bookingOrders + completed (nếu là regular)
      regularOrders = allOrders.where((o) => o['tripType'] == 'regular').toList();
      
      // Consolidated orders: delivering + completed (nếu là consolidated)
      consolidatedOrders = allOrders.where((o) => o['tripType'] == 'consolidated').toList();
      
      // Sort từng loại riêng (cũ nhất trước)
      regularOrders.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });
      
      consolidatedOrders.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử chuyến', style: TextStyle(color: Colors.white)),
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
        final trip = orders[index];
        final tripType = trip['tripType'] ?? 'regular';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripTrackingScreen(trip: trip),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STT - Số thứ tự (1, 2, 3...)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',  // Sequential number trong từng tab
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Order Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trip['route'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (trip['statusColor'] as Color?) ?? Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                trip['status'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loại: ${tripType == 'regular' ? 'Đơn thường' : 'Đơn ghép'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        Text(
                          'Hàng hóa: ${trip['cargo'] ?? trip['weight'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        if (trip['price'] != null)
                          Text(
                            'Giá: ${trip['price']}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}