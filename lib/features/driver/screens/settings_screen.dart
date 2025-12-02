// lib/features/driver/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho từng trường
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _idCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _vehicleTypeCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _accountCtrl;
  late TextEditingController _accountNameCtrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // TẢI DỮ LIỆU TỪ BỘ NHỚ
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl = TextEditingController(text: prefs.getString('name') ?? 'Nguyễn Văn A');
      _phoneCtrl = TextEditingController(text: prefs.getString('phone') ?? '0987654321');
      _idCtrl = TextEditingController(text: prefs.getString('id') ?? '0123456789');
      _plateCtrl = TextEditingController(text: prefs.getString('plate') ?? '77A-8977');
      _vehicleTypeCtrl = TextEditingController(text: prefs.getString('vehicle_type') ?? 'Xe tải nặng');
      _capacityCtrl = TextEditingController(text: prefs.getString('capacity') ?? '5 tấn');
      _areaCtrl = TextEditingController(text: prefs.getString('area') ?? 'Gia Lai');
      _bankCtrl = TextEditingController(text: prefs.getString('bank') ?? 'Techcombank');
      _accountCtrl = TextEditingController(text: prefs.getString('account') ?? '0965xxxxx');
      _accountNameCtrl = TextEditingController(text: prefs.getString('account_name') ?? 'Nguyễn Văn A');
    });
  }

  // LƯU DỮ LIỆU
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameCtrl.text);
    await prefs.setString('phone', _phoneCtrl.text);
    await prefs.setString('id', _idCtrl.text);
    await prefs.setString('plate', _plateCtrl.text);
    await prefs.setString('vehicle_type', _vehicleTypeCtrl.text);
    await prefs.setString('capacity', _capacityCtrl.text);
    await prefs.setString('area', _areaCtrl.text);
    await prefs.setString('bank', _bankCtrl.text);
    await prefs.setString('account', _accountCtrl.text);
    await prefs.setString('account_name', _accountNameCtrl.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu thông tin thành công!'), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _idCtrl.dispose();
    _plateCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _capacityCtrl.dispose();
    _areaCtrl.dispose();
    _bankCtrl.dispose();
    _accountCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Cài đặt', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quản lý thông tin cá nhân và xe', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 24),

              // THÔNG TIN CÁ NHÂN
              _infoSection('Thông tin cá nhân', [
                _textField(_nameCtrl, 'Họ và tên', validator: (v) => v!.isEmpty ? 'Nhập họ tên' : null),
                _textField(_phoneCtrl, 'Số điện thoại', keyboardType: TextInputType.phone, validator: (v) => v!.length < 10 ? 'SĐT không hợp lệ' : null),
                _textField(_idCtrl, 'CMND/CCCD', keyboardType: TextInputType.number, validator: (v) => v!.length < 9 ? 'CMND không hợp lệ' : null),
              ]),

              const SizedBox(height: 24),

              // THÔNG TIN XE
              _infoSection('Thông tin xe', [
                _textField(_plateCtrl, 'Biển số xe', validator: (v) => v!.isEmpty ? 'Nhập biển số' : null),
                _textField(_vehicleTypeCtrl, 'Loại xe'),
                _textField(_capacityCtrl, 'Tải trọng'),
                _textField(_areaCtrl, 'Khu vực hoạt động'),
              ]),

              const SizedBox(height: 24),

              // TÀI KHOẢN NGÂN HÀNG
              _infoSection('Tài khoản ngân hàng', [
                _textField(_bankCtrl, 'Ngân hàng'),
                _textField(_accountCtrl, 'Số tài khoản'),
                _textField(_accountNameCtrl, 'Chủ tài khoản'),
              ]),

              const SizedBox(height: 32),
              CustomButton(
                label: 'Lưu tất cả thay đổi',
                onPressed: _saveData,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await AuthService.instance.logout();
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> fields) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator,
      ),
    );
  }
}