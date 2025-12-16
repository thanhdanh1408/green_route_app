// lib/features/shipper/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/services/transaction_request_service.dart';
import '../../../core/widgets/balance_card.dart';
import '../../../core/widgets/transaction_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/services/auth_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double balance = 0;
  List<Map<String, dynamic>> transactions = [];
  Map<String, double> earnings = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_phone') ?? '';

    final bal = await WalletService.getBalance(userId);
    final txs = await WalletService.getTransactions(userId);
    final earn = await WalletService.getEarningsSummary(userId);

    setState(() {
      balance = bal;
      transactions = txs;
      earnings = earn;
      loading = false;
    });
  }

  Future<void> _showDepositDialog() async {
    final amountController = TextEditingController();
    XFile? selectedImage;
    
    final bankInfo = await TransactionRequestService.getAdminBankInfo();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nạp tiền vào ví'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bước 1: Nhập số tiền cần nạp',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'VD: 100000',
                    suffixText: 'đ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bước 2: Chuyển khoản đến tài khoản admin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBankInfoRow('Ngân hàng:', bankInfo['bankName']!),
                      const SizedBox(height: 8),
                      _buildBankInfoRow('STK:', bankInfo['accountNumber']!),
                      const SizedBox(height: 8),
                      _buildBankInfoRow('Chủ tài khoản:', bankInfo['accountHolder']!),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bước 3: Tải ảnh biên lai chuyển khoản',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      setState(() => selectedImage = image);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedImage == null ? Colors.blue : Colors.green,
                        width: 2,
                      ),
                    ),
                    child: selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.image, color: Colors.blue, size: 40),
                              SizedBox(height: 8),
                              Text(
                                'Tải ảnh biên lai',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ],
                          )
                        : Image.file(
                            File(selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedImage != null ? '✓ Ảnh đã được chọn' : 'Chưa chọn ảnh',
                  style: TextStyle(
                    color: selectedImage != null ? Colors.green : Colors.red,
                    fontSize: 12,
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
              onPressed: selectedImage != null && amountController.text.isNotEmpty
                  ? () async {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập số tiền hợp lệ'),
                          ),
                        );
                        return;
                      }

                      // Đọc ảnh và convert thành base64
                      final imageBytes = await selectedImage!.readAsBytes();
                      final base64Image = base64Encode(imageBytes);

                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString('user_phone') ?? '';

                      if (!mounted) return;

                      final success =
                          await TransactionRequestService.createDepositRequest(
                        userId: userId,
                        amount: amount,
                        proofImageBase64: base64Image,
                      );

                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã gửi yêu cầu nạp ${WalletService.formatCurrency(amount)}. Admin sẽ xử lý trong thời gian sớm nhất.',
                            ),
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')),
                        );
                      }
                    }
                  : null,
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWithdrawDialog() async {
    final amountController = TextEditingController();
    final passwordController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rút tiền từ ví'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Số dư khả dụng: ${WalletService.formatCurrency(balance)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nhập số tiền cần rút:'),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'VD: 100000',
                  suffixText: 'đ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nhập mật khẩu tài khoản:'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Mật khẩu',
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
              final amount = double.tryParse(amountController.text) ?? 0;
              final password = passwordController.text;

              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập số tiền hợp lệ'),
                  ),
                );
                return;
              }

              if (amount > balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Số tiền rút không được vượt quá số dư'),
                  ),
                );
                return;
              }

              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập mật khẩu'),
                  ),
                );
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('user_phone') ?? '';

              // ✅ Check password from AuthService fakeUsers (the correct source)
              final authService = AuthService.instance;
              if (!authService.fakeUsers.containsKey(userId)) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không tìm thấy tài khoản'),
                    ),
                  );
                }
                return;
              }

              final userAccount = authService.fakeUsers[userId]!;
              final correctPassword = userAccount['password'] as String? ?? '';
              
              if (password != correctPassword) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mật khẩu không chính xác'),
                    ),
                  );
                }
                return;
              }

              // ✅ Load bank info from user-specific keys
              final bankName = prefs.getString('bank_name_$userId') ?? '';
              final accountNumber = prefs.getString('account_number_$userId') ?? '';
              final accountHolder = prefs.getString('account_holder_$userId') ?? '';

              if (bankName.isEmpty ||
                  accountNumber.isEmpty ||
                  accountHolder.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Chưa cập nhật thông tin ngân hàng. Vui lòng cập nhật trong phần hồ sơ.',
                      ),
                    ),
                  );
                }
                return;
              }

              final success =
                  await TransactionRequestService.createWithdrawRequest(
                userId: userId,
                amount: amount,
                bankName: bankName,
                accountNumber: accountNumber,
                accountHolder: accountHolder,
              );

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã gửi yêu cầu rút ${WalletService.formatCurrency(amount)}. Admin sẽ xử lý trong thời gian sớm nhất.',
                    ),
                  ),
                );
                _loadData();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')),
                );
              }
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ví của tôi', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví của tôi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              BalanceCard(
                balance: balance,
                onTopUp: _showDepositDialog,
                onWithdraw: _showWithdrawDialog,
              ),

              // Earnings Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Thu nhập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _EarningCard(
                            title: 'Hôm nay',
                            amount: earnings['today'] ?? 0,
                            icon: Icons.today,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EarningCard(
                            title: 'Tuần này',
                            amount: earnings['thisWeek'] ?? 0,
                            icon: Icons.calendar_view_week,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EarningCard(
                            title: 'Tháng này',
                            amount: earnings['thisMonth'] ?? 0,
                            icon: Icons.calendar_month,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Transactions Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Lịch sử giao dịch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${transactions.length} giao dịch',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Transactions List
              if (transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có giao dịch nào',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: transactions.map((tx) => TransactionCard(transaction: tx)).toList(),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _EarningCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _EarningCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            WalletService.formatCurrency(amount),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
