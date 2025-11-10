import 'package:flutter/material.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/custom_button.dart';
import '../widgets/otp_input_field.dart';

class RegisterScreen2 extends StatelessWidget {
  const RegisterScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Mã xác nhận')),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          children: [
            const Text('Nhập mã xác nhận đã gửi qua số điện thoại', style: AppTextStyle.body),
            const SizedBox(height: 40),
            OtpInputField(onCompleted: (otp) {
              // TODO: verify OTP
            }),
            const SizedBox(height: 40),
            CustomButton(
              label: 'Tiếp theo',
              onPressed: () => Navigator.pushNamed(context, '/register3'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Gửi lại mã xác nhận', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}