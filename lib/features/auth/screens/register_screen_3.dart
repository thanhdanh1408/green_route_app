import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class RegisterScreen3 extends StatelessWidget {
  const RegisterScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Chứng minh thư / Thẻ căn cước')),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          children: [
            _buildUploadBox('Mặt trước, bao gồm ảnh và thông tin'),
            const SizedBox(height: 20),
            _buildUploadBox('Mặt sau, bao gồm số CCCD và họ tên'),
            const Spacer(),
            CustomButton(
              label: 'Lưu',
              onPressed: () => Navigator.pushNamed(context, '/bank_link'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 50, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyle.body)),
          ElevatedButton(
            onPressed: () {},
            style: AppTheme.roundedButtonStyle(
              backgroundColor: AppColors.primary,
              radius: 12, // BẮT BUỘC PHẢI CÓ
              shadowElevation: 4,
            ),
            child: const Text(
              'Tải lên',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}