import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/helpers/storage_helper.dart';
import '../../widgets/main_layout.dart'; // ✅ correct import
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
    startApp();
  }

  Future<void> startApp() async {
    String? token = await StorageHelper.getToken();
    String? user = await StorageHelper.getUser();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (token != null && token.isNotEmpty && user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: FadeTransition(
          opacity: controller,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/splash_logo.jpeg",
                width: 220,
              ),
              const SizedBox(height: 40),
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const LinearProgressIndicator(
                  color: AppColors.gold,
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "EXCELLENCE IN ARTISTRY",
                style: TextStyle(
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}