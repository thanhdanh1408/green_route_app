// lib/features/driver/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = '';
  String userPhone = '';
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Người dùng';
      userPhone = prefs.getString('user_phone') ?? '';
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => notificationsEnabled = value);
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text == confirmPasswordController.text &&
                  newPasswordController.text.length >= 6) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_password', newPasswordController.text);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đổi mật khẩu thành công!')),
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu không khớp hoặc quá ngắn!')),
                );
              }
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              
              // 🔒 PRESERVE verification documents before clearing
              final verificationDocuments = prefs.getString('verification_documents');
              debugPrint('🔒 Shipper logout: Saved documents before clear');
              
              await prefs.clear();
              
              // 🔒 RESTORE verification documents after clear
              if (verificationDocuments != null) {
                await prefs.setString('verification_documents', verificationDocuments);
                debugPrint('🔒 Shipper logout: Restored documents after clear');
              }
              
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(userPhone, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'Tài khoản'),
          _SettingsTile(icon: Icons.lock_outline, title: 'Đổi mật khẩu', onTap: _showChangePasswordDialog),
          _SettingsTile(
            icon: Icons.language,
            title: 'Ngôn ngữ',
            trailing: const Text('Tiếng Việt'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hiện chỉ hỗ trợ Tiếng Việt')),
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'Xác minh'),
          _SettingsTile(
            icon: Icons.verified_user,
            title: 'Xác minh lại tài khoản',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('user_phone') ?? '';
              // Xóa flag đã dismiss banner để hiện lại
              await prefs.remove('verification_banner_dismissed_$userId');
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Banner xác minh sẽ hiển thị lại'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'Thông báo'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Thông báo đẩy'),
            subtitle: const Text('Nhận thông báo về đơn hàng mới'),
            value: notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'Về ứng dụng'),
          _SettingsTile(icon: Icons.info_outline, title: 'Phiên bản', trailing: const Text('1.0.0'), onTap: () {}),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Điều khoản sử dụng',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xem điều khoản sử dụng'))),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Chính sách bảo mật',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xem chính sách bảo mật'))),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600])),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
