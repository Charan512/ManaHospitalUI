import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  /// 1. SlotGradientCard Skeleton (For SlotLogScreen)
  static Widget buildSlotCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBorder.withValues(alpha: 0.5),
      highlightColor: AppColors.white,
      child: Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  /// 2. RecentLog Skeleton (For AdminDashboard)
  static Widget buildRecentLogSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBorder.withValues(alpha: 0.5),
      highlightColor: AppColors.white,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const CircleAvatar(backgroundColor: Colors.white),
          title: Container(height: 16, width: 120, color: Colors.white),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(height: 12, width: 80, color: Colors.white),
          ),
          trailing: Container(height: 24, width: 60, color: Colors.white),
        ),
      ),
    );
  }

  /// 3. PatientHistoryCard Skeleton (For PatientHistoryScreen)
  static Widget buildHistoryCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBorder.withValues(alpha: 0.5),
      highlightColor: AppColors.white,
      child: Container(
        height: 130, // Approximating standard card height
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox(); // Fallback
}
