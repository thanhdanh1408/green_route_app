import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';

class RegisterShipperScreen extends StatelessWidget {
  const RegisterShipperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký Chủ hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Họ tên Chủ hàng/Doanh nghiệp *', style: AppTextStyle.body),
            const AuthInputField(hint: 'VD: Nguyễn Văn A'),
            const SizedBox(height: 16),
            const Text('Số điện thoại *', style: AppTextStyle.body),
            const AuthInputField(hint: 'VD: 0782xxxxxx'),
            const SizedBox(height: 16),
            const Text('Mật khẩu *', style: AppTextStyle.body),
            const AuthInputField(hint: '••••••••', obscureText: true),
            const SizedBox(height: 16),
            const Text('Địa chỉ *', style: AppTextStyle.body),
            const AuthInputField(hint: 'VD: Tổ 2, Khu phố 5, Quy Nhơn Tây, Gia Lai'),
            const SizedBox(height: 16),
            const Text('Mã số thuế (nếu có)'),
            const AuthInputField(hint: ''),
            const SizedBox(height: 16),
            const Text('Giấy phép kinh doanh (nếu có)'),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Tải lên ảnh')),
            ),
            const SizedBox(height: 40),
            CustomButton(
              label: 'Hoàn tất Đăng ký',
              onPressed: () => Navigator.pushNamed(context, '/register_complete'),
            ),
          ],
        ),
      ),
    );
  }
}