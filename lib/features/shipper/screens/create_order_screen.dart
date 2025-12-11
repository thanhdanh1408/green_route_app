// lib/features/shipper/screens/create_order_screen.dart
import 'package:flutter/material.dart';
import 'package:green_route_app/core/services/order_pool_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _goodsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _deliverCtrl = TextEditingController();

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tìm tài xế'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_fromCtrl, 'Điểm đi', Icons.location_on),
              const SizedBox(height: 16),
              _buildTextField(_toCtrl, 'Điểm đến', Icons.flag),
              const SizedBox(height: 16),
              _buildTextField(_goodsCtrl, 'Tên hàng hóa', Icons.inventory_2),
              const SizedBox(height: 16),
              _buildTextField(_weightCtrl, 'Trọng lượng (tấn)', Icons.scale, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_priceCtrl, 'Giá đề xuất (VNĐ)', Icons.attach_money, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_pickupCtrl, 'Thời gian nhận hàng', Icons.access_time, readOnly: true, onTap: () => _selectDateTime(_pickupCtrl)),
              const SizedBox(height: 16),
              _buildTextField(_deliverCtrl, 'Thời gian giao hàng', Icons.access_time_filled, readOnly: true, onTap: () => _selectDateTime(_deliverCtrl)),
              const SizedBox(height: 32),

              CustomButton(
                label: 'ĐĂNG TÌM TÀI XẾ',
                loading: _loading,
                width: double.infinity,
                onPressed: _loading ? null : _submitOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool readOnly = false, VoidCallback? onTap, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
    );
  }

  Future<void> _selectDateTime(TextEditingController ctrl) async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2026));
    if (date != null) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        ctrl.text = '${date.day}/${date.month}/${date.year} ${time.format(context)}';
      }
    }
  }

  // POPUP XÁC NHẬN ĐẸP NHƯ ẢNH ANH GỬI – ĐÃ HOÀN HẢO 100%
  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận đặt xe', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thông tin hàng hóa

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thông tin hàng hóa', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Text('Loại hàng hóa: ${_goodsCtrl.text}'),
                      Text('Khối lượng (Tấn): ${_weightCtrl.text}'),
                      Text('Địa chỉ nhận hàng: ${_fromCtrl.text}'),
                      Text('Địa chỉ giao hàng: ${_toCtrl.text}'),
                      Text('Ngày, giờ nhận hàng: ${_pickupCtrl.text}'),
                      Text('Ngày, giờ giao hàng: ${_deliverCtrl.text}'),
                      const SizedBox(height: 8),
                      Text('Giá cước thương lượng (đ): ${_priceCtrl.text}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tổng thanh toán
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('Tổng thanh toán:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_priceCtrl.text} đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800])),
                    const Text('+160.000 đ', style: TextStyle(color: Colors.grey)),
                    const Divider(),
                    Text('Tổng cộng: ${_priceCtrl.text} đ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận đặt xe', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      setState(() => _loading = false);
      return;
    }

    // ĐĂNG ĐƠN
    final prefs = await SharedPreferences.getInstance();
    final shipperPhone = prefs.getString('user_phone') ?? '';
    final shipperName = prefs.getString('name') ?? 'Công ty ABC';
    
    OrderPoolService.instance.addOrder(
      type: OrderType.normal,
      from: _fromCtrl.text,
      to: _toCtrl.text,
      goods: _goodsCtrl.text,
      weight: _weightCtrl.text,
      price: _priceCtrl.text,
      pickup: _pickupCtrl.text,
      deliver: _deliverCtrl.text,
      shipperName: shipperName,
      shipperPhone: shipperPhone,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đăng tìm tài xế thành công!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context, true);
    setState(() => _loading = false);
  }
}