// lib/features/driver/screens/driver_empty_trips_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/empty_trip_model.dart';
import '../services/empty_trip_service.dart';
import 'create_empty_trip_screen.dart';

class DriverEmptyTripsScreen extends StatefulWidget {
  const DriverEmptyTripsScreen({super.key});

  @override
  State<DriverEmptyTripsScreen> createState() => _DriverEmptyTripsScreenState();
}

class _DriverEmptyTripsScreenState extends State<DriverEmptyTripsScreen> {
  List<EmptyTrip> myTrips = [];
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 DriverEmptyTripsScreen initState - loading my trips');
    _loadMyTrips();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      debugPrint('⏱️ Auto-refresh timer fired - reloading my trips');
      _loadMyTrips();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMyTrips() async {
    // Lấy tất cả chuyến của driver hiện tại
    const driverId = '0987654321'; // TODO: Get from AuthService
    final trips = await EmptyTripService.getMyEmptyTrips(driverId);

    debugPrint('📍 DriverEmptyTripsScreen loaded ${trips.length} my trips');
    setState(() {
      myTrips = trips;
      _isLoading = false;
    });
  }

  void _showTripDetails(EmptyTrip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chi tiết chuyến của tôi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Thông tin chuyến
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📍 Thông tin chuyến', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _detailRow('Tuyến:', '${trip.from} → ${trip.to}'),
                    _detailRow('Container:', trip.containerType),
                    _detailRow('Dung tích:', trip.capacity),
                    _detailRow('Giá chuyến:', '${trip.proposedPrice}đ'),
                    _detailRow('Nhận hàng:', DateFormat('dd/MM HH:mm').format(trip.pickupTime)),
                    _detailRow('Giao hàng:', DateFormat('dd/MM HH:mm').format(trip.deliveryTime)),
                    _detailRow('Trạng thái:', trip.status),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Chủ hàng đã join
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('👥 Chủ hàng đã tham gia', style: TextStyle(fontWeight: FontWeight.bold)),
                        Chip(
                          label: Text('${trip.joinedShippers.length}/${trip.maxShippers}'),
                          backgroundColor: trip.hasAvailableSlots ? Colors.orange[200] : Colors.red[200],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (trip.joinedShippers.isEmpty)
                      const Text('Chưa có chủ hàng nào tham gia', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                    else
                      Column(
                        children: trip.joinedShippers.map((shipper) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      shipper.shipperName[0],
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(shipper.shipperName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        '${shipper.cargoWeight} - ${shipper.cargoType}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${shipper.price}đ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }).toList()
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lạp đầy chuyến', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${trip.fillPercentage}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: trip.fillPercentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        trip.hasAvailableSlots ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nút hành động
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: trip.hasAvailableSlots
                          ? () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Chuyến còn chỗ trống - Chờ chủ hàng tham gia'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            }
                          : null,
                      child: const Text('Chuyến đã đầy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await EmptyTripService.cancelEmptyTrip(trip.id);
                        if (mounted) {
                          Navigator.pop(context);
                          await _loadMyTrips();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Đã hủy chuyến'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text('Hủy', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Chuyến ghép hàng của tôi', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : myTrips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn chưa tạo chuyến ghép hàng nào',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateEmptyTripScreen()),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo chuyến mới'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyTrips,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: myTrips.length,
                    itemBuilder: (context, index) {
                      final trip = myTrips[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _showTripDetails(trip),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${trip.from} → ${trip.to}',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${trip.containerType} • ${trip.capacity}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text('${trip.joinedShippers.length}/${trip.maxShippers}'),
                                      backgroundColor: trip.hasAvailableSlots ? Colors.orange[100] : Colors.red[100],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: trip.fillPercentage / 100,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Giá: ${trip.proposedPrice}đ',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: trip.status == 'open' ? Colors.green[100] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        trip.status == 'open' ? '🟢 Mở' : '⚪ ${trip.status}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: trip.status == 'open' ? Colors.green[800] : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.grey))),
      ],
    ),
  );
}
