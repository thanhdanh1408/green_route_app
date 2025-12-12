// lib/features/admin/screens/user_list_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/user_management_service.dart';
import '../../../core/models/user_profile.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> with SingleTickerProviderStateMixin {
  final _userManagementService = UserManagementService();
  late TabController _tabController;
  
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  List<UserProfile> _drivers = [];
  List<UserProfile> _shippers = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    final users = await _userManagementService.getAllUsers();
    
    setState(() {
      _allUsers = users;
      _filteredUsers = users;
      _drivers = users.where((u) => u.userType == 'driver').toList();
      _shippers = users.where((u) => u.userType == 'shipper').toList();
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(query.toLowerCase()) ||
                 user.userId.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Tất cả (${_allUsers.length})'),
            Tab(text: 'Tài xế (${_drivers.length})'),
            Tab(text: 'Chủ hàng (${_shippers.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc số điện thoại...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUserList(_filteredUsers),
                      _buildUserList(_drivers),
                      _buildUserList(_shippers),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<UserProfile> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Chưa có người dùng' : 'Không tìm thấy kết quả',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: users.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = users[index];
          return _UserCard(
            user: user,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailScreen(userId: user.userId),
                ),
              );
              _loadUsers();
            },
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Define colors based on user type
    Color avatarColor;
    Color badgeColor;
    IconData avatarIcon;
    
    switch (user.userType) {
      case 'driver':
        avatarColor = Colors.blue;
        badgeColor = Colors.blue;
        avatarIcon = Icons.local_shipping;
        break;
      case 'shipper':
        avatarColor = Colors.purple;
        badgeColor = Colors.purple;
        avatarIcon = Icons.business;
        break;
      case 'admin':
        avatarColor = Colors.red;
        badgeColor = Colors.red;
        avatarIcon = Icons.admin_panel_settings;
        break;
      default: // unknown
        avatarColor = Colors.grey;
        badgeColor = Colors.grey;
        avatarIcon = Icons.person_outline;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  avatarIcon,
                  color: avatarColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // User type badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.getUserTypeDisplay(),
                            style: TextStyle(
                              fontSize: 11,
                              color: badgeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.userId,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    
                    // Status badges row
                    Row(
                      children: [
                        // Verification status
                        _StatusBadge(
                          icon: user.isVerified ? Icons.verified : Icons.pending,
                          label: user.getVerificationText(),
                          color: user.isVerified ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        
                        // Active status
                        _StatusBadge(
                          icon: user.isActive ? Icons.check_circle : Icons.block,
                          label: user.getStatusText(),
                          color: user.isActive ? Colors.green : Colors.grey,
                        ),
                        
                        const Spacer(),
                        
                        // Balance
                        Text(
                          '${user.walletBalance.toStringAsFixed(0)}đ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
