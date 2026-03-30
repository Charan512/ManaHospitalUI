import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class ConnectionOverlay extends StatelessWidget {
  const ConnectionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Blur background so the user is blocked from interacting
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
          // Banner
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.paleSkyBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                  border: Border.all(color: AppColors.medicalBlue, width: 2),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.medicalBlue, strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Trying to reconnect...',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.medicalBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.medicalBlue,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () {
                        // Dismiss the overlay and unblock touches natively
                        ApiService.isOffline.value = false;
                      },
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
