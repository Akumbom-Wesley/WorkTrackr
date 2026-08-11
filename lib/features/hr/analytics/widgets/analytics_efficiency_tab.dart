import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/worktrackr_empty_state.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/worktrackr_error_view.dart';
import '../model/hr_analytics_models.dart';
import '../providers/hr_analytics_providers.dart';
import 'analytics_risk_level.dart';

/// Efficiency tab body — Late Arrivals. Risk badges (CRITICAL/ELEVATED/LOW)
/// are a derived, client-side classification (see analytics_risk_level.dart)
/// — NOT a backend field. Bar chart shows occurrences per employee for the
/// top entries; full ranked list (with risk badges) shown below it.
class AnalyticsEfficiencyTab extends ConsumerWidget {
  const AnalyticsEfficiencyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(hrEfficiencyAnalyticsProvider);

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onRefresh: () => ref.read(hrEfficiencyAnalyticsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          reportAsync.when(
            loading: () => const _EfficiencyShimmer(),
            error: (err, _) => WorkTrackrErrorView(
              title: 'Could not load efficiency data',
              message: 'Check your connection and try again.',
              onRetry: () => ref.read(hrEfficiencyAnalyticsProvider.notifier).refresh(),
            ),
            data: (data) => _EfficiencyContent(data: data),
          ),
        ],
      ),
    );
  }
}

class _EfficiencyContent extends StatelessWidget {
  const _EfficiencyContent({required this.data});

  final HrEfficiencyAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final report = data.lateArrivals;
    final compliance = data.shiftCompliance;

    if (report.lateArrivals.isEmpty && compliance.totalSessions == 0) {
      return const _EfficiencyEmptyState();
    }

    final sorted = [...report.lateArrivals]
      ..sort((a, b) => b.occurrences.compareTo(a.occurrences));
    final chartEntries = sorted.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compliance.totalSessions > 0) ...[
          _ShiftComplianceCard(compliance: compliance),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Late threshold: ${report.lateThreshold}',
                  style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (chartEntries.isNotEmpty) ...[
          _OccurrencesBarChart(entries: chartEntries),
          const SizedBox(height: 16),
          Text(
            'Late Arrivals',
            style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          ...sorted.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LateArrivalRow(entry: e),
              )),
        ],
      ],
    );
  }
}

class _OccurrencesBarChart extends StatelessWidget {
  const _OccurrencesBarChart({required this.entries});

  final List<LateArrivalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxOccurrences = entries
            .map((e) => e.occurrences)
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
          Text(
            'INCIDENTS BY EMPLOYEE',
            style: AppTextStyles.labelXs.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxOccurrences <= 0 ? 10 : maxOccurrences.toDouble(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                        final parts = entries[i].fullName.split(' ');
                        final initials = parts.length >= 2
                            ? '${parts[0][0]}${parts[1][0]}'
                            : entries[i].fullName.substring(0, entries[i].fullName.length.clamp(0, 2));
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            initials.toUpperCase(),
                            style: AppTextStyles.labelXs.copyWith(color: cs.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < entries.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].occurrences.toDouble(),
                          color: riskLevelFor(entries[i].avgMinutesLate).color,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
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

class _LateArrivalRow extends StatelessWidget {
  const _LateArrivalRow({required this.entry});

  final LateArrivalEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final risk = riskLevelFor(entry.avgMinutesLate);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Text(
              entry.fullName.isNotEmpty ? entry.fullName[0].toUpperCase() : '?',
              style: AppTextStyles.labelSm.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.occurrences} incidents · avg ${entry.avgMinutesLate.toStringAsFixed(0)}m late',
                  style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: risk.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              risk.label,
              style: AppTextStyles.labelXs.copyWith(
                color: risk.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EfficiencyEmptyState extends StatelessWidget {
  const _EfficiencyEmptyState();

  @override
  Widget build(BuildContext context) {
    return const WorkTrackrEmptyState(
      title: 'No late arrivals',
      message: 'No late arrivals for this range.',
      icon: Icons.check_circle_outline_rounded,
    );
  }
}

class _EfficiencyShimmer extends StatelessWidget {
  const _EfficiencyShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.15);
    return Column(
      children: [
        Container(height: 180, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 16),
        Container(height: 220, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 16),
        Container(height: 220, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
      ],
    );
  }
}

class _ShiftComplianceCard extends StatelessWidget {
  const _ShiftComplianceCard({required this.compliance});

  final ShiftCompliance compliance;

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
            'SHIFT COMPLIANCE',
            style: AppTextStyles.labelXs.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.securitySuccess,
                        value: compliance.onTimePct,
                        title: '${compliance.onTimePct.toStringAsFixed(0)}%',
                        radius: 20,
                        titleStyle: AppTextStyles.labelXs.copyWith(color: AppColors.onPrimary),
                      ),
                      if (compliance.lateArrivalPct > 0)
                        PieChartSectionData(
                          color: AppColors.securityWarning,
                          value: compliance.lateArrivalPct,
                          title: '${compliance.lateArrivalPct.toStringAsFixed(0)}%',
                          radius: 20,
                          titleStyle: AppTextStyles.labelXs.copyWith(color: AppColors.onPrimary),
                        ),
                      if (compliance.earlyExitPct > 0)
                        PieChartSectionData(
                          color: AppColors.securityError,
                          value: compliance.earlyExitPct,
                          title: '${compliance.earlyExitPct.toStringAsFixed(0)}%',
                          radius: 20,
                          titleStyle: AppTextStyles.labelXs.copyWith(color: AppColors.onPrimary),
                        ),
                      if (compliance.incompleteShiftPct > 0)
                        PieChartSectionData(
                          color: cs.outlineVariant,
                          value: compliance.incompleteShiftPct,
                          title: '${compliance.incompleteShiftPct.toStringAsFixed(0)}%',
                          radius: 20,
                          titleStyle: AppTextStyles.labelXs.copyWith(color: AppColors.onPrimary),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(color: AppColors.securitySuccess, label: 'On Time (${compliance.onTimeCount})'),
                    const SizedBox(height: 8),
                    _LegendRow(color: AppColors.securityWarning, label: 'Late (${compliance.lateArrivalCount})'),
                    const SizedBox(height: 8),
                    _LegendRow(color: AppColors.securityError, label: 'Early Exit (${compliance.earlyExitCount})'),
                    const SizedBox(height: 8),
                    _LegendRow(color: cs.outlineVariant, label: 'Incomplete (${compliance.incompleteShiftCount})'),
                  ],
                ),
              ),
            ],
          ),
          if (compliance.frequentEarlyExits.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Frequent Early Exits',
              style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ...compliance.frequentEarlyExits.map((e) => _EarlyExitRow(entry: e)),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});
  
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.labelSm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      ],
    );
  }
}

class _EarlyExitRow extends StatelessWidget {
  const _EarlyExitRow({required this.entry});

  final FrequentEarlyExit entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.fullName, style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(entry.erpnextEmployeeId, style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.occurrences} times', style: AppTextStyles.labelSm.copyWith(color: AppColors.securityError)),
              Text('${entry.avgMinutesEarly.toStringAsFixed(0)}m avg', style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
