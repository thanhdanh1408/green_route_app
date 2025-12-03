import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen1 extends StatefulWidget {
  const ForgotPasswordScreen1({super.key});

  @override
  State<ForgotPasswordScreen1> createState() => _ForgotPasswordScreen1State();
}

class _ForgotPasswordScreen1State extends State<ForgotPasswordScreen1> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Quên mật khẩu"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Quên mật khẩu?",
                style: AppTextStyle.headline2,
              ),
              const SizedBox(height: 8),
              const Text(
                "Nhập số điện thoại để nhận mã xác thực",
                style: AppTextStyle.body,
              ),
              const SizedBox(height: 30),
              AuthInputField(
                hint: "Số điện thoại",
                controller: _phoneController,
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
                label: 'Gửi mã xác nhận',
                loading: _isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);
                  final phone = _phoneController.text.trim();
                  final error = await AuthService.instance.sendOtpForForgotPassword(phone);
                  setState(() => _isLoading = false);

                  if (error == null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mã OTP đã được gửi (Mã test: 123456)'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    Navigator.pushNamed(context, '/forgot2');
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
            ],
          ),
        ),
      ),
    );
  }
}
