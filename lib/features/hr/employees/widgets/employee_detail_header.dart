import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/hr_employee_models.dart';

/// Expanded SliverAppBar background for the employee detail screen:
/// avatar initials, ID, and active/onboarded status chips.
///
/// The employee's full name previously lived here as a large Text widget,
/// duplicating it (the collapsed SliverAppBar had no title at all, so the
/// name only appeared in this expanded block — meaning the bar showed
/// nothing but a bare back arrow once collapsed, inconsistent with every
/// other HR screen's AppBar, which always shows a static title). Fixed by
/// moving the name to the SliverAppBar's `title` at the call site (always
/// visible, pinned, matches the Onboarding/Employees screens' bar
/// pattern) and removing the duplicate name from this block — it now only
/// holds the avatar and the ID/status row.
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
      color: cs.primaryContainer,
      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 4, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.onPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: AppTextStyles.bodyLg.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  employee.erpnextEmployeeId,
                  style: AppTextStyles.labelSm.copyWith(
                    color: cs.onPrimary.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _HeaderChip(
                      label: employee.isActive ? 'Active' : 'Inactive',
                      color: employee.isActive
                          ? AppColors.securitySuccess
                          : AppColors.securityError,
                    ),
                    if (!employee.isOnboarded) ...[
                      const SizedBox(width: 6),
                      _HeaderChip(
                        label: 'Not Onboarded',
                        color: AppColors.securityWarning,
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
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
