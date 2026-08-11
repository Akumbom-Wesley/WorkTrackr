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

  bool get _isClockedIn {
    final s = widget.status.status?.toLowerCase();
    return s == 'present' || s == 'break' || s == 'errand' || s == 'assignment';
  }

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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelXs.copyWith(
              color: cs.outline,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: AppTextStyles.labelXs.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    final cs = Theme.of(context).colorScheme;
    final config = _configFor(cs, status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.surfaceContainerHighest),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CURRENT STATUS',
              style: AppTextStyles.labelXs.copyWith(
                color: cs.outline,
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
                      color: cs.onSurface,
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

  _StatusConfig _configFor(ColorScheme cs, String? status) {
    switch (status) {
      case 'present':
        return _StatusConfig('Present', AppColors.securitySuccess);
      case 'break':
        return _StatusConfig('On Break', AppColors.securityWarning);
      case 'errand':
        return _StatusConfig('On Errand', cs.onTertiaryContainer);
      case 'assignment':
        return _StatusConfig('On Assignment', const Color(0xFF7C3AED));
      case 'checked_out':
        return _StatusConfig('Checked Out', cs.outline);
      case 'absent':
        return _StatusConfig('Absent', cs.error);
      default:
        return _StatusConfig('Off-Duty', cs.outline);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color dotColor;
  const _StatusConfig(this.label, this.dotColor);
}
