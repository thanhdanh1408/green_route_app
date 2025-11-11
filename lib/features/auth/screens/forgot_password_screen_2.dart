import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/otp_input_field.dart';
import '../../../core/providers/forgot_password_provider.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen2 extends ConsumerStatefulWidget {
  const ForgotPasswordScreen2({super.key});

  @override
  ConsumerState<ForgotPasswordScreen2> createState() =>
      _ForgotPasswordScreen2State();
}

class _ForgotPasswordScreen2State extends ConsumerState<ForgotPasswordScreen2> {
  final passController = TextEditingController();
  final confirmController = TextEditingController();
  bool _isLoading = false;
  String? _enteredOtp;

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(forgotPhoneProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Đặt lại mật khẩu"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          children: [
            Text("Mã OTP đã gửi đến $phone", style: AppTextStyle.body),
            const SizedBox(height: 20),
            OtpInputField(onCompleted: (otp) => _enteredOtp = otp),
            const SizedBox(height: 30),
            CustomButton(
              label: 'Xác nhận',
              loading: _isLoading,
              onPressed: () async {
                if (_enteredOtp != '123456') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mã OTP không đúng! Nhập: 123456'),
                    ),
                  );
                  return;
                }

                setState(() => _isLoading = true);
                await Future.delayed(
                  const Duration(seconds: 1),
                ); // Giả lập xác minh
                setState(() => _isLoading = false);

                if (mounted) {
                  // CHUYỂN QUA TRANG NHẬP MẬT KHẨU MỚI
                  Navigator.pushNamed(context, '/forgot3');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
