import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/worktrackr_error_view.dart';
import 'providers/hr_employee_providers.dart';
import 'widgets/employee_filter_chips.dart';
import 'widgets/employee_list_states.dart';
import 'widgets/employee_search_bar.dart';
import 'widgets/employee_tile.dart';

/// HR employee directory.
class HrEmployeeListScreen extends ConsumerWidget {
  const HrEmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(hrFilteredEmployeeListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimary,
        title: Text(
          'Employees',
          style: AppTextStyles.headlineMd.copyWith(color: cs.onPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(hrEmployeeListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: EmployeeSearchBar(
              queryProvider: hrSearchQueryProvider,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: const EmployeeFilterChips(),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const EmployeeListShimmer(),
              error: (err, _) => WorkTrackrErrorView(
                title: 'Could not load employees',
                message: 'Check your connection and try again.',
                onRetry: () =>
                    ref.read(hrEmployeeListProvider.notifier).refresh(),
              ),
              data: (employees) => employees.isEmpty
                  ? const EmployeeListEmptyState()
                  : RefreshIndicator(
                      color: AppColors.secondary,
                      backgroundColor: AppColors.surfaceBase,
                      onRefresh: () =>
                          ref.read(hrEmployeeListProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: employees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => EmployeeTile(
                          employee: employees[i],
                          onTap: () {
                            context.pushNamed(
                              'hr-employee-detail',
                              pathParameters: {
                                'employeeId': employees[i].id.toString(),
                              },
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
