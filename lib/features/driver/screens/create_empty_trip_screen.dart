import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String? _selectedFrom;
  String? _selectedTo;
  String? _selectedContainer;
  String? _selectedCapacity;
  String? _maxShippers;
  String? _proposedPrice;
  DateTime? _pickupTime;
  DateTime? _deliveryTime;

  final containerOptions = ['Container 20\'', 'Container 40\'', 'Xe tải'];
  final capacityOptions = ['2 tấn', '5 tấn', '10 tấn', '15 tấn', '20 tấn'];
  final shipperOptions = ['1', '2', '3', '4', '5'];
  final provinceOptions = ['Hà Nội', 'TP.HCM', 'Gia Lai', 'Đắk Lắk', 'Quảng Ngãi'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Tạo chuyến ghép hàng', style: TextStyle(color: Colors.white)),
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
              const Text(
                'Thông tin chuyến hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Tuyến đường
              const Text('Tuyến đường', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFrom,
                      decoration: InputDecoration(
                        hintText: 'Điểm đi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: provinceOptions
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedFrom = value),
                      validator: (value) => value == null ? 'Chọn điểm đi' : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTo,
                      decoration: InputDecoration(
                        hintText: 'Điểm đến',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: provinceOptions
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedTo = value),
                      validator: (value) => value == null ? 'Chọn điểm đến' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Loại xe
              const Text('Loại container', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedContainer,
                decoration: InputDecoration(
                  hintText: 'Chọn loại container',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: containerOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedContainer = value),
                validator: (value) => value == null ? 'Chọn loại container' : null,
              ),
              const SizedBox(height: 16),

              // Dung tích
              const Text('Dung tích', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCapacity,
                decoration: InputDecoration(
                  hintText: 'Chọn dung tích',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: capacityOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCapacity = value),
                validator: (value) => value == null ? 'Chọn dung tích' : null,
              ),
              const SizedBox(height: 16),

              // Giá đề xuất
              const Text('Giá chuyến (VNĐ)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                onChanged: (value) => setState(() => _proposedPrice = value),
                decoration: InputDecoration(
                  hintText: 'VD: 5000000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Nhập giá chuyến' : null,
              ),
              const SizedBox(height: 16),

              // Số lượng shipper
              const Text('Số lượng shipper tối đa', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _maxShippers,
                decoration: InputDecoration(
                  hintText: 'Chọn số shipper',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: shipperOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text('$s shipper')))
                    .toList(),
                onChanged: (value) => setState(() => _maxShippers = value),
                validator: (value) => value == null ? 'Chọn số shipper' : null,
              ),
              const SizedBox(height: 16),

              // Thời gian nhận hàng
              const Text('Thời gian nhận hàng', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    if (!mounted) return;
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setState(() => _pickupTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(_pickupTime == null ? 'Chọn thời gian' : DateFormat('dd/MM/yyyy HH:mm').format(_pickupTime!)),
                    ],
                  ),
                ),
              ),
              if (_pickupTime == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Chọn thời gian nhận hàng', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 16),

              // Thời gian giao hàng
              const Text('Thời gian giao hàng', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    if (!mounted) return;
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setState(() => _deliveryTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(_deliveryTime == null ? 'Chọn thời gian' : DateFormat('dd/MM/yyyy HH:mm').format(_deliveryTime!)),
                    ],
                  ),
                ),
              ),
              if (_deliveryTime == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Chọn thời gian giao hàng', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 20),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ℹ️ Lưu ý:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text(
                      '• Chuyến của bạn sẽ được public để các chủ hàng có thể tham gia\n'
                      '• Bạn sẽ nhận được thông báo khi có shipper join\n'
                      '• Chuyến sẽ tự động full khi đủ số shipper',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nút tạo
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Tạo chuyến ghép hàng',
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && _pickupTime != null && _deliveryTime != null) {
                      // TODO: Get current driver info from AuthService
                      final trip = await EmptyTripService.createEmptyTrip(
                        driverId: '0987654321',
                        driverName: 'Tài xế Nguyễn Văn Nam',
                        driverPhone: '0987654321',
                        from: _selectedFrom!,
                        to: _selectedTo!,
                        containerType: _selectedContainer!,
                        capacity: _selectedCapacity!,
                        proposedPrice: _proposedPrice!,
                        pickupTime: _pickupTime!,
                        deliveryTime: _deliveryTime!,
                        maxShippers: int.parse(_maxShippers!),
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Tạo chuyến thành công! ID: ${trip.id}'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.pop(context, trip);
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
