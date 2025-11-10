import 'package:flutter/material.dart';

class RegisterScreen1 extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();

  RegisterScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Số điện thoại'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Chúng tôi sẽ gửi mã xác nhận qua số điện thoại của bạn',
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Image.asset('assets/icons/vietnam_flag.webp', width: 24),
                    const SizedBox(width: 8),
                    const Text('+84'),
                    const SizedBox(width: 8),
                  ],
                ),
                hintText: 'Nhập số điện thoại',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/register2');
              },
              child: const Text('Tiếp tục'),
            ),
            const Spacer(),
            const Text(
              'Khi tiếp tục, bạn chấp nhận Điều khoản và Chính sách của chúng tôi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
