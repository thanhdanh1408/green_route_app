// lib/features/shipper/screens/confirm_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../services/booking_service.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final Map<String, dynamic> driver;
  const ConfirmBookingScreen({super.key, required this.driver});

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goodsCtrl = TextEditingController(text: 'Cà phê');
  final _weightCtrl = TextEditingController(text: '5');
  final _fromCtrl = TextEditingController(text: 'Số nhà/Đường Phường/Tỉnh');
  final _toCtrl = TextEditingController(text: 'Số nhà/Đường Phường/Tỉnh');
  final _pickupCtrl = TextEditingController();
  final _deliverCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _insurance = true;
  bool _agreeTerms = true;

  @override
  void initState() {
    super.initState();
    final priceStr = (widget.driver['price'] as String?) ?? '0';
    final cleanPrice = priceStr.replaceAll(RegExp(r'[^\d]'), '');
    _priceCtrl.text = cleanPrice.isEmpty ? '0' : cleanPrice;
  }

  @override
  void dispose() {
    _goodsCtrl.dispose();
    _weightCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _pickupCtrl.dispose();
    _deliverCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = int.tryParse(_priceCtrl.text) ?? 0;
    final total = price + (_insurance ? 160000 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đặt xe'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin hàng hóa
              const Text('Thông tin hàng hóa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _buildField(_goodsCtrl, 'Loại hàng hóa *', 'VD: Cà phê'),
              _buildField(_weightCtrl, 'Khối lượng (Tấn) *', 'VD: 5', TextInputType.number),
              _buildField(_fromCtrl, 'Địa chỉ nhận hàng *'),
              _buildField(_toCtrl, 'Địa chỉ giao hàng *'),
              _buildDateField(_pickupCtrl, 'Ngày nhận hàng *'),
              _buildDateField(_deliverCtrl, 'Ngày giao hàng *'),
              _buildField(_priceCtrl, 'Giá cước thương lượng (đ) *', '3.200.000', TextInputType.number),

              const SizedBox(height: 20),

              Card(child: CheckboxListTile(title: const Text('Bảo hiểm hàng hóa (+160.000 đ)'), value: _insurance, onChanged: (v) => setState(() => _insurance = v ?? true))),
              Card(child: CheckboxListTile(title: const Text('Tôi cam kết hàng hóa hợp pháp'), value: _agreeTerms, onChanged: (v) => setState(() => _agreeTerms = v ?? true))),

              const SizedBox(height: 20),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Tổng thanh toán', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        '${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green[800]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy bỏ'))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () {
                        if (_agreeTerms && (_formKey.currentState?.validate() ?? false)) {
                          _confirmBooking();
                        }
                      },
                      child: const Text('XÁC NHẬN ĐẶT XE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _confirmBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final shipperId = prefs.getString('user_phone') ?? '';
    final shipperName = prefs.getString('name') ?? 'Chủ hàng';
    
    final price = int.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0;
    final insuranceFee = _insurance ? 160000 : 0;
    final totalPrice = price + insuranceFee;
    
    // Gửi booking request cho tài xế
    await BookingService.createBookingRequest(
      driverId: widget.driver['phone']?.toString() ?? '',
      driverName: widget.driver['name']?.toString() ?? '',
      driverPhone: widget.driver['phone']?.toString() ?? '',
      shipperId: shipperId,
      shipperName: shipperName,
      shipperPhone: shipperId,
      from: '${widget.driver['route']?.toString().split('→')[0].trim() ?? ''}',
      to: '${widget.driver['route']?.toString().split('→').last.trim() ?? ''}',
      fromDetail: _fromCtrl.text.trim(),
      toDetail: _toCtrl.text.trim(),
      goods: _goodsCtrl.text.trim(),
      weight: _weightCtrl.text.trim(),
      price: price.toString(),
      pickupTime: _pickupCtrl.text.isEmpty ? 'Chưa chọn' : _pickupCtrl.text,
      deliverTime: _deliverCtrl.text.isEmpty ? 'Chưa chọn' : _deliverCtrl.text,
      hasInsurance: _insurance,
      insuranceFee: insuranceFee.toString(),
      totalPrice: totalPrice.toString(),
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu cầu tới tài xế!'), backgroundColor: Colors.green),
    );
  }

  Widget _buildField(TextEditingController controller, String label, [String? hint, TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Bắt buộc nhập' : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime(2026),
          );
          if (date != null) controller.text = '${date.day}/${date.month}/${date.year}';
        },
        validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng chọn ngày' : null,
      ),
    );
  }
}