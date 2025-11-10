import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Sau 5 giây, chuyển qua login
    Timer(const Duration(seconds: 5), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(seconds: 2), // tốc độ fade
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _showSplash
            ? _buildSplash()
            : const LoginScreen(), // khi _showSplash=false, fade sang login
      ),
    );
  }

  Widget _buildSplash() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bg_road.png', fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.3)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.eco, color: Colors.green, size: 100),
              SizedBox(height: 20),
              Text(
                'Green Route',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Kết nối lộ trình xanh của bạn',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
