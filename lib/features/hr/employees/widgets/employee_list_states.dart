import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 36,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No employees found',
              style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'No employees match the current filter or search.',
              style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
