// lib/features/shipper/screens/confirm_booking_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/order_pool_service.dart';

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
    final rawPrice = widget.driver['price'].toString().replaceAll(RegExp(r'[^\d]'), '');
    _priceCtrl.text = rawPrice.isNotEmpty ? rawPrice : '0';
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
              // Thông tin tài xế
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(widget.driver['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(widget.driver['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${widget.driver['phone']}\n${widget.driver['vehicle']} • ${widget.driver['plate']}'),
                ),
              ),
              const SizedBox(height: 20),
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
              Card(
                child: CheckboxListTile(
                  title: const Text('Bảo hiểm hàng hóa (+160.000 đ)'),
                  value: _insurance,
                  onChanged: (v) => setState(() => _insurance = v ?? true),
                ),
              ),
              Card(
                child: CheckboxListTile(
                  title: const Text('Tôi cam kết hàng hóa hợp pháp'),
                  value: _agreeTerms,
                  onChanged: (v) => setState(() => _agreeTerms = v ?? true),
                ),
              ),

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
                      onPressed: (_agreeTerms && _formKey.currentState!.validate()) ? _confirmBooking : null,
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

  // FIX TRIỆT ĐỂ NULL VALUE TẠI ĐÂY
  void _confirmBooking() {
    OrderPoolService.instance.addOrder(
      type: OrderType.normal,
      from: _fromCtrl.text.trim(),
      to: _toCtrl.text.trim(),
      goods: _goodsCtrl.text.trim(),
      weight: _weightCtrl.text.trim(),
      price: _priceCtrl.text.replaceAll('.', '').trim(),
      pickup: _pickupCtrl.text.isEmpty ? 'Chưa chọn ngày' : _pickupCtrl.text,
      deliver: _deliverCtrl.text.isEmpty ? 'Chưa chọn ngày' : _deliverCtrl.text,
      shipperName: 'Chủ hàng (tôi)',
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đặt xe thành công! Đơn đã được gửi đến tài xế.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, [String? hint, TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v!.trim().isEmpty ? 'Bắt buộc nhập' : null,
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
          if (date != null) {
            controller.text = '${date.day}/${date.month}/${date.year}';
          }
        },
        validator: (v) => v!.isEmpty ? 'Vui lòng chọn ngày' : null, // BẮT BUỘC CHỌN NGÀY
      ),
    );
  }
}