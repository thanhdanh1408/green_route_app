// lib/features/admin/screens/transaction_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/transaction_request_service.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/models/transaction_request.dart';
import '../../../core/theme/app_theme.dart';

class TransactionRequestsScreen extends StatefulWidget {
  const TransactionRequestsScreen({super.key});

  @override
  State<TransactionRequestsScreen> createState() =>
      _TransactionRequestsScreenState();
}

class _TransactionRequestsScreenState extends State<TransactionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TransactionRequest> _pendingRequests = [];
  List<TransactionRequest> _allRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    final pending = await TransactionRequestService.getPendingRequests();
    
    // Load all requests for processed tab
    final prefs = await SharedPreferences.getInstance();
    final requestsJson = prefs.getStringList('transaction_requests') ?? [];
    final allRequests = requestsJson
        .map((json) => TransactionRequest.fromJson(
            jsonDecode(json) as Map<String, dynamic>))
        .toList();
    
    setState(() {
      _pendingRequests = pending;
      _allRequests = allRequests;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yêu cầu nạp/rút tiền',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Nạp tiền'),
            Tab(text: 'Rút tiền'),
            Tab(text: 'Đã xử lý'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList('deposit'),
          _buildRequestList('withdraw'),
          _buildProcessedList(),
        ],
      ),
    );
  }

  Widget _buildRequestList(String type) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final requests = _pendingRequests
        .where((req) => req.type == type && req.status == 'pending')
        .toList();

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'deposit' ? Icons.upload : Icons.money_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có yêu cầu nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return type == 'deposit'
              ? _buildDepositRequestCard(req)
              : _buildWithdrawRequestCard(req);
        },
      ),
    );
  }

  Widget _buildDepositRequestCard(TransactionRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Yêu cầu nạp tiền',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        WalletService.formatCurrency(request.amount),
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Người dùng:', request.userId),
                _buildInfoRow(
                  'Thời gian:',
                  DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thông tin ngân hàng:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Ngân hàng:', request.bankName ?? '-'),
                _buildInfoRow('STK:', request.accountNumber ?? '-'),
                _buildInfoRow('Chủ tài khoản:', request.accountHolder ?? '-'),
              ],
            ),
          ),
          if (request.proofImageBase64 != null &&
              request.proofImageBase64!.isNotEmpty)
            Column(
              children: [
                Divider(height: 0, color: Colors.grey[300]),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Biên lai chuyển khoản:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Image.memory(
                                base64Decode(request.proofImageBase64!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: Image.memory(
                            base64Decode(request.proofImageBase64!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          Divider(height: 0, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(request.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(request),
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawRequestCard(TransactionRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Yêu cầu rút tiền',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        WalletService.formatCurrency(request.amount),
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Người dùng:', request.userId),
                _buildInfoRow(
                  'Thời gian:',
                  DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thông tin ngân hàng:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Ngân hàng:', request.bankName ?? '-'),
                _buildInfoRow('STK:', request.accountNumber ?? '-'),
                _buildInfoRow('Chủ tài khoản:', request.accountHolder ?? '-'),
              ],
            ),
          ),
          Divider(height: 0, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(request.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(request),
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(TransactionRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt yêu cầu?'),
        content: Text(
          'Số tiền: ${WalletService.formatCurrency(request.amount)}\nNgười dùng: ${request.userId}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await TransactionRequestService.approveRequest(
        request.id,
        notes: 'Đã duyệt',
      );

      if (success) {
        if (request.type == 'deposit') {
          // Cộng tiền vào ví
          await WalletService.topUp(request.userId, request.amount);
        } else {
          // Trừ tiền từ ví
          await WalletService.withdraw(request.userId, request.amount);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã duyệt yêu cầu')),
          );
          _loadRequests();
        }
      }
    }
  }

  Future<void> _showRejectDialog(String requestId) async {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Lý do từ chối',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do')),
                );
                return;
              }

              final success = await TransactionRequestService.rejectRequest(
                requestId,
                reasonController.text,
              );

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã từ chối yêu cầu')),
                );
                _loadRequests();
              }
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final processed = _allRequests
        .where((req) => req.status != 'pending')
        .toList();

    if (processed.isEmpty) {
      return const Center(
        child: Text('Chưa có yêu cầu nào được xử lý'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: processed.length,
        itemBuilder: (context, index) {
          final req = processed[index];
          final isApproved = req.status == 'approved';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        req.type == 'deposit' ? 'Nạp tiền' : 'Rút tiền',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isApproved ? 'Đã duyệt' : 'Từ chối',
                          style: TextStyle(
                            color: isApproved
                                ? Colors.green[900]
                                : Colors.red[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Người dùng:', req.userId),
                  _buildInfoRow(
                    'Số tiền:',
                    WalletService.formatCurrency(req.amount),
                  ),
                  _buildInfoRow(
                    'Ngày yêu cầu:',
                    DateFormat('dd/MM/yyyy HH:mm').format(req.createdAt),
                  ),
                  if (req.approvedAt != null)
                    _buildInfoRow(
                      'Ngày xử lý:',
                      DateFormat('dd/MM/yyyy HH:mm').format(req.approvedAt!),
                    ),
                  if (req.adminNotes != null && req.adminNotes!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildInfoRow('Ghi chú:', req.adminNotes!),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
