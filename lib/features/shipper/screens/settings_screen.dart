// lib/features/driver/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/verification_service.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = '';
  String userPhone = '';
  String address = '';
  String company = '';
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_phone') ?? '';

    debugPrint('🔍 Shipper Settings _loadUserInfo: userId=$userId');

    // 🔒 Load from user-specific keys first
    var loadedUserName =
        userId.isNotEmpty ? prefs.getString('user_name_$userId') : null;
    debugPrint('🔍 user_name_$userId = $loadedUserName');

    // Fallback to global key
    if ((loadedUserName == null || loadedUserName.isEmpty)) {
      loadedUserName = prefs.getString('user_name');
      debugPrint('🔍 Fallback to global user_name = $loadedUserName');
    }

    // Fallback to fakeUsers if still empty
    if ((loadedUserName == null || loadedUserName.isEmpty) &&
        userId.isNotEmpty) {
      final fakeUser = AuthService.instance.fakeUsers[userId];
      if (fakeUser != null) {
        loadedUserName = fakeUser['name'] as String?;
        debugPrint('🔍 Fallback to fakeUsers = $loadedUserName');
      }
    }

    // Load address and company with fallback
    var loadedAddress =
        userId.isNotEmpty ? prefs.getString('address_$userId') : null;
    var loadedCompany =
        userId.isNotEmpty ? prefs.getString('company_$userId') : null;

    // Fallback to global keys
    loadedAddress ??= prefs.getString('address');
    loadedCompany ??= prefs.getString('company');

    // Fallback to fakeUsers
    if ((loadedAddress == null || loadedAddress.isEmpty) && userId.isNotEmpty) {
      final fakeUser = AuthService.instance.fakeUsers[userId];
      if (fakeUser != null && fakeUser['address'] != null) {
        loadedAddress = fakeUser['address'] as String?;
      }
    }

    setState(() {
      userName = loadedUserName ?? 'Người dùng';
      userPhone = userId;
      address = loadedAddress ?? '';
      company = loadedCompany ?? '';
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });

    debugPrint('✅ Shipper Settings loaded: userName=$userName');
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
              if (newPasswordController.text ==
                      confirmPasswordController.text &&
                  newPasswordController.text.length >= 6) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                    'user_password', newPasswordController.text);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đổi mật khẩu thành công!')),
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Mật khẩu không khớp hoặc quá ngắn!')),
                );
              }
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final addressController = TextEditingController(text: address);
    final companyController = TextEditingController(text: company);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  labelText: 'Công ty',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('user_phone') ?? '';

              // Save to global keys
              await prefs.setString('address', addressController.text.trim());
              await prefs.setString('company', companyController.text.trim());

              // Save to user-specific keys for persistence
              if (userId.isNotEmpty) {
                await prefs.setString(
                    'address_$userId', addressController.text.trim());
                await prefs.setString(
                    'company_$userId', companyController.text.trim());
                debugPrint(
                    '✅ Saved shipper profile to both global and user-specific keys');
              }

              if (mounted) {
                Navigator.pop(context);
                _loadUserInfo(); // Reload
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Cập nhật thông tin thành công!')),
                );
              }
            },
            child: const Text('Lưu'),
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
              // 🔒 Use AuthService.logout() to properly preserve user-specific keys
              await AuthService.instance.logout();
              debugPrint('✅ Shipper logged out using AuthService');

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
            decoration:
                BoxDecoration(color: AppColors.primary.withOpacity(0.1)),
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
                      Text(userName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(userPhone,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showEditProfileDialog,
                  tooltip: 'Chỉnh sửa',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'Thông tin chủ hàng'),
          _SettingsTile(
              icon: Icons.business,
              title: 'Công ty',
              trailing: Text(company.isEmpty ? 'Chưa cập nhật' : company),
              onTap: () {}),
          _SettingsTile(
              icon: Icons.location_on,
              title: 'Địa chỉ',
              trailing: Text(address.isEmpty ? 'Chưa cập nhật' : address),
              onTap: () {}),
          const SizedBox(height: 8),
          _SectionHeader(title: 'Tài khoản'),
          _SettingsTile(
              icon: Icons.lock_outline,
              title: 'Đổi mật khẩu',
              onTap: _showChangePasswordDialog),
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
          _ShipperVerificationDocumentsWidget(userId: userPhone),
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
          _SettingsTile(
              icon: Icons.info_outline,
              title: 'Phiên bản',
              trailing: const Text('1.0.0'),
              onTap: () {}),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Điều khoản sử dụng',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xem điều khoản sử dụng'))),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Chính sách bảo mật',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xem chính sách bảo mật'))),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
      child: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600])),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile(
      {required this.icon,
      required this.title,
      this.trailing,
      required this.onTap});

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

// Widget hiển thị trạng thái xác minh tài liệu cho Shipper
class _ShipperVerificationDocumentsWidget extends StatefulWidget {
  final String userId;
  const _ShipperVerificationDocumentsWidget({required this.userId});

  @override
  State<_ShipperVerificationDocumentsWidget> createState() =>
      _ShipperVerificationDocumentsWidgetState();
}

class _ShipperVerificationDocumentsWidgetState
    extends State<_ShipperVerificationDocumentsWidget>
    with WidgetsBindingObserver {
  final _verificationService = VerificationService();
  Map<String, dynamic>? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    if (widget.userId.isEmpty) return;

    setState(() => _isLoading = true);
    final status = await _verificationService.getUserVerificationStatus(
      widget.userId,
      'shipper',
    );
    setState(() {
      _status = status;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _status == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: CircularProgressIndicator(),
      );
    }

    final approvedCount = _status!['approvedCount'] as int;
    final pendingCount = _status!['pendingCount'] as int;
    final rejectedCount = _status!['rejectedCount'] as int;
    final totalRequired = _status!['totalRequired'] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trạng thái xác minh tài liệu',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DocumentStatusBadge(
                icon: Icons.check_circle,
                label: 'Đã duyệt',
                count: approvedCount,
                color: Colors.green,
              ),
              _DocumentStatusBadge(
                icon: Icons.pending,
                label: 'Chờ duyệt',
                count: pendingCount,
                color: Colors.orange,
              ),
              _DocumentStatusBadge(
                icon: Icons.cancel,
                label: 'Bị từ chối',
                count: rejectedCount,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Tổng: $approvedCount + $pendingCount + $rejectedCount / $totalRequired',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentStatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _DocumentStatusBadge({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
