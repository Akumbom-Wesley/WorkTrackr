import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/hr_analytics_providers.dart';

/// Period + optional custom date-range selector. Previously instantiated
/// separately per tab, each pointed at its own provider set. User
/// explicitly reversed that: this is now a SINGLE shared instance living
/// in the Analytics shell (above the TabBar), reading/writing the one
/// shared hrAnalyticsPeriod/DateFrom/DateToProvider set — selecting a
/// range here affects all 3 tabs at once.
///
/// No longer takes provider or defaultPeriod params (both were needed
/// only to support per-tab instantiation) — reads the shared providers
/// directly. Default period ('week') lives on hrAnalyticsPeriodProvider
/// itself in hr_analytics_providers.dart, confirmed by user.
///
/// Picking a custom date (either From or To) clears the period chip
/// selection implicitly — the provider layer already treats
/// "dateFrom != null || dateTo != null" as "ignore period", so this
/// widget mirrors that by visually deselecting the period chips once a
/// custom date is picked, and clears both custom dates when a period
/// chip is tapped.
class AnalyticsPeriodSelector extends ConsumerWidget {
  const AnalyticsPeriodSelector({super.key});

  static const _periods = [
    ('today', 'Today'),
    ('week', '7 Days'),
    ('month', '30 Days'),
  ];

  Future<void> _pickDate(
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
      ref.read(hrAnalyticsPeriodProvider.notifier).state = null;
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'mm/dd/yyyy';
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedPeriod = ref.watch(hrAnalyticsPeriodProvider);
    final dateFrom = ref.watch(hrAnalyticsDateFromProvider);
    final dateTo = ref.watch(hrAnalyticsDateToProvider);
    final hasCustomDate = dateFrom != null || dateTo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (value, label) in _periods) ...[
                _PeriodChip(
                  label: label,
                  selected: !hasCustomDate && selectedPeriod == value,
                  onTap: () {
                    ref.read(hrAnalyticsPeriodProvider.notifier).state = value;
                    ref.read(hrAnalyticsDateFromProvider.notifier).state = null;
                    ref.read(hrAnalyticsDateToProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Custom From',
                valueLabel: _fmt(dateFrom),
                onTap: () => _pickDate(context, ref, hrAnalyticsDateFromProvider),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: 'Custom To',
                valueLabel: _fmt(dateTo),
                onTap: () => _pickDate(context, ref, hrAnalyticsDateToProvider),
              ),
            ),
            if (hasCustomDate) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Clear custom range',
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant, size: 20),
                onPressed: () {
                  ref.read(hrAnalyticsDateFromProvider.notifier).state = null;
                  ref.read(hrAnalyticsDateToProvider.notifier).state = null;
                  ref.read(hrAnalyticsPeriodProvider.notifier).state = 'week';
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.secondary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? Theme.of(context).colorScheme.onSecondary : cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.valueLabel, required this.onTap});

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
          style: AppTextStyles.labelSm.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700),
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
