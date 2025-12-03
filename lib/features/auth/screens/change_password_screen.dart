import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Đổi mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đổi mật khẩu',
                style: AppTextStyle.headline2,
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng nhập mật khẩu cũ và mật khẩu mới',
                style: AppTextStyle.body,
              ),
              const SizedBox(height: 30),

              // Mật khẩu cũ
              const Text('Mật khẩu cũ *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Nhập mật khẩu cũ',
                controller: _oldPasswordController,
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu cũ' : null,
              ),
              const SizedBox(height: 20),

              // Mật khẩu mới
              const Text('Mật khẩu mới *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Nhập mật khẩu mới',
                controller: _newPasswordController,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 20),

              // Nhập lại mật khẩu mới
              const Text('Nhập lại mật khẩu mới *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Nhập lại mật khẩu mới',
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập lại mật khẩu';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu không trùng khớp';
                  }
                  return null;
                },
              ),
              const Spacer(),

              CustomButton(
                label: 'Đổi mật khẩu',
                loading: _isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);
                  
                  final prefs = await SharedPreferences.getInstance();
                  final phone = prefs.getString('user_phone');

                  if (phone != null) {
                    final error = await AuthService.instance.changePassword(
                      phone,
                      _oldPasswordController.text,
                      _newPasswordController.text,
                    );

                    setState(() => _isLoading = false);

                    if (error == null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đổi mật khẩu thành công!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      Navigator.pop(context);
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error ?? 'Có lỗi xảy ra'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  } else {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng đăng nhập lại'),
                          backgroundColor: AppColors.danger,
                        ),
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
