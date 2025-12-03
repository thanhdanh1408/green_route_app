import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';

class RegisterScreen1 extends StatefulWidget {
  const RegisterScreen1({super.key});

  @override
  State<RegisterScreen1> createState() => _RegisterScreen1State();
}

class _RegisterScreen1State extends State<RegisterScreen1> {
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Số điện thoại'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập số điện thoại',
                style: AppTextStyle.headline2,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chúng tôi sẽ gửi mã xác nhận qua số điện thoại của bạn',
                style: AppTextStyle.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              AuthInputField(
                hint: 'Nhập số điện thoại',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Image.asset('assets/icons/vietnam_flag.webp', width: 24),
                    const SizedBox(width: 8),
                    const Text('+84'),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              CustomButton(
                label: 'Tiếp tục',
                loading: _isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);
                  final error = await AuthService.instance.sendOtpForRegister(phoneController.text);
                  setState(() => _isLoading = false);

                  if (error == null && mounted) {
                    // Lưu số điện thoại tạm thời
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('temp_phone', phoneController.text);

                    // Thành công → chuyển sang màn OTP
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mã OTP đã được gửi (Mã test: 123456)'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    Navigator.pushNamed(context, '/register2');
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Có lỗi xảy ra'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
              ),
              const Spacer(),
              const Text(
                'Khi tiếp tục, bạn chấp nhận Điều khoản và Chính sách của chúng tôi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
