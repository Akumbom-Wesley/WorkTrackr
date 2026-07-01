import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/hr_employee_models.dart';

/// Attendance tab: summary chips, date-range picker, and the per-day
/// attendance entry list for the selected employee.
class EmployeeAttendanceTab extends StatelessWidget {
  const EmployeeAttendanceTab({
    super.key,
    required this.history,
    required this.onChangeRange,
  });

  final HrEmployeeHistory history;
  final void Function(String from, String to) onChangeRange;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: DateTimeRange(start: history.dateFrom, end: history.dateTo),
    );
    if (picked != null) {
      final from =
          '${picked.start.year}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}';
      final to =
          '${picked.end.year}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}';
      onChangeRange(from, to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _SummaryChip(
              label: 'Days Present',
              value: history.totalDaysPresent.toString(),
              color: AppColors.securitySuccess,
            ),
            const SizedBox(width: 10),
            _SummaryChip(
              label: 'Hours Worked',
              value: history.totalHoursWorked,
              color: AppColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '${_fmt(history.dateFrom)} → ${_fmt(history.dateTo)}',
              style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _pickRange(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range_rounded, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Change',
                      style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...history.attendance.map((e) => _AttendanceEntryTile(entry: e)),
        if (history.attendance.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No attendance records for this period.',
                style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.headlineMd.copyWith(color: color, fontSize: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelXs.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceEntryTile extends StatelessWidget {
  const _AttendanceEntryTile({required this.entry});
  final HrAttendanceEntry entry;

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _monthAbbr(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = entry.status == 'COMPLETE'
        ? AppColors.securitySuccess
        : entry.status == 'OUT_ONLY'
            ? AppColors.securityWarning
            : AppColors.securityError;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  entry.date.day.toString(),
                  style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface, fontSize: 20),
                ),
                Text(
                  _monthAbbr(entry.date.month),
                  style: AppTextStyles.labelXs.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: cs.outline.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.clockIn != null)
                  Text(
                    'In:  ${_time(entry.clockIn!)}',
                    style: AppTextStyles.labelSm.copyWith(color: cs.onSurface),
                  ),
                if (entry.clockOut != null)
                  Text(
                    'Out: ${_time(entry.clockOut!)}',
                    style: AppTextStyles.labelSm.copyWith(color: cs.onSurface),
                  ),
                if (entry.hoursWorked != null)
                  Text(
                    '${entry.hoursWorked} hrs',
                    style: AppTextStyles.labelXs.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.status.replaceAll('_', ' '),
              style: AppTextStyles.labelXs.copyWith(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
