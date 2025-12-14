import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../services/empty_trip_service.dart';

class CreateEmptyTripScreen extends StatefulWidget {
  const CreateEmptyTripScreen({super.key});

  @override
  State<CreateEmptyTripScreen> createState() => _CreateEmptyTripScreenState();
}

class _CreateEmptyTripScreenState extends State<CreateEmptyTripScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _fromAddressController = TextEditingController();
  final _toAddressController = TextEditingController();
  final _priceController = TextEditingController();

  // Dropdown values
  String? _selectedFrom;
  String? _selectedTo;
  String? _maxShippers;

  // DateTime values
  DateTime? _pickupTime;
  DateTime? _deliveryTime;

  // Vehicle info (mock data - in real app, get from user profile)
  final String _licensePlate = '77A-8977';
  final String _vehicleType = 'Xe tải nặng';
  final String _maxLoad = '5 tấn';

  // Options for dropdowns
  final shipperOptions = ['1', '2', '3', '4', '5'];
  // 11 tỉnh Khu vực Miền Trung Tây Nguyên sau sáp nhập
  final provinceOptions = [
    'Thành phố Huế',
    'Thành phố Đà Nẵng',
    'Tỉnh Thanh Hóa',
    'Tỉnh Nghệ An',
    'Tỉnh Hà Tĩnh',
    'Tỉnh Quảng Trị',
    'Tỉnh Quảng Ngãi',
    'Tỉnh Khánh Hòa',
    'Tỉnh Gia Lai',
    'Tỉnh Đắk Lắk',
    'Tỉnh Lâm Đồng',
  ];

  @override
  void dispose() {
    _fromAddressController.dispose();
    _toAddressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isPickup) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        setState(() {
          if (isPickup) {
            _pickupTime = dateTime;
          } else {
            _deliveryTime = dateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Tạo chuyến ghép hàng',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin xe
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin xe của bạn',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.local_shipping,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Biển số xe: $_licensePlate',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.category, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Loại xe: $_vehicleType',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.scale, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Tải trọng tối đa: $_maxLoad',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Thông tin chuyến hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Dropdown tuyến đường
              const Text('Điểm xuất phát *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedFrom,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                hint: const Text('Chọn tỉnh/thành phố'),
                items: provinceOptions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedFrom = value),
                validator: (value) =>
                    value == null ? 'Chọn điểm xuất phát' : null,
              ),
              const SizedBox(height: 16),

              const Text('Địa chỉ nhận hàng *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fromAddressController,
                decoration: InputDecoration(
                  hintText: 'VD: Kho A, KCN Sóng Thần, Dĩ An, Bình Dương',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Nhập địa chỉ nhận hàng'
                    : null,
              ),
              const SizedBox(height: 16),

              const Text('Điểm đến *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTo,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                hint: const Text('Chọn tỉnh/thành phố'),
                items: provinceOptions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedTo = value),
                validator: (value) => value == null ? 'Chọn điểm đến' : null,
              ),
              const SizedBox(height: 16),

              const Text('Địa chỉ giao hàng *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _toAddressController,
                decoration: InputDecoration(
                  hintText: 'VD: Kho B, KCN Nội Bài, Sóc Sơn, Hà Nội',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Nhập địa chỉ giao hàng'
                    : null,
              ),
              const SizedBox(height: 16),

              // Ngày giờ khởi hành
              const Text('Ngày giờ khởi hành *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _pickupTime == null
                            ? 'Chọn ngày giờ khởi hành'
                            : DateFormat('dd/MM/yyyy HH:mm')
                                .format(_pickupTime!),
                        style: TextStyle(
                            color: _pickupTime == null
                                ? Colors.grey
                                : Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ngày giờ giao hàng
              const Text('Ngày giờ giao hàng *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _deliveryTime == null
                            ? 'Chọn ngày giờ giao hàng'
                            : DateFormat('dd/MM/yyyy HH:mm')
                                .format(_deliveryTime!),
                        style: TextStyle(
                            color: _deliveryTime == null
                                ? Colors.grey
                                : Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tổng giá cước đề xuất
              const Text('Tổng giá cước đề xuất (VNĐ) *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  hintText: 'VD: 1800000',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nhập giá cước' : null,
              ),
              const SizedBox(height: 16),

              // Số người tham gia tối đa
              const Text('Số chủ hàng tối đa *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _maxShippers,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                hint: const Text('Chọn số chủ hàng'),
                items: shipperOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _maxShippers = value),
                validator: (value) => value == null ? 'Chọn số chủ hàng' : null,
              ),
              const SizedBox(height: 24),

              // Nút tạo
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Tạo chuyến ghép hàng',
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        _pickupTime != null &&
                        _deliveryTime != null) {
                      final prefs = await SharedPreferences.getInstance();
                      final driverId = prefs.getString('user_phone') ?? '';
                      final driverName = prefs.getString('name') ?? '';

                      // 🔒 Ensure route data is saved to user-specific keys for persistence
                      final routeFrom = prefs.getString('driver_route_from');
                      final routeTo = prefs.getString('driver_route_to');
                      final routeWeight =
                          prefs.getString('driver_route_weight');
                      final routeTimeRange =
                          prefs.getString('driver_route_time_range');
                      final hasRoute = prefs.getBool('driver_has_route');

                      if (driverId.isNotEmpty && hasRoute == true) {
                        if (routeFrom != null)
                          await prefs.setString(
                              'driver_route_from_$driverId', routeFrom);
                        if (routeTo != null)
                          await prefs.setString(
                              'driver_route_to_$driverId', routeTo);
                        if (routeWeight != null)
                          await prefs.setString(
                              'driver_route_weight_$driverId', routeWeight);
                        if (routeTimeRange != null)
                          await prefs.setString(
                              'driver_route_time_range_$driverId',
                              routeTimeRange);
                        await prefs.setBool('driver_has_route_$driverId', true);
                        debugPrint(
                            '✅ Auto-saved route to user-specific keys when creating trip');
                      }

                      final trip = await EmptyTripService.createEmptyTrip(
                        driverId: driverId,
                        driverName: driverName,
                        driverPhone: driverId,
                        from: _selectedFrom!,
                        to: _selectedTo!,
                        fromAddress: _fromAddressController.text,
                        toAddress: _toAddressController.text,
                        containerType: _vehicleType,
                        capacity: _maxLoad,
                        proposedPrice: _priceController.text,
                        pickupTime: _pickupTime!,
                        deliveryTime: _deliveryTime!,
                        maxShippers: int.parse(_maxShippers!),
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('✅ Tạo chuyến thành công! ID: ${trip.id}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context, trip);
                    } else if (_pickupTime == null || _deliveryTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Vui lòng chọn ngày giờ khởi hành và giao hàng'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
