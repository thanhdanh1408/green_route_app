import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';

class RegisterDriverScreen extends StatelessWidget {
  const RegisterDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký Tài xế'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Họ tên
            Text('Họ tên Tài xế *', style: AppTextStyle.body),
            const SizedBox(height: 8),
            const AuthInputField(hint: 'VD: Nguyễn Văn A'),
            const SizedBox(height: 16),

            // Số điện thoại
            Text('Số điện thoại *', style: AppTextStyle.body),
            const SizedBox(height: 8),
            const AuthInputField(hint: 'VD: 0782xxxxxx', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),

            // Mật khẩu
            Text('Mật khẩu *', style: AppTextStyle.body),
            const SizedBox(height: 8),
            const AuthInputField(hint: '••••••••', obscureText: true),
            const SizedBox(height: 24),

            // Thông tin xe
            Text(
              'Thông tin xe',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const AuthInputField(hint: 'Biển số xe *'),
            const SizedBox(height: 12),
            const AuthInputField(hint: 'Loại xe *'),
            const SizedBox(height: 12),
            const AuthInputField(hint: 'Tải trọng tối đa (tấn) *'),
            const SizedBox(height: 12),
            const AuthInputField(hint: 'Khu vực hoạt động chính *'),
            const SizedBox(height: 24),

            // Giấy tờ xác minh
            Text(
              'Giấy tờ xác minh',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildUploadBox('Ảnh giấy phép lái xe *'),
            const SizedBox(height: 16),
            _buildUploadBox('Ảnh mặt trước CMND/CCCD *'),
            const SizedBox(height: 40),

            // Nút hoàn tất
            CustomButton(
              label: 'Hoàn tất Đăng ký',
              onPressed: () {
                Navigator.pushNamed(context, '/register_complete');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget upload ảnh – đã fix lỗi const
  Widget _buildUploadBox(String title) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Nhấn để tải lên',
            style: TextStyle(color: AppColors.primary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}