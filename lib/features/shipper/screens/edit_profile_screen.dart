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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
    companyController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('user_name') ?? '';
      phoneController.text = prefs.getString('user_phone') ?? '';
      addressController.text = prefs.getString('address') ?? '';
      companyController.text = prefs.getString('company') ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', nameController.text.trim());
      // Phone is read-only for security
      await prefs.setString('address', addressController.text.trim());
      await prefs.setString('company', companyController.text.trim());

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
