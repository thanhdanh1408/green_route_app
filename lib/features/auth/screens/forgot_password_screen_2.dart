import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/otp_input_field.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen2 extends StatefulWidget {
  const ForgotPasswordScreen2({super.key});

  @override
  State<ForgotPasswordScreen2> createState() => _ForgotPasswordScreen2State();
}

class _ForgotPasswordScreen2State extends State<ForgotPasswordScreen2> {
  bool _isLoading = false;
  String? _enteredOtp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Xác nhận OTP"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nhập mã OTP",
              style: AppTextStyle.headline2,
            ),
            const SizedBox(height: 8),
            const Text(
              "Mã OTP đã được gửi đến số điện thoại của bạn",
              style: AppTextStyle.body,
            ),
            const SizedBox(height: 40),
            OtpInputField(onCompleted: (otp) => _enteredOtp = otp),
            const SizedBox(height: 40),
            CustomButton(
              label: 'Xác nhận',
              loading: _isLoading,
              onPressed: () async {
                if (_enteredOtp == null || _enteredOtp!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập mã OTP'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }

                setState(() => _isLoading = true);
                final isValid = await AuthService.instance.verifyOtp(_enteredOtp!);
                setState(() => _isLoading = false);

                if (isValid && mounted) {
                  Navigator.pushNamed(context, '/forgot3');
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mã OTP không đúng! Nhập: 123456'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
