import 'package:flutter/material.dart';

class RegisterScreen2 extends StatelessWidget {
  const RegisterScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Mã xác nhận')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Nhập mã xác nhận đã gửi qua số điện thoại'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 40,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/register3');
              },
              child: const Text('Tiếp theo'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Gửi lại mã xác nhận'),
            ),
          ],
        ),
      ),
    );
  }
}
