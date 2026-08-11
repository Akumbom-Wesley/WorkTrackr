import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/hr_reports_models.dart';
import '../providers/hr_reports_providers.dart';

/// Two-segment Employee/Company toggle, matches the reference screenshot's
/// pill-style selector. Writes directly to [reportPerspectiveProvider] —
/// switching perspective does not clear other form fields (date range and
/// output format apply to both); the employee-picker widget is simply
/// hidden when Company is selected.
class ReportPerspectiveToggle extends ConsumerWidget {
  const ReportPerspectiveToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportPerspectiveProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Employee Report',
              selected: selected == ReportPerspective.employee,
              onTap: () => ref.read(reportPerspectiveProvider.notifier).state =
                  ReportPerspective.employee,
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Company Report',
              selected: selected == ReportPerspective.company,
              onTap: () => ref.read(reportPerspectiveProvider.notifier).state =
                  ReportPerspective.company,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: selected ? Theme.of(context).colorScheme.onSecondaryContainer : cs.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
