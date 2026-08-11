import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../onboarding/providers/hr_onboarding_providers.dart';
import '../model/hr_employee_models.dart';

/// Overview tab: a modern command-center layout for HR admins to view
/// employee information and perform quick actions. Features:
///   1. Quick Actions Grid — 4 icon tiles for the most common HR tasks.
///   2. Premium Info Cards — grouped, beautifully styled employee data.
///   3. Onboarding CTA — contextual banner if the employee hasn't set up yet.
class EmployeeOverviewTab extends ConsumerStatefulWidget {
  const EmployeeOverviewTab({super.key, required this.employee});
  final HrEmployee employee;

  @override
  ConsumerState<EmployeeOverviewTab> createState() =>
      _EmployeeOverviewTabState();
}

class _EmployeeOverviewTabState extends ConsumerState<EmployeeOverviewTab> {
  bool _isSendingOnboarding = false;

  Future<void> _handleSendOnboarding() async {
    if (_isSendingOnboarding) return;
    setState(() => _isSendingOnboarding = true);
    try {
      await ref
          .read(hrOnboardingProvider.notifier)
          .sendEmail(widget.employee.erpnextEmployeeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Onboarding email sent to ${widget.employee.fullName}.'),
            backgroundColor: AppColors.securitySuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: $e'),
            backgroundColor: AppColors.securityError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingOnboarding = false);
    }
  }

  void _stubAction(String actionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionName is not yet available.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final emp = widget.employee;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Quick Actions ─────────────────────────────────────────────
        Text(
          'QUICK ACTIONS',
          style: AppTextStyles.labelXs.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _QuickActionsGrid(
          employee: emp,
          isSendingOnboarding: _isSendingOnboarding,
          onSendOnboarding: _handleSendOnboarding,
          onResetPassword: () => _stubAction('Reset Password'),
          onSuspendAccount: () => _stubAction('Suspend Account'),
          onEditDetails: () => _stubAction('Edit Details'),
          onDeviceBinding: () => _stubAction('Device Binding'),
        ),

        const SizedBox(height: 24),

        // ── Employee Information ──────────────────────────────────────
        _PremiumInfoCard(
          icon: Icons.badge_outlined,
          title: 'Identity',
          rows: [
            _InfoItem(label: 'Full Name', value: emp.fullName),
            _InfoItem(label: 'Employee ID', value: emp.erpnextEmployeeId),
            _InfoItem(label: 'Company ID', value: emp.company.toString()),
          ],
        ),
        const SizedBox(height: 12),
        _PremiumInfoCard(
          icon: Icons.work_outline_rounded,
          title: 'Work',
          rows: [
            _InfoItem(
              label: 'Department',
              value: emp.department.isNotEmpty ? emp.department : '—',
            ),
            _InfoItem(
              label: 'Email',
              value: emp.email.isNotEmpty ? emp.email : '—',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PremiumInfoCard(
          icon: Icons.verified_user_outlined,
          title: 'Account Status',
          rows: [
            _InfoItem(
              label: 'Status',
              value: emp.isActive ? 'Active' : 'Inactive',
              valueColor:
                  emp.isActive ? AppColors.securitySuccess : AppColors.securityError,
            ),
            _InfoItem(
              label: 'Onboarded',
              value: emp.isOnboarded ? 'Yes' : 'No',
              valueColor: emp.isOnboarded
                  ? AppColors.securitySuccess
                  : AppColors.securityWarning,
            ),
          ],
        ),

        // ── Contextual Onboarding Banner ─────────────────────────────
        if (!emp.isOnboarded) ...[
          const SizedBox(height: 20),
          _OnboardingBanner(
            employeeName: emp.fullName,
            isSending: _isSendingOnboarding,
            onSend: _handleSendOnboarding,
            onViewOnboarding: () => context.push(AppRoutes.hrOnboarding),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Quick Actions Grid
// ═══════════════════════════════════════════════════════════════════════════

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.employee,
    required this.isSendingOnboarding,
    required this.onSendOnboarding,
    required this.onResetPassword,
    required this.onSuspendAccount,
    required this.onEditDetails,
    required this.onDeviceBinding,
  });

  final HrEmployee employee;
  final bool isSendingOnboarding;
  final VoidCallback onSendOnboarding;
  final VoidCallback onResetPassword;
  final VoidCallback onSuspendAccount;
  final VoidCallback onEditDetails;
  final VoidCallback onDeviceBinding;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [
        // Onboarding / Reset Password
        if (!employee.isOnboarded)
          _QuickActionTile(
            icon: isSendingOnboarding
                ? null
                : Icons.forward_to_inbox_rounded,
            isLoading: isSendingOnboarding,
            label: 'Send Onboarding',
            color: AppColors.securityWarning,
            onTap: onSendOnboarding,
          )
        else
          _QuickActionTile(
            icon: Icons.lock_reset_rounded,
            label: 'Reset Password',
            color: Theme.of(context).colorScheme.secondary,
            onTap: onResetPassword,
          ),

        // Suspend / Activate
        _QuickActionTile(
          icon: employee.isActive
              ? Icons.person_off_outlined
              : Icons.person_add_alt_1_rounded,
          label: employee.isActive ? 'Suspend' : 'Activate',
          color: employee.isActive
              ? AppColors.securityError
              : AppColors.securitySuccess,
          onTap: onSuspendAccount,
        ),

        // Edit Details
        _QuickActionTile(
          icon: Icons.edit_note_rounded,
          label: 'Edit Details',
          color: Theme.of(context).colorScheme.tertiary,
          onTap: onEditDetails,
        ),

        // Device Binding
        _QuickActionTile(
          icon: Icons.phone_iphone_rounded,
          label: 'Device',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          onTap: onDeviceBinding,
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(icon, size: 20, color: color),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Premium Info Card
// ═══════════════════════════════════════════════════════════════════════════

class _InfoItem {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoItem({required this.label, required this.value, this.valueColor});
}

class _PremiumInfoCard extends StatelessWidget {
  const _PremiumInfoCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<_InfoItem> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 16, color: cs.secondary),
                ),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: AppTextStyles.labelXs.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.1)),
          // Data rows
          ...rows.map((item) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.label,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.value,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: item.valueColor ?? cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Onboarding Banner
// ═══════════════════════════════════════════════════════════════════════════

class _OnboardingBanner extends StatelessWidget {
  const _OnboardingBanner({
    required this.employeeName,
    required this.isSending,
    required this.onSend,
    required this.onViewOnboarding,
  });

  final String employeeName;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onViewOnboarding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.securityWarning.withValues(alpha: 0.08),
            AppColors.securityWarning.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.securityWarning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.securityWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.securityWarning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Onboarding Required',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$employeeName has not completed onboarding. '
            'Send credentials or view the onboarding dashboard.',
            style: AppTextStyles.bodyMd.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSending ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(isSending ? 'Sending...' : 'Send Email'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.securityWarning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: AppTextStyles.labelSm
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onViewOnboarding,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                      color: cs.outline.withValues(alpha: 0.3)),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
