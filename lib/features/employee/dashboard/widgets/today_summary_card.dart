import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/dashboard_models.dart';

/// Card showing Clock In time, Clock Out time, and hours worked today.
/// Spec §2.4: Today Summary Card.
class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({super.key, required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceMuted),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY\'S SUMMARY',
            style: AppTextStyles.labelXs.copyWith(
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  icon: Icons.login_rounded,
                  iconColor: AppColors.securitySuccess,
                  label: 'Clock In',
                  value: summary.clockIn != null
                      ? _formatTime(summary.clockIn!)
                      : '--:--',
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _StatCell(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.outline,
                  label: 'Clock Out',
                  value: summary.clockOut != null
                      ? _formatTime(summary.clockOut!)
                      : '--:--',
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _StatCell(
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.onTertiaryContainer,
                  label: 'Hours',
                  value: _formatDuration(summary.hoursWorked),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
    width: 1,
    height: 48,
    color: AppColors.surfaceMuted,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.headlineMd.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelXs.copyWith(
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }
}