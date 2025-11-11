import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class RegisterCompleteScreen extends StatelessWidget {
  const RegisterCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 120),
            const SizedBox(height: 30),
            Text(
              'Đăng ký thành công',
              style: AppTextStyle.headline2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tài khoản đang được xác minh',
              style: AppTextStyle.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            CustomButton(
              label: 'Hoàn Thành',
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/login'));
              },
            ),
          ],
        ),
      ),
    );
  }
}