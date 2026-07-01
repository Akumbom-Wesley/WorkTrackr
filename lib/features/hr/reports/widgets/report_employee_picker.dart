import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../employees/providers/hr_employee_providers.dart';
import '../providers/hr_reports_providers.dart';

/// Embedded typeahead for picking an employee, scoped to this widget —
/// Reports lives as a bottom-nav-shell tab (not a routed screen), so it
/// cannot reuse Onboarding's "navigate to another screen and pick" pattern.
/// Filters the already-cached employee list client-side via
/// hrEmployeeListProvider; does not hit the network itself — consistent
/// with Reports being explicitly outside the offline-first caching effort,
/// since this is just a local filter on data fetched by another feature.
class ReportEmployeePicker extends ConsumerStatefulWidget {
  const ReportEmployeePicker({super.key});

  @override
  ConsumerState<ReportEmployeePicker> createState() => _ReportEmployeePickerState();
}

class _ReportEmployeePickerState extends ConsumerState<ReportEmployeePicker> {
  final _controller = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = ref.watch(reportSelectedEmployeeProvider);
    final employeesAsync = ref.watch(hrEmployeeListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employee',
          style: AppTextStyles.labelSm.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: selected != null ? selected.fullName : 'Search employee by name or ID',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: cs.onSurfaceVariant),
                  suffixIcon: selected != null
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            ref.read(reportSelectedEmployeeProvider.notifier).state = null;
                            _controller.clear();
                            setState(() => _expanded = false);
                          },
                        )
                      : null,
                ),
                onTap: () => setState(() => _expanded = true),
                onChanged: (_) => setState(() {}),
              ),
              if (_expanded)
                employeesAsync.when(
                  data: (employees) {
                    final query = _controller.text.trim().toLowerCase();
                    final filtered = query.isEmpty
                        ? employees
                        : employees.where((e) =>
                            e.fullName.toLowerCase().contains(query) ||
                            e.erpnextEmployeeId.toLowerCase().contains(query)).toList();

                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No employees match.',
                          style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
                        ),
                      );
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final e = filtered[i];
                          return ListTile(
                            dense: true,
                            title: Text(e.fullName, style: AppTextStyles.bodyMd),
                            subtitle: Text(e.erpnextEmployeeId, style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant)),
                            onTap: () {
                              ref.read(reportSelectedEmployeeProvider.notifier).state = e;
                              _controller.text = e.fullName;
                              setState(() => _expanded = false);
                              FocusScope.of(context).unfocus();
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Could not load employees.',
                      style: AppTextStyles.bodyMd.copyWith(color: cs.error),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
