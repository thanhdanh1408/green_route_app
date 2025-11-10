import 'package:flutter/material.dart';

class ForgotPasswordScreen2 extends StatelessWidget {
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  ForgotPasswordScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text("Đặt lại mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Nhập mật khẩu mới của bạn"),
            const SizedBox(height: 20),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Mật khẩu mới",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Nhập lại mật khẩu",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đặt lại mật khẩu thành công")),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Xác nhận"),
            ),
          ],
        ),
      ),
    );
  }
}
