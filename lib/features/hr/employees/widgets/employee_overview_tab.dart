import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../model/hr_employee_models.dart';
import 'employee_info_card.dart';

/// Overview tab: profile card with real employee fields, a "Go to
/// Onboarding" action (navigates to the existing Onboarding list screen —
/// not a duplicated stepper, per explicit product decision: this screen
/// should link out rather than re-implement onboarding state), and a
/// stubbed hardware/device-binding card. The hardware card has no backing
/// field on HrEmployee and no repository method — shown disabled with a
/// "not yet available" snackbar on tap, matching the same stub pattern
/// used for the onboarding screen's email actions, rather than inventing
/// fake device data.
class EmployeeOverviewTab extends StatelessWidget {
  const EmployeeOverviewTab({super.key, required this.employee});
  final HrEmployee employee;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EmployeeInfoCard(
          title: 'Employee Info',
          rows: [
            InfoRow(label: 'Email', value: employee.email),
            InfoRow(label: 'Department', value: employee.department),
            InfoRow(
              label: 'Status',
              value: employee.isActive ? 'Active' : 'Inactive',
              valueColor: employee.isActive
                  ? AppColors.securitySuccess
                  : AppColors.securityError,
            ),
            InfoRow(
              label: 'Onboarded',
              value: employee.isOnboarded ? 'Yes' : 'No',
              valueColor: employee.isOnboarded
                  ? AppColors.securitySuccess
                  : AppColors.securityWarning,
            ),
          ],
        ),
        if (!employee.isOnboarded) ...[
          const SizedBox(height: 14),
          _GoToOnboardingCard(onTap: () => context.push(AppRoutes.hrOnboarding)),
        ],
        const SizedBox(height: 14),
        _HardwareStubCard(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Device binding is not yet available — no backend field '
                  'or endpoint exists for this yet.',
                ),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GoToOnboardingCard extends StatelessWidget {
  const _GoToOnboardingCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.securityWarning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.securityWarning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.forward_to_inbox_rounded,
                color: AppColors.securityWarning, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Not Onboarded',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View this employee in Onboarding to send credentials',
                    style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _HardwareStubCard extends StatelessWidget {
  const _HardwareStubCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_iphone_rounded, color: cs.onSurfaceVariant, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hardware Governance',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Device binding not yet available',
                      style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
