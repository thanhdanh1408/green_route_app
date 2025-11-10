import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen_1.dart';
import 'screens/register_screen_2.dart';
import 'screens/register_screen_3.dart';
import 'screens/forgot_password_screen_1.dart';
import 'screens/forgot_password_screen_2.dart';
import 'screens/bank_link_screen.dart';
import 'screens/bank_complete_screen.dart';

void main() {
  runApp(const GreenRouteApp());
}

class GreenRouteApp extends StatelessWidget {
  const GreenRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Green Route',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register1': (context) => RegisterScreen1(),
        '/register2': (context) => const RegisterScreen2(),
        '/register3': (context) => const RegisterScreen3(),
        '/forgot1': (context) => ForgotPasswordScreen1(),
        '/forgot2': (context) => ForgotPasswordScreen2(),
        '/bank_link': (context) => const BankLinkScreen(),
        '/bank_complete': (context) => const BankCompleteScreen(),
      },
    );
  }
}
