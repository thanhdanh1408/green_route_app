import 'package:flutter/material.dart';

class RegisterScreen3 extends StatelessWidget {
  const RegisterScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Chứng minh thư / Thẻ căn cước')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildUploadBox('Mặt trước, bao gồm ảnh và thông tin'),
            const SizedBox(height: 20),
            _buildUploadBox('Mặt sau, bao gồm số CCCD và họ tên'),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              onPressed: () {},
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 40, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Tải lên'),
          ),
        ],
      ),
    );
  }
}
