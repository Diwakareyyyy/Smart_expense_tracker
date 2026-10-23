import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ai_expense_tracker/services/biometric_service.dart';

import '../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 3));

    bool loggedIn = await AuthService.instance.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      bool authenticated = await BiometricService().authenticate();

      if (authenticated) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff070B16) : const Color(0xffF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 35),
            Text(
              "Smart AI",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Expense Tracker",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Colors.greenAccent,
            ),
          ],
        ),
      ),
    );
  }
}
