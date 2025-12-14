import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../services/auth_service.dart';

class RegisterDriverScreen extends StatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _plateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _areaController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  
  bool _isLoading = false;
  String? _phone;
  String? _password;

  @override
  void initState() {
    super.initState();
    _loadDataFromPrefs();
  }

  Future<void> _loadDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phone = prefs.getString('temp_phone');
      _password = prefs.getString('temp_password');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _plateController.dispose();
    _vehicleTypeController.dispose();
    _capacityController.dispose();
    _areaController.dispose();
    _bankController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký Tài xế'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Họ tên
              const Text('Họ tên Tài xế *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: Nguyễn Văn A',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),

              // Địa chỉ
              const Text('Địa chỉ *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: Gia Lai',
                controller: _addressController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 24),

              // THÔNG TIN XE
              Text(
                'Thông tin xe',
                style: AppTextStyle.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              const Text('Biển số xe *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: 77A-8977',
                controller: _plateController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập biển số xe' : null,
              ),
              const SizedBox(height: 12),

              const Text('Loại xe *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: Xe tải nặng',
                controller: _vehicleTypeController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập loại xe' : null,
              ),
              const SizedBox(height: 12),

              const Text('Tải trọng tối đa (tấn) *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: 5',
                controller: _capacityController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tải trọng' : null,
              ),
              const SizedBox(height: 12),

              const Text('Khu vực hoạt động chính *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: Gia Lai - Dak Lak',
                controller: _areaController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập khu vực' : null,
              ),
              const SizedBox(height: 24),

              // THÔNG TIN NGÂN HÀNG
              Text(
                'Thông tin Ngân hàng',
                style: AppTextStyle.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              const Text('Tên ngân hàng *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: Techcombank',
                controller: _bankController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên ngân hàng' : null,
              ),
              const SizedBox(height: 12),

              const Text('Số tài khoản *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Số tài khoản',
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập số tài khoản' : null,
              ),
              const SizedBox(height: 12),

              const Text('Tên chủ tài khoản *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: NGUYEN VAN A',
                controller: _accountNameController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên chủ tài khoản' : null,
              ),
              const SizedBox(height: 40),

              // Nút hoàn tất
              CustomButton(
                label: 'Hoàn tất Đăng ký',
                loading: _isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  if (_phone != null && _password != null) {
                    // Cập nhật vào fakeUsers của AuthService
                    final authService = AuthService.instance;
                    
                    debugPrint('=== REGISTER DRIVER ===');
                    debugPrint('Phone: $_phone');
                    debugPrint('Password: $_password');
                    
                    // Tạo user mới trực tiếp
                    authService.fakeUsers[_phone!] = {
                      'password': _password!,
                      'role': 'driver',
                      'hasRole': true,
                      'hasRoute': false,
                      'name': _nameController.text,
                      'address': _addressController.text,
                      'plate': _plateController.text,
                      'vehicle_type': _vehicleTypeController.text,
                      'capacity': _capacityController.text,
                      'area': _areaController.text,
                      'bank': _bankController.text,
                      'accountNumber': _accountNumberController.text,
                      'accountName': _accountNameController.text,
                      'idStatus': 'pending',
                      'licenseStatus': 'pending',
                    };
                    
                    debugPrint('User created in fakeUsers');
                    debugPrint('Available users: ${authService.fakeUsers.keys.toList()}');

                    // Lưu thông tin driver vào SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_phone', _phone!);
                    await prefs.setString('user_role', 'driver');
                    await prefs.setString('name', _nameController.text);
                    await prefs.setString('area', _addressController.text);
                    await prefs.setString('plate', _plateController.text);
                    await prefs.setString('vehicle_type', _vehicleTypeController.text);
                    await prefs.setString('capacity', _capacityController.text);
                    await prefs.setString('area', _areaController.text);
                    await prefs.setString('bank', _bankController.text);
                    await prefs.setString('account', _accountNumberController.text);
                    await prefs.setString('account_name', _accountNameController.text);
                    await prefs.setString('id_status', 'pending');
                    await prefs.setString('license_status', 'pending');
                    
                    // 🔒 Lưu vào user-specific keys để admin có thể query
                    await prefs.setString('user_name_$_phone', _nameController.text.trim());
                    await prefs.setString('user_role_$_phone', 'driver');
                    await prefs.setString('vehicle_type_$_phone', _vehicleTypeController.text.trim());
                    await prefs.setString('license_plate_$_phone', _plateController.text.trim().toUpperCase());
                    await prefs.setString('id_number_$_phone', '');
                    
                    // Xóa dữ liệu tạm thời
                    await prefs.remove('temp_phone');
                    await prefs.remove('temp_password');

                    setState(() => _isLoading = false);

                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/register_complete',
                        (route) => false,
                      );
                    }
                  } else {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Có lỗi xảy ra, vui lòng thử lại'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
