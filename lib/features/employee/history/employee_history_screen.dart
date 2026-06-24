import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../dashboard/widgets/dashboard_error_view.dart';
import 'model/history_models.dart';
import 'providers/history_providers.dart';
import 'widgets/attendance_entry_card.dart';

class EmployeeHistoryScreen extends ConsumerWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: historyAsync.when(
        loading: () => const _HistoryShimmer(),
        error: (err, _) => DashboardErrorView(
          message: friendlyHistoryError(err),
          onRetry: () => ref.read(historyProvider.notifier).refresh(),
        ),
        data: (report) => _HistoryBody(report: report),
      ),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({required this.report});
  final HistoryReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = report.attendance;

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).cardTheme.color,
      onRefresh: () => ref.read(historyProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _DateRangeChips()),
          SliverToBoxAdapter(child: _SummaryHeader(report: report)),
          if (report.isFromCache)
            SliverToBoxAdapter(child: _CacheBanner()),
          if (entries.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AttendanceEntryCard(entry: entries[i]),
                  ),
                  childCount: entries.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Date range chips ───────────────────────────────────────────────────────

class _DateRangeChips extends ConsumerWidget {
  const _DateRangeChips();

  static DateRange _thisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateRange(
      from: DateTime(monday.year, monday.month, monday.day),
      to: DateTime(now.year, now.month, now.day),
    );
  }

  static DateRange _thisMonth() {
    final now = DateTime.now();
    return DateRange(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month, now.day),
    );
  }

  bool _isPresetActive(DateRange current, DateRange preset) {
    return current.from.year == preset.from.year &&
        current.from.month == preset.from.month &&
        current.from.day == preset.from.day &&
        current.to.year == preset.to.year &&
        current.to.month == preset.to.month &&
        current.to.day == preset.to.day;
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref, DateRange current) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: current.from, end: current.to),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Theme.of(context).colorScheme.onPrimary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(historyDateRangeProvider.notifier).state = DateRange(
        from: picked.start,
        to: picked.end,
      );
      ref.read(historyProvider.notifier).refresh();
    }
  }

  void _applyPreset(WidgetRef ref, DateRange preset) {
    ref.read(historyDateRangeProvider.notifier).state = preset;
    ref.read(historyProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final range = ref.watch(historyDateRangeProvider);
    final thisWeek = _thisWeek();
    final thisMonth = _thisMonth();
    final isWeekActive = _isPresetActive(range, thisWeek);
    final isMonthActive = _isPresetActive(range, thisMonth);
    final isCustomActive = !isWeekActive && !isMonthActive;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _PresetChip(
            label: 'This Week',
            isActive: isWeekActive,
            onTap: () => _applyPreset(ref, thisWeek),
          ),
          const SizedBox(width: 8),
          _PresetChip(
            label: 'This Month',
            isActive: isMonthActive,
            onTap: () => _applyPreset(ref, thisMonth),
          ),
          const SizedBox(width: 8),
          _CalendarChip(
            isActive: isCustomActive,
            onTap: () => _pickCustomRange(context, ref, range),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? cs.primary : cs.outline,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CalendarChip extends StatelessWidget {
  const _CalendarChip({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? cs.primary : cs.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Custom',
              style: AppTextStyles.labelSm.copyWith(
                color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary header ─────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.report});
  final HistoryReport report;

  @override
  Widget build(BuildContext context) {
    final hw = report.totalHoursWorked;
    final hoursLabel =
        '${hw.inHours}h ${hw.inMinutes.remainder(60).toString().padLeft(2, '0')}m';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _StatTile(
            label: 'Days Present',
            value: report.totalDaysPresent.toString(),
            icon: Icons.calendar_today_rounded,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
            context: context,
          ),
          const SizedBox(width: 12),
          _StatTile(
            label: 'Hours Worked',
            value: hoursLabel,
            icon: Icons.access_time_rounded,
            color: Theme.of(context).colorScheme.secondary,
            context: context,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.context,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelXs.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.headlineMd.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cache banner ───────────────────────────────────────────────────────────

class _CacheBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.securityWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.securityWarning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 16, color: AppColors.securityWarning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — showing last synced data.',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.securityWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 36,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No records found',
            style: AppTextStyles.headlineMd.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No attendance records for this period.',
            style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer placeholder ────────────────────────────────────────────────────

class _HistoryShimmer extends StatelessWidget {
  const _HistoryShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
