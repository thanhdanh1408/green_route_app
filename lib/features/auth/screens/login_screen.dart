import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_route_app/features/auth/screens/role_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm điều hướng thông minh
  void _navigateAfterLogin(Map<String, dynamic> user) async {
  final role = user['role'] as String?;
  final hasRole = user['hasRole'] as bool? ?? false;

  if (role == null || !hasRole) {
    // LẦN ĐẦU → CHỌN ROLE
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => RoleSelectionScreen(phone: _identifierController.text.trim())),
      (route) => false,
    );
    return;
  }

  switch (role) {
    case 'driver':
      final destination = user['hasRoute'] == true ? '/driver_home' : '/driver_route_selection';
      Navigator.pushNamedAndRemoveUntil(context, destination, (route) => false);
      break;
    case 'shipper':
      Navigator.pushNamedAndRemoveUntil(context, '/shipper_home', (route) => false);
      break;
    case 'admin':
      Navigator.pushNamedAndRemoveUntil(context, '/admin_home', (route) => false);
      break;
    default:
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vai trò không hợp lệ!')));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_road.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.all(AppPadding.large),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo + Tên app
                      Text(
                        'Green Route',
                        style: AppTextStyle.headline1.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chào mừng đến với Green Route\nKết nối lộ trình xanh của bạn',
                        textAlign: TextAlign.center,
                        style: AppTextStyle.body.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 50),

                      // Ô nhập số điện thoại hoặc admin
                      AuthInputField(
                        hint: 'Số điện thoại',
                        controller: _identifierController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          if (value.trim() == 'admin') return null;
                          return Validators.validatePhone(value);
                        },
                      ),
                      const SizedBox(height: AppPadding.normal),

                      // Ô mật khẩu
                      AuthInputField(
                        hint: 'Mật khẩu',
                        controller: _passwordController,
                        obscureText: true,
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 30),

                      // Nút Đăng nhập
                      CustomButton(
                        label: 'Đăng nhập',
                        loading: _isLoading,
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          setState(() => _isLoading = true);
                          final identifier = _identifierController.text.trim();
                          final password = _passwordController.text;

                          final user = await AuthService.instance.login(
                            identifier,
                            password,
                          );
                          
                          if (user != null && mounted) {
                            // Lưu thông tin user vào SharedPreferences
                            final prefs = await SharedPreferences.getInstance();
                            final normalizedPhone = identifier == 'admin' ? 'admin' : identifier.replaceAll(RegExp(r'[^0-9]'), '');
                            await prefs.setString('user_phone', normalizedPhone);
                            await prefs.setString('name', user['name'] ?? '');
                            await prefs.setString('user_role', user['role'] ?? '');
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Chào ${user['name']} 👋'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                              _navigateAfterLogin(user);
                            }
                          } else {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sai số điện thoại hoặc mật khẩu',
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                      ),

                      // Quên mật khẩu
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/forgot1'),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      // Đăng ký
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Bạn chưa có tài khoản?',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register1'),
                            child: Text(
                              'Đăng ký ngay',
                              style: TextStyle(color: AppColors.accent),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      const Text(
                        'Hoặc đăng nhập bằng',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialIcon('assets/icons/facebook.webp'),
                          const SizedBox(width: 20),
                          _socialIcon('assets/icons/google.webp'),
                          const SizedBox(width: 20),
                          _socialIcon('assets/icons/apple.webp'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: Image.asset(path, width: 50, height: 50, fit: BoxFit.cover),
    );
  }
}
