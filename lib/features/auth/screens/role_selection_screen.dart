import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/login')),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bạn là ai ?',
              style: AppTextStyle.headline2.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            CustomButton(
              label: 'Chủ hàng',
              leading: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/register_shipper'),
            ),
            const SizedBox(height: 30),
            CustomButton(
              label: 'Tài xế',
              leading: const Icon(Icons.directions_car, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/register_driver'),
            ),
          ],
        ),
      ),
    );
  }
}