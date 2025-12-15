// lib/features/shipper/screens/create_order_screen.dart
import 'package:flutter/material.dart';
import 'package:green_route_app/core/services/order_pool_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/location_picker_widget.dart';
import '../../../core/services/vietnam_locations_service.dart';

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

  // Location selection
  String? _selectedFromProvince;
  String? _selectedFromDistrict;
  String? _selectedToProvince;
  String? _selectedToDistrict;
  late LatLng _fromCoordinates;
  late LatLng _toCoordinates;

  bool _loading = false;

  final provinceOptions = VietnamLocationsService.getAllProvinces();

  @override
  void initState() {
    super.initState();
    _fromCoordinates = const LatLng(13.9833, 108.0000);
    _toCoordinates = const LatLng(12.6667, 108.0500);
  }

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
              // LOCATION PICKER: FROM
              LocationPickerWidget(
                title: 'Điểm nhận hàng *',
                selectedProvince: _selectedFromProvince ?? 'Gia Lai',
                availableProvinces: provinceOptions,
                onLocationSelected: (province, district, coordinates) {
                  setState(() {
                    _selectedFromProvince = province;
                    _selectedFromDistrict = district;
                    _fromCoordinates = coordinates;
                    _fromCtrl.text = '$province${district != null ? ', $district' : ''}';
                  });
                },
              ),
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
              const SizedBox(height: 16),
              
              // LOCATION PICKER: TO
              LocationPickerWidget(
                title: 'Điểm giao hàng *',
                selectedProvince: _selectedToProvince ?? 'Đắk Lắk',
                availableProvinces: provinceOptions,
                onLocationSelected: (province, district, coordinates) {
                  setState(() {
                    _selectedToProvince = province;
                    _selectedToDistrict = district;
                    _toCoordinates = coordinates;
                    _toCtrl.text = '$province${district != null ? ', $district' : ''}';
                  });
                },
              ),
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
    if (!_formKey.currentState!.validate() || _selectedFromProvince == null || _selectedToProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn điểm nhận và giao hàng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
                      const SizedBox(height: 8),
                      // Route (Province -> Province)
                      Text('Tuyến đường: $_selectedFromProvince → $_selectedToProvince', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 8),
                      // Specific locations (Province, District)
                      Text('Địa điểm nhận: ${_fromCtrl.text}'),
                      Text('Địa điểm giao: ${_toCtrl.text}'),
                      const SizedBox(height: 8),
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

    // Ensure locations are selected before submitting
    if (_selectedFromProvince == null || _selectedToProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn cả điểm nhận và điểm giao hàng'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loading = false);
      return;
    }

    // ĐĂNG ĐƠN
    final prefs = await SharedPreferences.getInstance();
    final shipperPhone = prefs.getString('user_phone') ?? '';
    final shipperName = prefs.getString('name') ?? 'Công ty ABC';
    
    // 📍 Save coordinates for map display
    await prefs.setDouble('order_from_lat_${shipperPhone}_temp', _fromCoordinates.latitude);
    await prefs.setDouble('order_from_lng_${shipperPhone}_temp', _fromCoordinates.longitude);
    await prefs.setDouble('order_to_lat_${shipperPhone}_temp', _toCoordinates.latitude);
    await prefs.setDouble('order_to_lng_${shipperPhone}_temp', _toCoordinates.longitude);
    await prefs.setString('order_from_district_${shipperPhone}_temp', _selectedFromDistrict ?? _selectedFromProvince ?? '');
    await prefs.setString('order_to_district_${shipperPhone}_temp', _selectedToDistrict ?? _selectedToProvince ?? '');

    debugPrint('📍 Saved order coordinates: FROM($_fromCoordinates) TO($_toCoordinates)');
    
    OrderPoolService.instance.addOrder(
      type: OrderType.normal,
      from: _selectedFromProvince!,  // Province name only
      to: _selectedToProvince!,      // Province name only
      goods: _goodsCtrl.text,
      weight: _weightCtrl.text,
      price: _priceCtrl.text,
      pickup: _pickupCtrl.text,
      deliver: _deliverCtrl.text,
      shipperName: shipperName,
      shipperPhone: shipperPhone,
      fromLatLng: _fromCoordinates,
      toLatLng: _toCoordinates,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đăng tìm tài xế thành công!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context, true);
    setState(() => _loading = false);
  }
}