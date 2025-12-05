// lib/features/shipper/screens/match_cargo_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../driver/models/empty_trip_model.dart';
import '../../driver/services/empty_trip_service.dart';

class MatchCargoScreen extends StatefulWidget {
  const MatchCargoScreen({super.key});

  @override
  State<MatchCargoScreen> createState() => _MatchCargoScreenState();
}

class _MatchCargoScreenState extends State<MatchCargoScreen> {
  List<EmptyTrip> availableTrips = [];
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 MatchCargoScreen initState - loading trips');
    _loadTrips();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      debugPrint('⏱️ Auto-refresh timer fired - reloading trips');
      _loadTrips();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    debugPrint('🔄 Loading available trips from MatchCargoScreen...');
    await EmptyTripService.debugPrintStorage();
    final trips = await EmptyTripService.getAvailableEmptyTrips();
    debugPrint('📍 MatchCargoScreen received ${trips.length} trips');
    setState(() {
      availableTrips = trips;
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
                    'Chi tiết chuyến ghép hàng',
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

              // Thông tin driver
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👤 Thông tin tài xế', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _detailRow('Tên:', trip.driverName),
                    _detailRow('SĐT:', trip.driverPhone),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Shipper đã join
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
                        }).toList(),
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

              // Nút tham gia
              if (trip.hasAvailableSlots)
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Tham gia ghép hàng',
                    onPressed: () {
                      Navigator.pop(context);
                      _showJoinDialog(trip);
                    },
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    child: const Text('Chuyến đã đầy'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinDialog(EmptyTrip trip) {
    final cargoTypeController = TextEditingController();
    final cargoWeightController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tham gia ghép hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: cargoTypeController,
                decoration: InputDecoration(
                  labelText: 'Loại hàng',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: cargoWeightController,
                decoration: InputDecoration(
                  labelText: 'Khối lượng (tấn)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Giá (VNĐ)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // ✅ Lấy thông tin shipper hiện tại từ SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final shipperId = prefs.getString('user_phone') ?? '0977123456';
              final shipperName = prefs.getString('name') ?? 'Chủ hàng';

              final success = await EmptyTripService.joinEmptyTrip(
                tripId: trip.id,
                shipperId: shipperId,
                shipperName: shipperName,
                shipperPhone: shipperId,
                cargoType: cargoTypeController.text.trim(),
                cargoWeight: cargoWeightController.text.trim(),
                price: priceController.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Tham gia ghép hàng thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                await _loadTrips();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Không thể tham gia chuyến này'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Ghép hàng tiết kiệm', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : availableTrips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'Hiện không có chuyến ghép hàng',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: availableTrips.length,
                    itemBuilder: (context, index) {
                      final trip = availableTrips[index];
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
                                      'Giá chuyến: ${trip.proposedPrice}đ',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                    Text(
                                      'Tài xế: ${trip.driverName}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
          width: 80,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
