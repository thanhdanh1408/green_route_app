// lib/features/driver/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/document_upload_widget.dart';
import '../../../core/models/verification_document.dart';
import '../../auth/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController vehicleTypeController;
  late TextEditingController licensePlateController;
  late TextEditingController idNumberController;
  late TextEditingController bankNameController;
  late TextEditingController accountNumberController;
  late TextEditingController accountHolderController;
  String _userId = '';
  
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
    vehicleTypeController = TextEditingController();
    licensePlateController = TextEditingController();
    idNumberController = TextEditingController();
    bankNameController = TextEditingController();
    accountNumberController = TextEditingController();
    accountHolderController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_phone') ?? '';
    
    // 🔒 Load from user-specific keys, fallback to fakeUsers if not found
    var userName = _userId.isNotEmpty ? prefs.getString('user_name_$_userId') : null;
    
    // Fallback to fakeUsers if user-specific key is empty
    if ((userName == null || userName.isEmpty) && _userId.isNotEmpty) {
      final fakeUser = AuthService.instance.fakeUsers[_userId];
      if (fakeUser != null) {
        userName = fakeUser['name'] as String?;
      }
    }
    
    var vehicleType = _userId.isNotEmpty ? (prefs.getString('vehicle_type_$_userId') ?? '') : '';
    var licensePlate = _userId.isNotEmpty ? (prefs.getString('license_plate_$_userId') ?? '') : '';
    var idNumber = _userId.isNotEmpty ? (prefs.getString('id_number_$_userId') ?? '') : '';
    var bankName = _userId.isNotEmpty ? (prefs.getString('bank_name_$_userId') ?? '') : '';
    var accountNumber = _userId.isNotEmpty ? (prefs.getString('account_number_$_userId') ?? '') : '';
    var accountHolder = _userId.isNotEmpty ? (prefs.getString('account_holder_$_userId') ?? '') : '';
    
    setState(() {
      nameController.text = userName ?? '';
      phoneController.text = _userId;
      vehicleTypeController.text = vehicleType;
      licensePlateController.text = licensePlate;
      idNumberController.text = idNumber;
      bankNameController.text = bankName;
      accountNumberController.text = accountNumber;
      accountHolderController.text = accountHolder;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_phone') ?? '';
      
      // Lưu vào SharedPreferences (cả global và user-specific keys)
      await prefs.setString('user_name', nameController.text.trim());
      await prefs.setString('vehicle_type', vehicleTypeController.text.trim());
      await prefs.setString('license_plate', licensePlateController.text.trim().toUpperCase());
      await prefs.setString('id_number', idNumberController.text.trim());
      await prefs.setString('bank_name', bankNameController.text.trim());
      await prefs.setString('account_number', accountNumberController.text.trim());
      await prefs.setString('account_holder', accountHolderController.text.trim());
      
      // 🔒 Lưu vào user-specific keys để admin có thể query
      if (userId.isNotEmpty) {
        await prefs.setString('user_name_$userId', nameController.text.trim());
        await prefs.setString('vehicle_type_$userId', vehicleTypeController.text.trim());
        await prefs.setString('license_plate_$userId', licensePlateController.text.trim().toUpperCase());
        await prefs.setString('id_number_$userId', idNumberController.text.trim());
        await prefs.setString('bank_name_$userId', bankNameController.text.trim());
        await prefs.setString('account_number_$userId', accountNumberController.text.trim());
        await prefs.setString('account_holder_$userId', accountHolderController.text.trim());
        debugPrint('✅ Saved profile to user-specific keys for admin query');
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
    vehicleTypeController.dispose();
    licensePlateController.dispose();
    idNumberController.dispose();
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

            // Vehicle Type
            TextFormField(
              controller: vehicleTypeController,
              decoration: const InputDecoration(
                labelText: 'Loại xe *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping),
                hintText: 'VD: Xe tải 5 tấn',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập loại xe';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // License Plate
            TextFormField(
              controller: licensePlateController,
              decoration: const InputDecoration(
                labelText: 'Biển số xe *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
                hintText: 'VD: 30A-12345',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập biển số xe';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ID Number (CMND/CCCD)
            TextFormField(
              controller: idNumberController,
              decoration: const InputDecoration(
                labelText: 'CMND/CCCD *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
                hintText: 'VD: 001234567890',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số CMND/CCCD';
                }
                if (value.length < 9 || value.length > 12) {
                  return 'CMND/CCCD phải có 9-12 số';
                }
                return null;
              },
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
              'Upload tài liệu để Admin xác minh. Bạn cần hoàn tất xác minh để có thể nhận đơn hàng.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Document uploads
            DocumentUploadWidget(
              userId: _userId,
              userType: 'driver',
              documentType: DocumentTypes.idCardFront,
              documentLabel: 'CCCD/CMND (Mặt trước)',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: _userId,
              userType: 'driver',
              documentType: DocumentTypes.idCardBack,
              documentLabel: 'CCCD/CMND (Mặt sau)',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: _userId,
              userType: 'driver',
              documentType: DocumentTypes.vehicleRegistration,
              documentLabel: 'Giấy đăng ký xe',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: _userId,
              userType: 'driver',
              documentType: DocumentTypes.driverLicenseFront,
              documentLabel: 'Giấy phép lái xe (Mặt trước)',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: _userId,
              userType: 'driver',
              documentType: DocumentTypes.driverLicenseBack,
              documentLabel: 'Giấy phép lái xe (Mặt sau)',
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
