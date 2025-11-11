import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen3 extends StatefulWidget {
  const ForgotPasswordScreen3({super.key});

  @override
  State<ForgotPasswordScreen3> createState() => _ForgotPasswordScreen3State();
}

class _ForgotPasswordScreen3State extends State<ForgotPasswordScreen3> {
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Đặt lại mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.lock_reset, size: 80, color: AppColors.primary),
              const SizedBox(height: 20),
              const Text(
                'Tạo mật khẩu mới',
                style: AppTextStyle.headline2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Mật khẩu phải có ít nhất 8 ký tự',
                style: AppTextStyle.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              AuthInputField(
                hint: 'Mật khẩu mới',
                controller: _newPassController,
                obscureText: true,
                validator: (v) => v!.length < 8 ? 'Mật khẩu phải ≥ 8 ký tự' : null,
              ),
              const SizedBox(height: 16),

              AuthInputField(
                hint: 'Nhập lại mật khẩu',
                controller: _confirmPassController,
                obscureText: true,
                validator: (v) {
                  if (v != _newPassController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              CustomButton(
                label: 'Hoàn tất',
                loading: _isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);
                  final success = await AuthService.instance.resetPassword(_newPassController.text);
                  setState(() => _isLoading = false);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đặt lại mật khẩu thành công!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
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