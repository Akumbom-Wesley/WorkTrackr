import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/dashboard_models.dart';

class HoursSummaryGrid extends StatefulWidget {
  const HoursSummaryGrid({
    super.key,
    required this.summary,
    required this.status,
    this.onStatusTap,
  });

  final TodaySummary summary;
  final EmployeeStatusResponse status;
  final VoidCallback? onStatusTap;

  @override
  State<HoursSummaryGrid> createState() => _HoursSummaryGridState();
}

class _HoursSummaryGridState extends State<HoursSummaryGrid> {
  late Timer _timer;
  late Duration _elapsed;

  bool get _isClockedIn =>
      widget.status.status == 'present' ||
      widget.status.status == 'break' ||
      widget.status.status == 'errand' ||
      widget.status.status == 'assignment';

  @override
  void initState() {
    super.initState();
    _elapsed = _computeElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isClockedIn) {
        setState(() => _elapsed = _computeElapsed());
      }
    });
  }

  @override
  void didUpdateWidget(HoursSummaryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _elapsed = _computeElapsed();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration _computeElapsed() {
    final clockIn = widget.summary.clockIn;
    if (clockIn == null) return Duration.zero;
    final end = (_isClockedIn) ? DateTime.now() : (widget.summary.clockOut ?? DateTime.now());
    final d = end.difference(clockIn);
    return d.isNegative ? Duration.zero : d;
  }
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          label: "TODAY'S HOURS",
          value: _formatDuration(_elapsed),
          sub: widget.summary.clockIn != null
              ? 'Since ${_formatTime(widget.summary.clockIn!)}'
              : 'Not clocked in',
        ),
        _StatCard(
          label: 'WEEK TOTAL',
          value: _formatWeek(widget.summary.weekTotal),
          sub: 'Target: 40h',
        ),
        const _StatCard(
          label: 'OVERTIME',
          value: '--',
          sub: 'This Pay Period',
        ),
        _StatusCard(
          status: widget.status.status,
          onTap: widget.onStatusTap,
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatWeek(Duration d) {
    if (d == Duration.zero) return '--';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelXs.copyWith(
              color: AppColors.outline,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: AppTextStyles.labelXs.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, this.onTap});

  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceBase,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceMuted),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CURRENT STATUS',
              style: AppTextStyles.labelXs.copyWith(
                color: AppColors.outline,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: config.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    config.label,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _configFor(String? status) {
    switch (status) {
      case 'present':
        return const _StatusConfig('Present', AppColors.securitySuccess);
      case 'break':
        return const _StatusConfig('On Break', AppColors.securityWarning);
      case 'errand':
        return const _StatusConfig('On Errand', AppColors.onTertiaryContainer);
      case 'assignment':
        return const _StatusConfig('On Assignment', Color(0xFF7C3AED));
      case 'checked_out':
        return const _StatusConfig('Checked Out', AppColors.outline);
      case 'absent':
        return const _StatusConfig('Absent', AppColors.error);
      default:
        return const _StatusConfig('Off-Duty', AppColors.outline);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color dotColor;
  const _StatusConfig(this.label, this.dotColor);
}
