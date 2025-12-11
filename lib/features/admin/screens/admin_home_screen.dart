import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ Admin'),
      ),
      body: const Center(
        child: Text('Chào mừng Admin!'),
      ),
    );
  }
}
