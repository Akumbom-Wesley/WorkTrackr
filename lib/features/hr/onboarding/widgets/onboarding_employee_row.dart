import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/hr_onboarding_models.dart';

/// Compact single-line row: avatar, name/ID/department, status pill, and a
/// trailing icon-only action — replaces the previous 3-stacked-block card
/// (header row / status+timestamp row / full-width button row) which made
/// each entry ~3x taller than needed for what is fundamentally one
/// scannable line item in a triage list. Action wiring (onAction) is a
/// stub — backend endpoints exist but request/response shape isn't wired
/// up yet, per explicit product decision.
class OnboardingEmployeeRow extends StatelessWidget {
  const OnboardingEmployeeRow({
    super.key,
    required this.entry,
    required this.onAction,
  });

  final OnboardingEntry entry;
  final VoidCallback onAction;

  String get _initials {
    final trimmed = entry.employee.fullName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.split(' ').map((w) => w[0]).take(2).join().toUpperCase();
  }

  _StatusVisual get _visual {
    switch (entry.emailStatus) {
      case OnboardingEmailStatus.notSent:
        return const _StatusVisual(
          label: 'Not Sent',
          color: AppColors.securityWarning,
          actionIcon: Icons.send_rounded,
          actionTooltip: 'Send Email',
        );
      case OnboardingEmailStatus.invitedExpired:
        return const _StatusVisual(
          label: 'Expired',
          color: AppColors.onSurfaceVariant,
          actionIcon: Icons.refresh_rounded,
          actionTooltip: 'Resend Invitation',
        );
      case OnboardingEmailStatus.deliveryFailed:
        return const _StatusVisual(
          label: 'Failed',
          color: AppColors.securityError,
          actionIcon: Icons.replay_rounded,
          actionTooltip: 'Retry Send',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visual = _visual;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.employee.fullName,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.employee.erpnextEmployeeId} · ${entry.employee.department}',
                  style: AppTextStyles.labelXs.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              visual.label,
              style: AppTextStyles.labelXs.copyWith(
                color: visual.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(visual.actionIcon, size: 19),
            color: AppColors.secondary,
            tooltip: visual.actionTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.color,
    required this.actionIcon,
    required this.actionTooltip,
  });

  final String label;
  final Color color;
  final IconData actionIcon;
  final String actionTooltip;
}
