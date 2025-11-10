import 'package:flutter/material.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/custom_button.dart';

class BankCompleteScreen extends StatelessWidget {
  const BankCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bankName = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 120),
            const SizedBox(height: 30),
            Text(
              'Bạn đã liên kết thành công với\nngân hàng $bankName',
              textAlign: TextAlign.center,
              style: AppTextStyle.headline2,
            ),
            const SizedBox(height: 50),
            CustomButton(
              label: 'Hoàn Thành',
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/login')),
            ),
          ],
        ),
      ),
    );
  }
}