import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/worktrackr_empty_state.dart';
import '../../../../shared/widgets/worktrackr_error_view.dart';
import '../model/hr_analytics_models.dart';
import '../providers/hr_analytics_providers.dart';

/// Attendance tab body — combines AttendanceSummary + AttendanceTrend
/// (already merged upstream into HrAttendanceAnalyticsData by the
/// provider's Future.wait). Trend rendered via fl_chart LineChart —
/// current installed API (0.69.2) uses singular `color:` on
/// LineChartBarData, not the deprecated plural `colors: [...]`.
class AnalyticsAttendanceTab extends ConsumerWidget {
  const AnalyticsAttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(hrAttendanceAnalyticsProvider);

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onRefresh: () => ref.read(hrAttendanceAnalyticsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          dataAsync.when(
            loading: () => const _AttendanceShimmer(),
            error: (err, _) => WorkTrackrErrorView(
              title: 'Could not load attendance data',
              message: 'Check your connection and try again.',
              onRetry: () =>
                  ref.read(hrAttendanceAnalyticsProvider.notifier).refresh(),
            ),
            data: (data) => _AttendanceContent(data: data),
          ),
        ],
      ),
    );
  }
}

class _AttendanceContent extends StatelessWidget {
  const _AttendanceContent({required this.data});

  final HrAttendanceAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final trend = data.trend.trend;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(summary: summary),
        const SizedBox(height: 16),
        if (trend.isEmpty)
          const _AttendanceEmptyState()
        else
          _TrendCard(points: trend),
        const SizedBox(height: 16),
        if (data.breakdown.departments.isNotEmpty)
          _DepartmentBreakdownCard(breakdown: data.breakdown),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORKFORCE ADHERENCE',
            style: AppTextStyles.labelXs.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: (summary.adherenceScore / 100).clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  Text(
                    '${summary.adherenceScore.toStringAsFixed(1)}%',
                    style: AppTextStyles.headlineXl.copyWith(color: cs.onSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatColumn(label: 'Staff', value: '${summary.totalActiveEmployees}'),
              _StatColumn(label: 'Expected', value: '${summary.expectedPersonDays}'),
              _StatColumn(label: 'Actual', value: '${summary.actualPersonDays}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatColumn(label: 'Att.', value: '${summary.attendanceRatePct.toStringAsFixed(1)}%'),
              _StatColumn(label: 'On-time', value: '${summary.onTimeRatePct.toStringAsFixed(1)}%'),
              _StatColumn(label: 'Shift', value: '${summary.shiftCompletionRatePct.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});

  final List<AttendanceTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = points
            .map((p) => p.present > p.absent ? p.present : p.absent)
            .fold<int>(0, (a, b) => a > b ? a : b) *
        1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ATTENDANCE TREND',
                style: AppTextStyles.labelXs.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: AppColors.securitySuccess, label: 'Present'),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.securityError, label: 'Absent'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 10 : maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: (points.length / 6).ceilToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= points.length) return const SizedBox.shrink();
                        final label = points[i].date.length >= 10
                            ? points[i].date.substring(5, 10)
                            : points[i].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: AppTextStyles.labelXs.copyWith(color: cs.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].present.toDouble()),
                    ],
                    isCurved: true,
                    color: AppColors.securitySuccess,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].absent.toDouble()),
                    ],
                    isCurved: true,
                    color: AppColors.securityError,
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelXs.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _AttendanceEmptyState extends StatelessWidget {
  const _AttendanceEmptyState();

  @override
  Widget build(BuildContext context) {
    return const WorkTrackrEmptyState(
      title: 'No Data',
      message: 'No trend data for this range.',
      icon: Icons.show_chart_rounded,
    );
  }
}

class _AttendanceShimmer extends StatelessWidget {
  const _AttendanceShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.15);
    return Column(
      children: [
        Container(height: 220, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 16),
        Container(height: 220, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 16),
        Container(height: 220, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
      ],
    );
  }
}

class _DepartmentBreakdownCard extends StatelessWidget {
  const _DepartmentBreakdownCard({required this.breakdown});

  final DepartmentBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEPARTMENT BREAKDOWN',
            style: AppTextStyles.labelXs.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ...breakdown.departments.map((dept) => _DeptRow(dept: dept)),
        ],
      ),
    );
  }
}

class _DeptRow extends StatelessWidget {
  const _DeptRow({required this.dept});

  final DepartmentStat dept;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rate = (dept.attendanceRatePct / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dept.department,
                style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
              ),
              Text(
                '${dept.attendanceRatePct.toStringAsFixed(1)}%',
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(
                rate >= 0.9 ? AppColors.securitySuccess : 
                rate >= 0.75 ? AppColors.securityWarning : AppColors.securityError,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${dept.presentCount} present / ${dept.absentCount} absent',
                style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
              ),
              if (dept.lateArrivalsCount > 0)
                Text(
                  '${dept.lateArrivalsCount} late (${dept.avgLateMinutes.toStringAsFixed(0)}m avg)',
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.securityWarning),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
