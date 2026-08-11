import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/worktrackr_empty_state.dart';

/// Loading shimmer for the HR employee list.
class EmployeeListShimmer extends StatelessWidget {
  const EmployeeListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.15);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 92,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Empty state for the HR employee list, shown when no employees match
/// the current filter/search combination.
class EmployeeListEmptyState extends StatelessWidget {
  const EmployeeListEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkTrackrEmptyState(
      title: 'No employees found',
      message: 'No employees match the current filter or search.',
      icon: Icons.people_outline_rounded,
    );
  }
}
