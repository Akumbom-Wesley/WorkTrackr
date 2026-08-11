import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/hr_employee_models.dart';

/// Single-row card for the HR employee list. Mobile-first adaptation of
/// the reference design's table row: avatar initials, name + department,
/// monospace ID pill, status pill (active/inactive), not-onboarded badge.
class EmployeeTile extends StatelessWidget {
  const EmployeeTile({super.key, required this.employee, required this.onTap});
  final HrEmployee employee;
  final VoidCallback onTap;

  String get _initials {
    final trimmed = employee.fullName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed
        .split(' ')
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).cardTheme.color ?? cs.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employee.department,
                          style: AppTextStyles.labelSm.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _IdPill(id: employee.erpnextEmployeeId),
                  const SizedBox(width: 8),
                  _StatusPill(active: employee.isActive),
                  if (!employee.isOnboarded) ...[
                    const SizedBox(width: 8),
                    _NotOnboardedBadge(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdPill extends StatelessWidget {
  const _IdPill({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        id,
        style: AppTextStyles.labelXs.copyWith(
          color: cs.onPrimaryContainer,
          fontFamily: 'JetBrainsMono',
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppColors.securitySuccess : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.block_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            active ? 'Active' : 'Inactive',
            style: AppTextStyles.labelXs.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotOnboardedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.securityWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pending_rounded,
              size: 12, color: AppColors.securityWarning),
          const SizedBox(width: 4),
          Text(
            'Not Onboarded',
            style: AppTextStyles.labelXs.copyWith(
              color: AppColors.securityWarning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
