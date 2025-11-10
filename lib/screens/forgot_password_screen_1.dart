import 'package:flutter/material.dart';

class ForgotPasswordScreen1 extends StatelessWidget {
  final TextEditingController contactController = TextEditingController();

  ForgotPasswordScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text("Quên mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Nhập số điện thoại hoặc email của bạn để nhận mã xác thực",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: contactController,
              decoration: InputDecoration(
                labelText: "Số điện thoại hoặc email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/forgot2');
              },
              child: const Text("Gửi mã xác nhận"),
            ),
          ],
        ),
      ),
    );
  }
}
