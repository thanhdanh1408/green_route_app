// lib/features/shipper/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/document_upload_widget.dart';
import '../../../core/models/verification_document.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController companyController;
  late TextEditingController bankNameController;
  late TextEditingController accountNumberController;
  late TextEditingController accountHolderController;
  
  // Popular Vietnamese banks
  static const List<String> vietnameseBanks = [
    'Vietcombank',
    'Techcombank',
    'Agribank',
    'BIDV',
    'Sacombank',
    'VP Bank',
    'ACB',
    'Đông Á Bank',
    'TPBank',
    'MB Bank',
    'LienVietPostBank',
    'Kienlongbank',
    'SHB',
    'OceanBank',
    'SeABank',
    'PG Bank',
    'NCB',
    'Eximbank',
    'VietinBank',
    'VIB',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
    companyController = TextEditingController();
    bankNameController = TextEditingController();
    accountNumberController = TextEditingController();
    accountHolderController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_phone') ?? '';
    
    // 🔒 Load from user-specific keys, fallback to global keys
    var userName = userId.isNotEmpty ? prefs.getString('user_name_$userId') : null;
    var address = userId.isNotEmpty ? prefs.getString('address_$userId') : null;
    var company = userId.isNotEmpty ? prefs.getString('company_$userId') : null;
    var bankName = userId.isNotEmpty ? prefs.getString('bank_name_$userId') : null;
    var accountNumber = userId.isNotEmpty ? prefs.getString('account_number_$userId') : null;
    var accountHolder = userId.isNotEmpty ? prefs.getString('account_holder_$userId') : null;
    
    // Fallback to global keys
    userName ??= prefs.getString('user_name');
    address ??= prefs.getString('address');
    company ??= prefs.getString('company');
    bankName ??= prefs.getString('bank_name');
    accountNumber ??= prefs.getString('account_number');
    accountHolder ??= prefs.getString('account_holder');
    
    setState(() {
      nameController.text = userName ?? '';
      phoneController.text = userId;
      addressController.text = address ?? '';
      companyController.text = company ?? '';
      bankNameController.text = bankName ?? '';
      accountNumberController.text = accountNumber ?? '';
      accountHolderController.text = accountHolder ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_phone') ?? '';
      
      // Save to global keys
      await prefs.setString('user_name', nameController.text.trim());
      await prefs.setString('address', addressController.text.trim());
      await prefs.setString('company', companyController.text.trim());
      await prefs.setString('bank_name', bankNameController.text.trim());
      await prefs.setString('account_number', accountNumberController.text.trim());
      await prefs.setString('account_holder', accountHolderController.text.trim());
      
      // 🔒 Also save to user-specific keys for consistency with admin queries
      if (userId.isNotEmpty) {
        await prefs.setString('user_name_$userId', nameController.text.trim());
        await prefs.setString('address_$userId', addressController.text.trim());
        await prefs.setString('company_$userId', companyController.text.trim());
        await prefs.setString('bank_name_$userId', bankNameController.text.trim());
        await prefs.setString('account_number_$userId', accountNumberController.text.trim());
        await prefs.setString('account_holder_$userId', accountHolderController.text.trim());
        debugPrint('✅ Saved shipper profile to both global and user-specific keys');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes were saved
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    companyController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập họ tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone (read-only)
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                suffixIcon: Icon(Icons.lock, size: 18),
                helperText: 'Số điện thoại không thể thay đổi',
              ),
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'VD: 123 Đường ABC, Quận 1, TP.HCM',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa chỉ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Company (optional)
            TextFormField(
              controller: companyController,
              decoration: const InputDecoration(
                labelText: 'Công ty (không bắt buộc)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
                hintText: 'VD: Công ty TNHH ABC',
              ),
            ),
            const SizedBox(height: 16),

            // Bank Information Section
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            const Text(
              'Thông tin ngân hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thông tin này sẽ được sử dụng để xử lý rút tiền',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Bank Name - Dropdown
            DropdownButtonFormField<String>(
              value: bankNameController.text.isNotEmpty ? bankNameController.text : null,
              decoration: const InputDecoration(
                labelText: 'Tên ngân hàng *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              items: vietnameseBanks.map((String bank) {
                return DropdownMenuItem<String>(
                  value: bank,
                  child: Text(bank),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  if (value != null) {
                    bankNameController.text = value;
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn ngân hàng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Account Number
            TextFormField(
              controller: accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Số tài khoản *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                hintText: 'VD: 1234567890123',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số tài khoản';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Account Holder
            TextFormField(
              controller: accountHolderController,
              decoration: const InputDecoration(
                labelText: 'Chủ tài khoản *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'VD: Nguyễn Văn A',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên chủ tài khoản';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Document Verification Section
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            
            const Text(
              'Tài liệu xác minh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload tài liệu để Admin xác minh. Bạn cần hoàn tất xác minh để có thể tạo đơn hàng.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Document uploads
            DocumentUploadWidget(
              userId: phoneController.text,
              userType: 'shipper',
              documentType: DocumentTypes.idCardFront,
              documentLabel: 'CCCD/CMND (Mặt trước)',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: phoneController.text,
              userType: 'shipper',
              documentType: DocumentTypes.idCardBack,
              documentLabel: 'CCCD/CMND (Mặt sau)',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: phoneController.text,
              userType: 'shipper',
              documentType: DocumentTypes.businessLicense,
              documentLabel: 'Giấy phép kinh doanh (không bắt buộc)',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Lưu thay đổi', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
