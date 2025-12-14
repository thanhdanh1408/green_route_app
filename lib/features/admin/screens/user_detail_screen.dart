// lib/features/admin/screens/user_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/user_management_service.dart';
import '../../../core/services/verification_service.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/verification_document.dart';
import 'document_review_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> with SingleTickerProviderStateMixin {
  final _userManagementService = UserManagementService();
  final _verificationService = VerificationService();
  
  late TabController _tabController;
  UserProfile? _user;
  List<VerificationDocument> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    final user = await _userManagementService.getUserById(widget.userId);
    final documents = await _verificationService.getUserDocuments(widget.userId);
    
    setState(() {
      _user = user;
      _documents = documents;
      _isLoading = false;
    });
  }

  Future<void> _toggleActiveStatus() async {
    if (_user == null) return;

    final newStatus = !_user!.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Kích hoạt tài khoản' : 'Khóa tài khoản'),
        content: Text(
          newStatus
              ? 'Bạn có muốn kích hoạt lại tài khoản này?'
              : 'Bạn có muốn khóa tài khoản này? Người dùng sẽ không thể sử dụng app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.red,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _userManagementService.toggleUserStatus(widget.userId, newStatus);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Đã kích hoạt tài khoản' : 'Đã khóa tài khoản'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
        _loadUserData();
      }
    }
  }

  Future<void> _editUser() async {
    if (_user == null) return;

    final result = await showDialog(
      context: context,
      builder: (context) => _EditUserDialog(user: _user!),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết người dùng', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết người dùng', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Không tìm thấy người dùng')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết người dùng', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editUser,
            tooltip: 'Chỉnh sửa',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            color: Colors.grey[50],
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _user!.userType == 'driver'
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    _user!.userType == 'driver' ? Icons.local_shipping : Icons.business,
                    color: _user!.userType == 'driver' ? Colors.blue : Colors.purple,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  _user!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Phone
                Text(
                  _user!.userId,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),

                // Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(
                      label: _user!.getUserTypeDisplay(),
                      color: _user!.userType == 'driver' ? Colors.blue : Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      label: _user!.getVerificationText(),
                      color: _user!.isVerified ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active status toggle
                ElevatedButton.icon(
                  onPressed: _toggleActiveStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _user!.isActive ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(_user!.isActive ? Icons.block : Icons.check_circle),
                  label: Text(_user!.isActive ? 'Khóa tài khoản' : 'Kích hoạt'),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Thông tin'),
              Tab(text: 'Xác minh'),
              Tab(text: 'Thống kê'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildVerificationTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_user!.userType == 'driver') ...[
            _InfoRow(label: 'Loại xe', value: _user!.vehicleType ?? 'N/A'),
            _InfoRow(label: 'Biển số xe', value: _user!.licensePlate ?? 'N/A'),
            _InfoRow(label: 'CCCD/CMND', value: _user!.idNumber ?? 'N/A'),
            _InfoRow(
              label: 'Trạng thái tuyến',
              value: _user!.hasRoute == true ? 'Đã chọn tuyến' : 'Chưa chọn',
            ),
          ] else ...[
            _InfoRow(label: 'Địa chỉ', value: _user!.address ?? 'N/A'),
            _InfoRow(label: 'Công ty', value: _user!.company ?? 'N/A'),
          ],
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Số dư ví',
            value: '${_user!.walletBalance.toStringAsFixed(0)} VNĐ',
          ),
          _InfoRow(label: 'Tổng đơn hàng', value: '${_user!.totalOrders}'),
          if (_user!.averageRating != null)
            _InfoRow(label: 'Đánh giá TB', value: '${_user!.averageRating!.toStringAsFixed(1)} ⭐'),
        ],
      ),
    );
  }

  Widget _buildVerificationTab() {
    if (_documents.isEmpty) {
      return const Center(
        child: Text('Chưa có tài liệu xác minh'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = _documents[index];
        return Card(
          child: ListTile(
            leading: Icon(
              doc.status == VerificationStatus.approved
                  ? Icons.check_circle
                  : doc.status == VerificationStatus.pending
                      ? Icons.pending
                      : Icons.cancel,
              color: doc.status == VerificationStatus.approved
                  ? Colors.green
                  : doc.status == VerificationStatus.pending
                      ? Colors.orange
                      : Colors.red,
            ),
            title: Text(doc.getDocumentTypeName()),
            subtitle: Text(doc.getStatusText()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentReviewScreen(documentId: doc.id),
                ),
              ).then((_) => _loadUserData());
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatCard(
            icon: Icons.account_balance_wallet,
            label: 'Số dư ví',
            value: '${_user!.walletBalance.toStringAsFixed(0)} VNĐ',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.shopping_bag,
            label: 'Tổng đơn hàng',
            value: '${_user!.totalOrders}',
            color: Colors.blue,
          ),
          if (_user!.averageRating != null) ...[
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.star,
              label: 'Đánh giá trung bình',
              value: '${_user!.averageRating!.toStringAsFixed(1)} ⭐',
              color: Colors.amber,
            ),
          ],
          const SizedBox(height: 12),
          _StatCard(
            icon: _user!.isVerified ? Icons.verified : Icons.pending,
            label: 'Trạng thái xác minh',
            value: _user!.getVerificationText(),
            color: _user!.isVerified ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final UserProfile user;

  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _licensePlateController;
  late TextEditingController _addressController;
  late TextEditingController _companyController;
  late TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _vehicleTypeController = TextEditingController(text: widget.user.vehicleType ?? '');
    _licensePlateController = TextEditingController(text: widget.user.licensePlate ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _companyController = TextEditingController(text: widget.user.company ?? '');
    _balanceController = TextEditingController(text: widget.user.walletBalance.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vehicleTypeController.dispose();
    _licensePlateController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updates = {
      'name': _nameController.text.trim(),
      'walletBalance': double.tryParse(_balanceController.text) ?? 0.0,
    };

    if (widget.user.userType == 'driver') {
      updates['vehicleType'] = _vehicleTypeController.text.trim();
      updates['licensePlate'] = _licensePlateController.text.trim();
    } else {
      updates['address'] = _addressController.text.trim();
      updates['company'] = _companyController.text.trim();
    }

    final service = UserManagementService();
    final success = await service.updateUser(widget.user.userId, updates);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi cập nhật'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa thông tin'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên'),
                validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập tên' : null,
              ),
              if (widget.user.userType == 'driver') ...[
                TextFormField(
                  controller: _vehicleTypeController,
                  decoration: const InputDecoration(labelText: 'Loại xe'),
                ),
                TextFormField(
                  controller: _licensePlateController,
                  decoration: const InputDecoration(labelText: 'Biển số xe'),
                ),
              ] else ...[
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
                ),
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Công ty'),
                ),
              ],
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(labelText: 'Số dư ví (VNĐ)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập số dư';
                  if (double.tryParse(v) == null) return 'Số không hợp lệ';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
