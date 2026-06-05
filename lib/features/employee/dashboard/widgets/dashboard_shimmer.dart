import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Skeleton loading placeholders while dashboard data is fetching.
class DashboardShimmer extends StatefulWidget {
  const DashboardShimmer({super.key});

  @override
  State<DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<DashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _block(height: 130, radius: 12),
              const SizedBox(height: 16),
              _block(height: 100, radius: 12),
              const SizedBox(height: 16),
              _block(height: 56, radius: 12),
              const SizedBox(height: 24),
              _block(height: 14, width: 120, radius: 4),
              const SizedBox(height: 12),
              _block(height: 110, radius: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block({
    required double height,
    double? width,
    double radius = 8,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}