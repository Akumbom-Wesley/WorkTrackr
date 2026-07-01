import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../providers/hr_employee_providers.dart';

/// Horizontal scrollable row of filter chips for the HR employee list:
/// All / Active / Inactive / Not Onboarded. Wired to [hrEmployeeFilterProvider].
class EmployeeFilterChips extends ConsumerWidget {
  const EmployeeFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(hrEmployeeFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'All',
            isActive: active == HrEmployeeFilter.all,
            onTap: () => ref.read(hrEmployeeFilterProvider.notifier).state =
                HrEmployeeFilter.all,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Active',
            isActive: active == HrEmployeeFilter.active,
            onTap: () => ref.read(hrEmployeeFilterProvider.notifier).state =
                HrEmployeeFilter.active,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Inactive',
            isActive: active == HrEmployeeFilter.inactive,
            onTap: () => ref.read(hrEmployeeFilterProvider.notifier).state =
                HrEmployeeFilter.inactive,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Not Onboarded',
            isActive: active == HrEmployeeFilter.notOnboarded,
            onTap: () => ref.read(hrEmployeeFilterProvider.notifier).state =
                HrEmployeeFilter.notOnboarded,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
