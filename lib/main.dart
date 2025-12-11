import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_route_app/features/admin/screens/admin_home_screen.dart';
import 'package:green_route_app/features/shipper/screens/shipper_home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen_1.dart';
import 'features/auth/screens/register_screen_2.dart';
import 'features/auth/screens/register_password_screen.dart';
import 'features/auth/screens/register_screen_3.dart';
import 'features/auth/screens/forgot_password_screen_1.dart';
import 'features/auth/screens/forgot_password_screen_2.dart';
import 'features/auth/screens/forgot_password_screen_3.dart';
import 'features/auth/screens/change_password_screen.dart';
import 'features/auth/screens/bank_link/bank_link_screen.dart';
import 'features/auth/screens/bank_link/bank_complete_screen.dart';
import 'screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/register_shipper_screen.dart';
import 'features/auth/screens/register_driver_screen.dart';
import 'features/auth/screens/register_complete_screen.dart';
import 'features/driver/screens/driver_route_selection_screen.dart';
import 'features/driver/screens/driver_orders_screen.dart';
import 'features/driver/screens/driver_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: GreenRouteApp()));
}

class GreenRouteApp extends StatelessWidget {
  const GreenRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Green Route',
      theme: AppTheme.lightTheme(),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register1': (context) => RegisterScreen1(),
        '/register2': (context) => const RegisterScreen2(),
        '/register_password': (context) => const RegisterPasswordScreen(),
        '/register3': (context) => const RegisterScreen3(),
        '/forgot1': (context) => ForgotPasswordScreen1(),
        '/forgot2': (context) => ForgotPasswordScreen2(),
        '/forgot3': (context) => const ForgotPasswordScreen3(),
        '/change_password': (context) => const ChangePasswordScreen(),
        '/bank_link': (context) => const BankLinkScreen(),
        '/bank_complete': (context) => const BankCompleteScreen(),
        '/register_shipper': (context) => const RegisterShipperScreen(),
        '/register_driver': (context) => const RegisterDriverScreen(),
        '/register_complete': (context) => const RegisterCompleteScreen(),

        '/driver_route_selection': (context) => const DriverRouteSelectionScreen(),
        '/driver_orders': (context) => DriverOrdersScreen(),
        '/driver_home': (context) => DriverHomeScreen(),

        '/shipper_home': (context) => const ShipperHomeScreen(),
        '/admin_home': (context) => const AdminHomeScreen(),
      },
    );
  }
}
