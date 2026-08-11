import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/worktrackr_empty_state.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/worktrackr_error_view.dart';
import '../model/hr_analytics_models.dart';
import '../providers/hr_analytics_providers.dart';

/// Performance tab body — Hours Leaderboard.
/// Plain widgets throughout (circular gauge, linear progress, ranked
/// cards) — no fl_chart here since none of this maps to a line/bar chart;
/// fl_chart is reserved for the Attendance tab's trend line and the
/// Efficiency tab's occurrences bar chart.
class AnalyticsPerformanceTab extends ConsumerWidget {
  const AnalyticsPerformanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(hrHoursLeaderboardProvider);

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onRefresh: () => ref.read(hrHoursLeaderboardProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          leaderboardAsync.when(
            loading: () => const _PerformanceShimmer(),
            error: (err, _) => WorkTrackrErrorView(
              title: 'Could not load performance data',
              message: 'Check your connection and try again.',
              onRetry: () =>
                  ref.read(hrHoursLeaderboardProvider.notifier).refresh(),
            ),
            data: (board) => _PerformanceContent(board: board),
          ),
        ],
      ),
    );
  }
}

class _PerformanceContent extends StatelessWidget {
  const _PerformanceContent({required this.board});

  final HoursLeaderboard board;

  @override
  Widget build(BuildContext context) {
    if (board.leaderboard.isEmpty) {
      return const _PerformanceEmptyState();
    }

    final top = board.leaderboard.take(3).toList();
    final rest = board.leaderboard.skip(3).toList();

    // Team-average hours across all leaderboard entries — used to drive
    // the linear "average hours" progress display beneath the gauge.
    final avgHours = board.leaderboard
            .map((e) => e.totalHoursWorked)
            .fold<double>(0, (a, b) => a + b) /
        board.leaderboard.length;
    // Weekly target is not provided by the backend for this endpoint;
    // 40.0 is a standard full-time-week assumption used only for the
    // progress bar's denominator, mirroring the "38.2 / 40.0" mockup.
    const weeklyTargetHours = 40.0;
    final progress = (avgHours / weeklyTargetHours).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EfficiencyGaugeCard(avgHours: avgHours, progress: progress),
        const SizedBox(height: 16),
        Text(
          'Top Contributors',
          style: AppTextStyles.headlineMd.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...top.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LeaderboardCard(entry: e, highlight: true),
            )),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'EXTENDED PERFORMANCE LIST',
            style: AppTextStyles.labelXs.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...rest.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LeaderboardCard(entry: e, highlight: false),
              )),
        ],
      ],
    );
  }
}

/// Circular "efficiency" style gauge card. Uses total hours vs. the
/// weekly target as the progress fraction — this is a display simplification
/// (the mockup's 85%/"Efficiency" figure has no direct backend field on
/// HoursLeaderboard), driven from the same team-average hours the linear
/// bar beneath it shows.
class _EfficiencyGaugeCard extends StatelessWidget {
  const _EfficiencyGaugeCard({required this.avgHours, required this.progress});

  final double avgHours;
  final double progress;

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
            'TEAM PERFORMANCE METRIC',
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
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: AppTextStyles.headlineXl.copyWith(color: cs.onSurface),
                      ),
                      Text(
                        'Efficiency',
                        style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average Hours (Wkly)',
                style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                '${avgHours.toStringAsFixed(1)} / 40.0',
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.secondary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            progress >= 1.0 ? 'Above Target' : 'Below Target',
            style: AppTextStyles.labelSm.copyWith(
              color: progress >= 1.0 ? AppColors.securitySuccess : cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entry, required this.highlight});

  final HoursLeaderboardEntry entry;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Consistency isn't a backend field on HoursLeaderboardEntry — the
    // mockup shows a "Consistency Score" per person that this endpoint
    // doesn't provide, so it's intentionally omitted rather than invented.
    return Container(
      padding: EdgeInsets.all(highlight ? 16 : 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: entry.rank <= 3
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : cs.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${entry.rank}',
              style: AppTextStyles.labelSm.copyWith(
                color: entry.rank <= 3 ? Theme.of(context).colorScheme.onSecondaryContainer : cs.onSurfaceVariant,
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
                  '${entry.totalDaysPresent} days present',
                  style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${entry.totalHoursWorked.toStringAsFixed(1)} hrs',
            style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceEmptyState extends StatelessWidget {
  const _PerformanceEmptyState();

  @override
  Widget build(BuildContext context) {
    return const WorkTrackrEmptyState(
      title: 'No Data',
      message: 'No performance data for this range.',
      icon: Icons.leaderboard_outlined,
    );
  }
}

class _PerformanceShimmer extends StatelessWidget {
  const _PerformanceShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.15);
    return Column(
      children: [
        Container(height: 260, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 16),
        Container(height: 70, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
        const SizedBox(height: 10),
        Container(height: 70, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
      ],
    );
  }
}
