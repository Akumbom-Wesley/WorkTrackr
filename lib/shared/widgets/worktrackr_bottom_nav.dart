import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Employee bottom nav — 4 tabs:
/// 0: Dashboard, 1: Check In, 2: History, 3: Reports
class WorkTrackrBottomNav extends StatelessWidget {
  const WorkTrackrBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 60,
      backgroundColor: AppColors.background,
      color: AppColors.primaryContainer,
      buttonBackgroundColor: AppColors.secondary,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      onTap: onTap,
      items: const [
        Icon(Icons.dashboard_rounded, size: 24, color: AppColors.onPrimary),
        Icon(Icons.fingerprint_rounded, size: 24, color: AppColors.onPrimary),
        Icon(Icons.history_rounded, size: 24, color: AppColors.onPrimary),
        Icon(Icons.analytics_rounded, size: 24, color: AppColors.onPrimary),
      ],
    );
  }
}
