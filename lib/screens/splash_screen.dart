import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Minimal loading screen shown during bootstrap
class SplashLoadingScreen extends StatelessWidget {
  const SplashLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // MH Logo
            Image.asset(
              'assets/icon.png',
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 24),
            const Text(
              'Mana Hospital',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bhimavaram\'s Trusted Care',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: AppColors.medicalBlue,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
