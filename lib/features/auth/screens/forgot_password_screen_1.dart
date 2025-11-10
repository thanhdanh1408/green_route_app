import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/providers/forgot_password_provider.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen1 extends ConsumerStatefulWidget {
  const ForgotPasswordScreen1({super.key});

  @override
  ConsumerState<ForgotPasswordScreen1> createState() => _ForgotPasswordScreen1State();
}

class _ForgotPasswordScreen1State extends ConsumerState<ForgotPasswordScreen1> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text("Quên mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Nhập số điện thoại để nhận mã xác thực",
                textAlign: TextAlign.center,
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
                    Image.asset('assets/icons/vietnam_flag.webp', width: 24),
                    const SizedBox(width: 8),
                    const Text('+84'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              CustomButton(
                label: 'Gửi mã xác nhận',
                loading: _isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final phone = _phoneController.text.trim();
                    final success = await AuthService.instance.sendOtp(phone);
                    setState(() => _isLoading = false);

                    if (success && mounted) {
                      ref.read(forgotPhoneProvider.notifier).state = phone;
                      Navigator.pushNamed(context, '/forgot2');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Số điện thoại chưa đăng ký!')),
                      );
                    }
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