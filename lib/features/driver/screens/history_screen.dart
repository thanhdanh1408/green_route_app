// lib/features/driver/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import 'trip_tracking_screen.dart';
import '../services/order_status_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> allTrips = [];
  List<Map<String, dynamic>> waitingTrips = [];
  List<Map<String, dynamic>> completedTrips = [];
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
    // Lấy đơn đang chờ
    final waitingOrders = await OrderStatusService.getWaitingOrders();
    final waiting = waitingOrders.map((order) {
      return {
        'id': order.id,
        'route': '${order.from} - ${order.to}',
        'cargo': '${order.weight}',
        'date': DateTime.now().toString().split(' ')[0],
        'status': 'Đang chờ',
        'statusColor': Colors.blue,
        'price': order.price,
        'progress': 0,
      };
    }).toList();

    // Lấy đơn đã hoàn tất (từ completed_orders)
    final completedOrders = await OrderStatusService.getCompletedOrders();
    final completed = completedOrders.map((order) {
      return {
        'id': order.id,
        'route': '${order.from} - ${order.to}',
        'cargo': '${order.weight}',
        'date': DateTime.now().toString().split(' ')[0],
        'status': order.bidStatus == 'transporting' ? 'Đang vận chuyển' : 'Hoàn thành',
        'statusColor': order.bidStatus == 'transporting' ? Colors.orange : Colors.green,
        'price': order.price,
        'progress': order.bidStatus == 'transporting' ? 2 : 4,
      };
    }).toList();

    setState(() {
      waitingTrips = waiting;
      completedTrips = completed;
      allTrips = [...waiting, ...completed];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Lịch sử chuyến', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Danh sách các chuyến đã hoàn thành', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allTrips.length,
              itemBuilder: (context, i) {
                final trip = allTrips[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripTrackingScreen(trip: trip),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(trip['id'][3], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(trip['route'], style: AppTextStyle.headline2.copyWith(fontWeight: FontWeight.bold)),
                                    Text(trip['cargo'], style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: trip['statusColor'] == Colors.green
                                      ? Colors.green[100]
                                      : trip['statusColor'] == Colors.orange
                                          ? Colors.orange[100]
                                          : Colors.red[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  trip['status'],
                                  style: TextStyle(
                                    color: trip['statusColor'] == Colors.green
                                        ? Colors.green[800]
                                        : trip['statusColor'] == Colors.orange
                                            ? Colors.orange[800]
                                            : Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Ngày hoàn thành: ${trip['date']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Thu nhập: ${trip['price']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}