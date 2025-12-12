// lib/features/driver/screens/edit_profile_screen.dart
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
  late TextEditingController vehicleTypeController;
  late TextEditingController licensePlateController;
  late TextEditingController idNumberController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    vehicleTypeController = TextEditingController();
    licensePlateController = TextEditingController();
    idNumberController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('user_name') ?? '';
      phoneController.text = prefs.getString('user_phone') ?? '';
      vehicleTypeController.text = prefs.getString('vehicle_type') ?? '';
      licensePlateController.text = prefs.getString('license_plate') ?? '';
      idNumberController.text = prefs.getString('id_number') ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', nameController.text.trim());
      // Phone is read-only for security
      await prefs.setString('vehicle_type', vehicleTypeController.text.trim());
      await prefs.setString('license_plate', licensePlateController.text.trim().toUpperCase());
      await prefs.setString('id_number', idNumberController.text.trim());

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
              userId: phoneController.text,
              userType: 'driver',
              documentType: DocumentTypes.idCardFront,
              documentLabel: 'CCCD/CMND (Mặt trước)',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: phoneController.text,
              userType: 'driver',
              documentType: DocumentTypes.idCardBack,
              documentLabel: 'CCCD/CMND (Mặt sau)',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: phoneController.text,
              userType: 'driver',
              documentType: DocumentTypes.vehicleRegistration,
              documentLabel: 'Giấy đăng ký xe',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: phoneController.text,
              userType: 'driver',
              documentType: DocumentTypes.driverLicenseFront,
              documentLabel: 'Giấy phép lái xe (Mặt trước)',
              onDocumentChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            DocumentUploadWidget(
              userId: phoneController.text,
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
