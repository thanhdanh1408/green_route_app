// settings_screen.dart
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

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _accountCtrl;
  late TextEditingController _accountNameCtrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl = TextEditingController(text: prefs.getString('name') ?? 'Công ty ABC');
      _phoneCtrl = TextEditingController(text: prefs.getString('user_phone') ?? '0987654321');
      _addressCtrl = TextEditingController(text: prefs.getString('address') ?? 'Quy Nhơn Bình Định');
      _bankCtrl = TextEditingController(text: prefs.getString('bank') ?? 'Vietcombank');
      _accountCtrl = TextEditingController(text: prefs.getString('account') ?? '123xxxxxxx');
      _accountNameCtrl = TextEditingController(text: prefs.getString('account_name') ?? 'Trần C');
    });
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameCtrl.text);
    await prefs.setString('address', _addressCtrl.text);
    await prefs.setString('bank', _bankCtrl.text);
    await prefs.setString('account', _accountCtrl.text);
    await prefs.setString('account_name', _accountNameCtrl.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin thành công!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bankCtrl.dispose();
    _accountCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Widget _textField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, FormFieldValidator<String>? validator, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 12),
        ...fields,
      ],
    );
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
              const Text('Quản lý thông tin cá nhân và tài khoản ngân hàng', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 24),

              // THÔNG TIN CÁ NHÂN
              _infoSection('Thông tin cá nhân', [
                _textField(_nameCtrl, 'Tên doanh nghiệp', validator: (v) => v!.isEmpty ? 'Nhập tên doanh nghiệp' : null),
                _textField(_phoneCtrl, 'Số điện thoại', keyboardType: TextInputType.phone, readOnly: true),
                _textField(_addressCtrl, 'Địa chỉ', validator: (v) => v!.isEmpty ? 'Nhập địa chỉ' : null),
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
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
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
}
