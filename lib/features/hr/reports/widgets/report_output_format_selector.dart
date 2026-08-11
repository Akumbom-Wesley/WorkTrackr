import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/hr_reports_models.dart';
import '../providers/hr_reports_providers.dart';

/// JSON / CSV / PDF three-way selector. JSON renders in-app via
/// ReportResultView; CSV/PDF trigger a real save to the device's Downloads
/// folder (see HrReportGenerateNotifier._saveToDownloads) — not stubbed,
/// per explicit product decision, though the Android permission path is
/// flagged elsewhere as unverified on real hardware.
class ReportOutputFormatSelector extends ConsumerWidget {
  const ReportOutputFormatSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportOutputFormatProvider);

    return Row(
      children: [
        Expanded(
          child: _FormatOption(
            label: 'JSON',
            icon: Icons.data_object_rounded,
            selected: selected == ReportOutputFormat.json,
            onTap: () => ref.read(reportOutputFormatProvider.notifier).state =
                ReportOutputFormat.json,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FormatOption(
            label: 'CSV',
            icon: Icons.table_chart_rounded,
            selected: selected == ReportOutputFormat.csv,
            onTap: () => ref.read(reportOutputFormatProvider.notifier).state =
                ReportOutputFormat.csv,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FormatOption(
            label: 'PDF',
            icon: Icons.picture_as_pdf_rounded,
            selected: selected == ReportOutputFormat.pdf,
            onTap: () => ref.read(reportOutputFormatProvider.notifier).state =
                ReportOutputFormat.pdf,
          ),
        ),
      ],
    );
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? Theme.of(context).colorScheme.secondary : cs.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.secondary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
