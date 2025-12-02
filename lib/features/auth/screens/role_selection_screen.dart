// lib/features/auth/screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String phone;
  const RoleSelectionScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_road.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.6),
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 100, color: Colors.white),
              const SizedBox(height: 30),
              Text(
                'Chào mừng bạn!',
                style: AppTextStyle.headline1.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vui lòng chọn vai trò của bạn',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              _roleCard(
                context,
                icon: Icons.person,
                title: 'Chủ hàng',
                subtitle: 'Quản lý đơn hàng, tìm tài xế',
                role: 'shipper',
              ),
              const SizedBox(height: 20),
              _roleCard(
                context,
                icon: Icons.local_shipping,
                title: 'Tài xế',
                subtitle: 'Nhận đơn, giao hàng, kiếm tiền',
                role: 'driver',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required String role}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final success = await AuthService.instance.updateRole(phone, role);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã chọn vai trò: $title'), backgroundColor: AppColors.primary),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              role == 'shipper' ? '/shipper_home' : '/driver_home',
              (route) => false,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.primary, radius: 30, child: Icon(icon, size: 30, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}