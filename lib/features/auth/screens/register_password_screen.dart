import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';

class RegisterPasswordScreen extends StatefulWidget {
  const RegisterPasswordScreen({super.key});

  @override
  State<RegisterPasswordScreen> createState() => _RegisterPasswordScreenState();
}

class _RegisterPasswordScreenState extends State<RegisterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Đặt mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo mật khẩu cho tài khoản của bạn',
                style: AppTextStyle.headline2,
              ),
              const SizedBox(height: 8),
              const Text(
                'Mật khẩu cần ít nhất 8 ký tự',
                style: AppTextStyle.body,
              ),
              const SizedBox(height: 30),

              // Nhập mật khẩu
              const Text('Mật khẩu *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Nhập mật khẩu',
                controller: _passwordController,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 20),

              // Nhập lại mật khẩu
              const Text('Nhập lại mật khẩu *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Nhập lại mật khẩu',
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập lại mật khẩu';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu không trùng khớp';
                  }
                  return null;
                },
              ),
              const Spacer(),

              CustomButton(
                label: 'Tiếp tục',
                loading: _isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  // Lưu mật khẩu tạm thời vào SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  final phone = prefs.getString('temp_phone');
                  await prefs.setString('temp_password', _passwordController.text);

                  // Cập nhật mật khẩu vào fakeUsers
                  if (phone != null) {
                    final authService = AuthService.instance;
                    if (authService.fakeUsers.containsKey(phone)) {
                      authService.fakeUsers[phone]!['password'] = _passwordController.text;
                      debugPrint('=== Password set for user: $phone ===');
                      debugPrint('Password: ${_passwordController.text}');
                    }
                  }

                  setState(() => _isLoading = false);

                  // Chuyển đến trang upload CCCD
                  if (mounted) {
                    Navigator.pushNamed(context, '/register3');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
