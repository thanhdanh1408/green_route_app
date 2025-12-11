import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class RegisterCompleteScreen extends StatefulWidget {
  const RegisterCompleteScreen({super.key});

  @override
  State<RegisterCompleteScreen> createState() => _RegisterCompleteScreenState();
}

class _RegisterCompleteScreenState extends State<RegisterCompleteScreen> {
  String _userRole = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? '';
      _userName = prefs.getString('name') ?? 'Người dùng';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.check_circle, color: AppColors.primary, size: 120),
              const SizedBox(height: 30),
              Text(
                'Đăng ký thành công!',
                style: AppTextStyle.headline2.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Chào mừng $_userName',
                style: AppTextStyle.body.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Tài khoản đang được xác minh',
                      style: AppTextStyle.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vai trò: ${_userRole == 'driver' ? 'Tài xế' : _userRole == 'shipper' ? 'Chủ hàng' : 'Chờ xác nhận'}',
                      style: AppTextStyle.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Admin sẽ xác minh thông tin của bạn trong 1-2 ngày',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              CustomButton(
                label: 'Về đăng nhập',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}