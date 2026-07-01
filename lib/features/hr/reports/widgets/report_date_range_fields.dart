import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../providers/hr_reports_providers.dart';

/// Date From / Date To fields, each opening the platform date picker.
/// Writes to [reportDateFromProvider] / [reportDateToProvider] — both are
/// required by [HrReportGenerateNotifier.generate] (it errors if either
/// is null), so this widget doesn't itself need to enforce anything
/// beyond showing the picker.
class ReportDateRangeFields extends ConsumerWidget {
  const ReportDateRangeFields({super.key});

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    StateProvider<DateTime?> provider,
  ) async {
    final current = ref.read(provider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(provider.notifier).state = picked;
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'mm/dd/yyyy';
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final from = ref.watch(reportDateFromProvider);
    final to = ref.watch(reportDateToProvider);

    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: 'Date From',
            valueLabel: _fmt(from),
            onTap: () => _pick(context, ref, reportDateFromProvider),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateField(
            label: 'Date To',
            valueLabel: _fmt(to),
            onTap: () => _pick(context, ref, reportDateToProvider),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.valueLabel,
    required this.onTap,
  });

  final String label;
  final String valueLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valueLabel,
                    style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
