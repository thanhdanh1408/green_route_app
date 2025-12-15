// lib/features/common/widgets/chatbot_fab.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../screens/chatbot_screen.dart';

class ChatbotFAB extends StatelessWidget {
  const ChatbotFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        );
      },
      tooltip: 'Trợ lý ảo',
      child: const Icon(Icons.chat_bubble_outline),
    );
  }
}
