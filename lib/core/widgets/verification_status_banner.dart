// lib/core/widgets/verification_status_banner.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/verification_service.dart';

class VerificationStatusBanner extends StatefulWidget {
  final String userId;
  final String userType;
  final VoidCallback? onTapEditProfile;

  const VerificationStatusBanner({
    super.key,
    required this.userId,
    required this.userType,
    this.onTapEditProfile,
  });

  @override
  State<VerificationStatusBanner> createState() => _VerificationStatusBannerState();
}

class _VerificationStatusBannerState extends State<VerificationStatusBanner> {
  final _verificationService = VerificationService();
  Map<String, dynamic>? _status;
  bool _isLoading = true;
  bool _isDismissed = false;
  bool _showBanner = true; // Check if user has dismissed banner

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _checkBannerDismissed();
  }

  Future<void> _checkBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('verification_banner_dismissed_${widget.userId}') ?? false;
    setState(() {
      _isDismissed = dismissed;
    });
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('verification_banner_dismissed_${widget.userId}', true);
    setState(() => _isDismissed = true);
  }

  Future<void> _showBannerAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('verification_banner_dismissed_${widget.userId}');
    setState(() => _isDismissed = false);
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    final status = await _verificationService.getUserVerificationStatus(
      widget.userId,
      widget.userType,
    );
    setState(() {
      _status = status;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _status == null || _isDismissed) {
      return const SizedBox.shrink();
    }

    final isVerified = _status!['isVerified'] as bool;
    final totalRequired = _status!['totalRequired'] as int;
    final approvedCount = _status!['approvedCount'] as int;
    final pendingCount = _status!['pendingCount'] as int;
    final rejectedCount = _status!['rejectedCount'] as int;

    // If fully verified and no banner was dismissed, show success (once)
    if (isVerified) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tài khoản đã xác minh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bạn có thể sử dụng đầy đủ tính năng của app',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _isDismissed = true),
              color: Colors.green.shade700,
            ),
          ],
        ),
      );
    }

    // If has rejected documents
    if (rejectedCount > 0) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tài liệu bị từ chối',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$rejectedCount tài liệu cần upload lại. Vui lòng kiểm tra lý do và upload lại.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onTapEditProfile,
              child: const Text('Xem'),
            ),
          ],
        ),
      );
    }

    // If has pending documents
    if (pendingCount > 0) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.pending, color: Colors.orange.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đang chờ xác minh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pendingCount/$totalRequired tài liệu đang được Admin xem xét',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // If not submitted any documents yet
    if (approvedCount == 0 && pendingCount == 0) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.amber.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cần xác minh tài khoản',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vui lòng upload $totalRequired tài liệu để được Admin xác minh',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onTapEditProfile,
              child: const Text('Upload'),
            ),
          ],
        ),
      );
    }

    // If all documents are submitted (pending + approved), banner is dismissed automatically
    // User won't see the banner unless there's a rejection or they request re-verification
    return const SizedBox.shrink();
  }
}
