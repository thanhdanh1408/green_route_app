import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class RegisterScreen3 extends StatefulWidget {
  const RegisterScreen3({super.key});

  @override
  State<RegisterScreen3> createState() => _RegisterScreen3State();
}

class _RegisterScreen3State extends State<RegisterScreen3> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _frontImage;
  XFile? _backImage;
  Uint8List? _frontImageBytes;
  Uint8List? _backImageBytes;

  Future<void> _pickImage(bool isFront) async {
    try {
      XFile? image;
      
      if (kIsWeb) {
        // Web: Chọn từ file
        image = await _imagePicker.pickImage(source: ImageSource.gallery);
      } else {
        // Mobile: Chụp từ camera
        image = await _imagePicker.pickImage(source: ImageSource.camera);
      }
      
      if (image != null) {
        Uint8List? imageBytes;
        if (kIsWeb) {
          imageBytes = await image.readAsBytes();
        }
        
        setState(() {
          if (isFront) {
            _frontImage = image;
            _frontImageBytes = imageBytes;
          } else {
            _backImage = image;
            _backImageBytes = imageBytes;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  bool _isFormValid() {
    if (kIsWeb) {
      return _frontImageBytes != null && _backImageBytes != null;
    } else {
      return _frontImage != null && _backImage != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Chứng minh thư / Thẻ căn cước'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tải lên ảnh căn cước',
              style: AppTextStyle.headline2,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng tải lên 2 ảnh: mặt trước và mặt sau',
              style: AppTextStyle.body,
            ),
            const SizedBox(height: 24),

            // Mặt trước
            const Text('Mặt trước *', style: AppTextStyle.body),
            const SizedBox(height: 12),
            _buildUploadBox(
              title: 'Mặt trước, bao gồm ảnh và thông tin',
              image: _frontImage,
              imageBytes: _frontImageBytes,
              onTap: () => _pickImage(true),
              isFront: true,
            ),
            const SizedBox(height: 24),

            // Mặt sau
            const Text('Mặt sau *', style: AppTextStyle.body),
            const SizedBox(height: 12),
            _buildUploadBox(
              title: 'Mặt sau, bao gồm số CCCD và họ tên',
              image: _backImage,
              imageBytes: _backImageBytes,
              onTap: () => _pickImage(false),
              isFront: false,
            ),
            const SizedBox(height: 40),

            // Thông báo lỗi nếu chưa đủ ảnh
            if (!_isFormValid())
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: AppColors.danger, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vui lòng tải lên 2 ảnh (mặt trước và mặt sau)',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đã tải lên đủ ảnh',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),

            CustomButton(
              label: 'Lưu',
              onPressed: _isFormValid()
                  ? () {
                      Navigator.pushNamed(context, '/bank_link');
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox({
    required String title,
    required XFile? image,
    required Uint8List? imageBytes,
    required VoidCallback onTap,
    required bool isFront,
  }) {
    final hasImage = kIsWeb ? imageBytes != null : image != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppColors.primary : AppColors.textSecondary,
            width: 2,
          ),
          color: hasImage ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(image!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFront) {
                            _frontImage = null;
                            _frontImageBytes = null;
                          } else {
                            _backImage = null;
                            _backImageBytes = null;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.red, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Nhấn để thay đổi',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kIsWeb ? 'Nhấn để chọn ảnh' : 'Nhấn để chụp ảnh',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}