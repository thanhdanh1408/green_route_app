import 'package:flutter/material.dart';

class BankCompleteScreen extends StatelessWidget {
  const BankCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bankName = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 120),
            const SizedBox(height: 20),
            Text(
              'Bạn đã liên kết thành công với\nngân hàng ${bankName ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/login'));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Hoàn Thành',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
