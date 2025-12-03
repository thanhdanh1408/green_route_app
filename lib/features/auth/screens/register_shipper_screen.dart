import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../services/auth_service.dart';

class RegisterShipperScreen extends StatefulWidget {
  const RegisterShipperScreen({super.key});

  @override
  State<RegisterShipperScreen> createState() => _RegisterShipperScreenState();
}

class _RegisterShipperScreenState extends State<RegisterShipperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _businessLicenseController = TextEditingController();
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
    _taxIdController.dispose();
    _businessLicenseController.dispose();
    _bankController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký Chủ hàng'),
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
              const Text('Họ tên Chủ hàng/Doanh nghiệp *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: Công ty ABC',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),

              const Text('Địa chỉ *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: Tổ 2, Khu phố 5, Quy Nhơn Tây, Gia Lai',
                controller: _addressController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 16),

              const Text('Mã số thuế (nếu có)', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: 0123456789',
                controller: _taxIdController,
              ),
              const SizedBox(height: 16),

              const Text('Giấy phép kinh doanh (nếu có)', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Số giấy phép kinh doanh',
                controller: _businessLicenseController,
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
              const SizedBox(height: 16),

              const Text('Số tài khoản *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Số tài khoản',
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập số tài khoản' : null,
              ),
              const SizedBox(height: 16),

              const Text('Tên chủ tài khoản *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'VD: CONG TY ABC',
                controller: _accountNameController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên chủ tài khoản' : null,
              ),
              const SizedBox(height: 40),

              CustomButton(
                label: 'Hoàn tất Đăng ký',
                loading: _isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  if (_phone != null && _password != null) {
                    // Cập nhật vào fakeUsers của AuthService
                    final authService = AuthService.instance;
                    
                    debugPrint('=== REGISTER SHIPPER ===');
                    debugPrint('Phone: $_phone');
                    debugPrint('Password: $_password');
                    
                    // Tạo user mới trực tiếp
                    authService.fakeUsers[_phone!] = {
                      'password': _password!,
                      'role': 'shipper',
                      'hasRole': true,
                      'name': _nameController.text,
                      'address': _addressController.text,
                      'bank': _bankController.text,
                      'accountNumber': _accountNumberController.text,
                      'accountName': _accountNameController.text,
                      'idStatus': 'pending',
                      'tax_id': _taxIdController.text,
                      'business_license': _businessLicenseController.text,
                    };
                    
                    debugPrint('User created in fakeUsers');
                    debugPrint('Available users: ${authService.fakeUsers.keys.toList()}');

                    // Lưu thông tin shipper vào SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_phone', _phone!);
                    await prefs.setString('user_role', 'shipper');
                    await prefs.setString('name', _nameController.text);
                    await prefs.setString('address', _addressController.text);
                    await prefs.setString('tax_id', _taxIdController.text);
                    await prefs.setString('business_license', _businessLicenseController.text);
                    await prefs.setString('bank', _bankController.text);
                    await prefs.setString('account', _accountNumberController.text);
                    await prefs.setString('account_name', _accountNameController.text);
                    await prefs.setString('id_status', 'pending');
                    
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
