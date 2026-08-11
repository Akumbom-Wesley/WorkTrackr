import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../employees/model/hr_employee_models.dart';
import '../model/hr_reports_models.dart';
import '../providers/hr_reports_providers.dart';

/// Renders a [ReportResult]: JSON results show an in-app summary,
/// file results show a saved-path confirmation. Does not attempt to
/// render CSV/PDF bytes in-app — those are saved to Downloads and
/// confirmed via [FileSavedResult] only.
class ReportResultView extends StatelessWidget {
  const ReportResultView({super.key, required this.result});

  final ReportResult result;

  @override
  Widget build(BuildContext context) {
    return switch (result) {
      EmployeeJsonResult(:final history) => _EmployeeJsonView(history: history),
      CompanyJsonResult(:final report) => _CompanyJsonView(report: report),
      FileSavedResult(:final savedPath) => _FileSavedView(savedPath: savedPath),
    };
  }
}

String _summaryLine(HrAttendanceEntry e) {
  final date = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
  final hours = e.hoursWorked != null ? ' · ${e.hoursWorked}' : '';
  return '$date — ${e.status}$hours';
}

class _EmployeeJsonView extends StatelessWidget {
  const _EmployeeJsonView({required this.history});

  final HrEmployeeHistory history;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(history.fullName, style: AppTextStyles.headlineMd),
          const SizedBox(height: 4),
          Text(
            '${history.totalDaysPresent} day(s) present · ${history.totalHoursWorked} total',
            style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...history.attendance.take(20).map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _summaryLine(entry),
                  style: AppTextStyles.bodyMd,
                ),
              )),
          if (history.attendance.length > 20)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${history.attendance.length - 20} more — export to CSV/PDF for the full list.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompanyJsonView extends StatelessWidget {
  const _CompanyJsonView({required this.report});

  final CompanyReport report;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Company Report — ${report.company}', style: AppTextStyles.headlineMd),
          const SizedBox(height: 4),
          Text(
            '${report.employees.length} employee(s) · ${report.companyTotalHoursWorked} total',
            style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...report.employees.take(20).map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${e.fullName} — ${e.attendance.length} record(s)',
                  style: AppTextStyles.bodyMd,
                ),
              )),
          if (report.employees.length > 20)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${report.employees.length - 20} more — export to CSV/PDF for the full list.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FileSavedView extends StatelessWidget {
  const _FileSavedView({required this.savedPath});

  final String savedPath;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved to device', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  savedPath,
                  style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
