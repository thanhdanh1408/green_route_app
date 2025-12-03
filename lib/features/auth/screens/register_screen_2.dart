import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/custom_button.dart';
import '../widgets/otp_input_field.dart';
import '../services/auth_service.dart';

class RegisterScreen2 extends StatefulWidget {
  const RegisterScreen2({super.key});

  @override
  State<RegisterScreen2> createState() => _RegisterScreen2State();
}

class _RegisterScreen2State extends State<RegisterScreen2> {
  String? _enteredOtp;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Mã xác nhận'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã xác nhận',
              style: AppTextStyle.headline2,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập mã xác nhận đã gửi qua số điện thoại',
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
                  // Lấy số điện thoại tạm thời và tạo user vào fakeUsers
                  final prefs = await SharedPreferences.getInstance();
                  final phone = prefs.getString('temp_phone');
                  
                  if (phone != null) {
                    debugPrint('=== REGISTER SCREEN 2: Creating user in fakeUsers ===');
                    debugPrint('Phone: $phone');
                    
                    // Tạo user mới vào fakeUsers ngay lập tức
                    final authService = AuthService.instance;
                    authService.fakeUsers[phone] = {
                      'password': '', // Mật khẩu sẽ được set ở screen kế tiếp
                      'role': null,
                      'hasRole': false,
                      'hasRoute': false,
                      'name': '',
                      'address': '',
                      'bank': '',
                      'accountNumber': '',
                      'accountName': '',
                      'idStatus': 'pending',
                      'licenseStatus': 'pending',
                    };
                    
                    debugPrint('User created in fakeUsers: $phone');
                    debugPrint('Available users: ${authService.fakeUsers.keys.toList()}');
                  }
                  
                  Navigator.pushNamed(context, '/register_password');
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
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isResending
                  ? null
                  : () async {
                      setState(() => _isResending = true);
                      // Giả lập gửi lại OTP
                      await Future.delayed(const Duration(seconds: 2));
                      setState(() => _isResending = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mã OTP đã được gửi lại')),
                        );
                      }
                    },
              child: Text(
                _isResending ? 'Đang gửi...' : 'Gửi lại mã xác nhận',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
