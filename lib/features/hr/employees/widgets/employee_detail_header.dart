import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/hr_employee_models.dart';

/// Expanded SliverAppBar background for the employee detail screen:
/// large centered avatar with initials, name, department, and status chips.
/// Designed to feel premium and spacious — the avatar is prominent and
/// the chips use soft pill styling with subtle translucent backgrounds.
class EmployeeDetailHeader extends StatelessWidget {
  const EmployeeDetailHeader({super.key, required this.employee});
  final HrEmployee employee;

  String get _initials {
    final trimmed = employee.fullName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.split(' ').map((w) => w[0]).take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: Colors.transparent,
      // Add 48px to the bottom padding to clear the TabBar
      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 16, 20, 14 + 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ── Avatar ──────────────────────────────────────────────────
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.onPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.onPrimary.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _initials,
                style: AppTextStyles.headlineMd.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Employee ID ─────────────────────────────────────────────
          Text(
            employee.erpnextEmployeeId,
            style: AppTextStyles.labelSm.copyWith(
              color: cs.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          if (employee.department.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              employee.department,
              style: AppTextStyles.labelSm.copyWith(
                color: cs.onPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 10),

          // ── Status chips ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeaderChip(
                label: employee.isActive ? 'Active' : 'Inactive',
                color: employee.isActive
                    ? AppColors.securitySuccess
                    : AppColors.securityError,
              ),
              if (!employee.isOnboarded) ...[
                const SizedBox(width: 8),
                _HeaderChip(
                  label: 'Not Onboarded',
                  color: AppColors.securityWarning,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelXs.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
