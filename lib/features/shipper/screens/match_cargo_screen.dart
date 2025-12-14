// lib/features/shipper/screens/match_cargo_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
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
  StreamSubscription? _tripUpdateSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
    // Lắng nghe stream để tự động cập nhật UI khi có thay đổi
    _tripUpdateSubscription = EmptyTripService.tripStream.listen((_) {
      _loadTrips();
    });
  }

  @override
  void dispose() {
    _tripUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    final trips = await EmptyTripService.getAvailableEmptyTrips();
    if (mounted) {
      setState(() {
        availableTrips = trips;
        _isLoading = false;
      });
    }
  }

  Future<void> _showTripDetails(EmptyTrip trip) async {
    final prefs = await SharedPreferences.getInstance();
    final currentShipperId = prefs.getString('user_phone') ?? '';
    final hasJoined = trip.joinedShippers.any((s) => s.shipperId == currentShipperId);
    
    debugPrint('🔍 Current Shipper ID: $currentShipperId');
    debugPrint('🔍 Joined Shippers: ${trip.joinedShippers.map((s) => s.shipperId).toList()}');
    debugPrint('🔍 Has Joined: $hasJoined');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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

                // Thông tin chuyến, tài xế và các chủ hàng đã tham gia...
                _buildTripInfoSection(trip),
                const SizedBox(height: 16),
                _buildShipperListSection(trip),
                const SizedBox(height: 16),
                _buildFillProgress(trip),
                const SizedBox(height: 24),

                // Nút hành động (Tham gia / Hủy / Đã đầy)
                _buildActionButton(trip, hasJoined, currentShipperId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJoinDialog(EmptyTrip trip) {
    final cargoTypeController = TextEditingController();
    final fromDetailController = TextEditingController();
    final toDetailController = TextEditingController();
    final priceController = TextEditingController();
    final availableCapacity = trip.availableCapacityInTons;
    double selectedWeight = (availableCapacity > 1.0) ? 1.0 : availableCapacity;
    
    // Tính giá đề xuất dựa trên tỷ lệ khối lượng
    final totalPrice = double.tryParse(trip.proposedPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final totalCapacity = trip.totalCapacityInTons;
    debugPrint('💰 Price calculation:');
    debugPrint('   - Trip capacity string: "${trip.capacity}"');
    debugPrint('   - Total capacity parsed: $totalCapacity tấn');
    debugPrint('   - Total joined weight: ${trip.totalJoinedWeight} tấn');
    debugPrint('   - Available capacity: ${trip.availableCapacityInTons} tấn');
    debugPrint('   - Total price: $totalPrice VNĐ');
    debugPrint('   - Selected weight: $selectedWeight tấn');
    if (totalCapacity > 0) {
      final suggestedPrice = (totalPrice / totalCapacity) * selectedWeight;
      priceController.text = suggestedPrice.toStringAsFixed(0);
      debugPrint('   - Suggested price: $suggestedPrice VNĐ (${totalPrice}/${totalCapacity}*$selectedWeight)');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tham gia ghép hàng', textAlign: TextAlign.center),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  const Text('Khối lượng (tấn)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: selectedWeight,
                          min: 0.1,
                          max: availableCapacity,
                          divisions: (availableCapacity / 0.1).round().clamp(1, 1000),
                          label: selectedWeight.toStringAsFixed(1),
                          onChanged: (double value) {
                            setState(() {
                              selectedWeight = value;
                              if (totalCapacity > 0) {
                                final suggestedPrice = (totalPrice / totalCapacity) * value;
                                priceController.text = suggestedPrice.toStringAsFixed(0);
                                debugPrint('🔄 Slider changed: weight=$value tấn → price=${suggestedPrice.toStringAsFixed(0)} VNĐ');
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: selectedWeight.toStringAsFixed(1),
                          decoration: const InputDecoration(
                            suffixText: 'tấn',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            final parsed = double.tryParse(value);
                            if (parsed != null && parsed >= 0.1 && parsed <= availableCapacity) {
                              setState(() {
                                selectedWeight = parsed;
                                if (totalCapacity > 0) {
                                  final suggestedPrice = (totalPrice / totalCapacity) * parsed;
                                  priceController.text = suggestedPrice.toStringAsFixed(0);
                                  debugPrint('✏️ Manual input: weight=$parsed tấn → price=${suggestedPrice.toStringAsFixed(0)} VNĐ');
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Tối đa: ${availableCapacity.toStringAsFixed(1)} tấn', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  // Địa điểm nhận hàng
                  TextFormField(
                    controller: fromDetailController,
                    decoration: InputDecoration(
                      labelText: 'Địa điểm nhận hàng cụ thể *',
                      hintText: 'VD: Kho A, KCN Tân Bình',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Địa điểm giao hàng
                  TextFormField(
                    controller: toDetailController,
                    decoration: InputDecoration(
                      labelText: 'Địa điểm giao hàng cụ thể *',
                      hintText: 'VD: Kho B, KCN Nội Bài',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Giá tự động (VNĐ)',
                      helperText: 'Tính theo tỷ lệ khối lượng',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              // Validation
              if (cargoTypeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập loại hàng!'), backgroundColor: Colors.orange),
                );
                return;
              }
              if (fromDetailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập địa điểm nhận hàng!'), backgroundColor: Colors.orange),
                );
                return;
              }
              if (toDetailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập địa điểm giao hàng!'), backgroundColor: Colors.orange),
                );
                return;
              }
              
              final prefs = await SharedPreferences.getInstance();
              final shipperId = prefs.getString('user_phone') ?? '';
              final shipperName = prefs.getString('name') ?? 'Chủ hàng';

              final success = await EmptyTripService.sendJoinRequest(
                tripId: trip.id,
                shipperId: shipperId,
                shipperName: shipperName,
                shipperPhone: shipperId,
                cargoType: cargoTypeController.text.trim(),
                cargoWeight: selectedWeight.toStringAsFixed(1),
                price: priceController.text.trim(),
                fromDetail: fromDetailController.text.trim(),
                toDetail: toDetailController.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? '✅ Gửi yêu cầu thành công! Chờ tài xế duyệt.' : '❌ Không thể gửi yêu cầu'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Gửi yêu cầu'),
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
              ? const Center(
                  child: Text('Hiện không có chuyến ghép hàng nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                            const SizedBox(height: 2),
                                            Text(
                                              '${trip.containerType} • ${trip.capacity}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Chip(
                                        label: Text('${trip.joinedShippers.length}/${trip.maxShippers} slots'),
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
                                        'Giá tham khảo: ${trip.proposedPrice}đ',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Tài xế: ${trip.driverName}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          textAlign: TextAlign.end,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ));
                    },
                  ),
                ),
    );
  }

  // Helper widgets for dialog
  Widget _buildTripInfoSection(EmptyTrip trip) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📍 Thông tin chuyến', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(height: 10),
            _detailRow('Tài xế:', trip.driverName),
            _detailRow('SĐT:', trip.driverPhone),
            _detailRow('Tuyến:', '${trip.from} → ${trip.to}'),
            _detailRow('Nhận hàng:', trip.fromAddress, isAddress: true),
            _detailRow('Giao hàng:', trip.toAddress, isAddress: true),
            const Divider(height: 10),
            _detailRow('Container:', trip.containerType),
            _detailRow('Tải trọng:', trip.capacity),
            _detailRow('Giá tham khảo:', '${trip.proposedPrice}đ'),
            _detailRow('Thời gian nhận:', DateFormat('dd/MM HH:mm').format(trip.pickupTime)),
            _detailRow('Thời gian giao:', DateFormat('dd/MM HH:mm').format(trip.deliveryTime)),
          ],
        ),
      );

  Widget _buildShipperListSection(EmptyTrip trip) => Container(
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
                children: trip.joinedShippers.map((s) => Text('- ${s.shipperName} (${s.cargoWeight} tấn)')).toList(),
              ),
          ],
        ),
      );

  Widget _buildFillProgress(EmptyTrip trip) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tỉ lệ lấp đầy (theo khối lượng)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: trip.fillPercentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                trip.fillPercentage > 80 ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${trip.fillPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      );

  Widget _buildActionButton(EmptyTrip trip, bool hasJoined, String currentShipperId) {
    if (trip.hasAvailableSlots) {
      return SizedBox(
        width: double.infinity,
        child: CustomButton(
          label: hasJoined ? 'Đã tham gia' : 'Tham gia ghép hàng',
          onPressed: hasJoined ? null : () {
            Navigator.pop(context); // Close details to show join dialog
            _showJoinDialog(trip);
          },
        ),
      );
    }

    return const SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        child: Text('Chuyến đã đầy'),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isAddress = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text(value, style: TextStyle(color: isAddress ? AppColors.primary : null))),
          ],
        ),
      );
}
