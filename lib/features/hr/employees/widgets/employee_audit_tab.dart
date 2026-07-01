import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/hr_employee_models.dart';
import 'employee_info_card.dart';

/// Audit tab: final decision banner, per-factor pass/fail checklist,
/// and timestamps for the employee's most recent check-in audit.
class EmployeeAuditTab extends StatelessWidget {
  const EmployeeAuditTab({super.key, required this.audit});
  final HrCheckinAudit? audit;

  String _fmtDt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (audit == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No audit record found.',
              style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final a = audit!;
    final decisionColor = a.finalDecision == 'PASS'
        ? AppColors.securitySuccess
        : a.finalDecision == 'TWO_FACTOR_ONLY'
            ? AppColors.securityWarning
            : AppColors.securityError;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: decisionColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: decisionColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(
                a.finalDecision == 'PASS'
                    ? Icons.check_circle_rounded
                    : a.finalDecision == 'TWO_FACTOR_ONLY'
                        ? Icons.warning_amber_rounded
                        : Icons.cancel_rounded,
                color: decisionColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Final Decision',
                    style: AppTextStyles.labelXs.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    a.finalDecision.replaceAll('_', ' '),
                    style: AppTextStyles.headlineMd.copyWith(color: decisionColor),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AuditFactorCard(
          factors: [
            _AuditFactor('Biometric', a.biometricResult),
            _AuditFactor('Geofence', a.geofenceResult),
            _AuditFactor('Wi-Fi RSSI', a.rssiResult),
            _AuditFactor('Anti-Spoof', a.antispoofingResult),
            _AuditFactor('Wi-Fi Available', a.wifiAvailable),
            _AuditFactor('2FA Only', a.twoFactorOnly),
          ],
        ),
        const SizedBox(height: 12),
        if (a.errorCode.isNotEmpty)
          EmployeeInfoCard(
            title: 'Error Code',
            rows: [InfoRow(label: 'Code', value: a.errorCode)],
          ),
        const SizedBox(height: 12),
        EmployeeInfoCard(
          title: 'Timestamps',
          rows: [
            InfoRow(label: 'Audit Created', value: _fmtDt(a.createdAt)),
            if (a.gpsTimestampUsed != null)
              InfoRow(label: 'GPS Timestamp', value: _fmtDt(a.gpsTimestampUsed!)),
          ],
        ),
      ],
    );
  }
}

class _AuditFactor {
  final String label;
  final bool passed;
  const _AuditFactor(this.label, this.passed);
}

class _AuditFactorCard extends StatelessWidget {
  const _AuditFactorCard({required this.factors});
  final List<_AuditFactor> factors;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'FACTOR CHECKS',
              style: AppTextStyles.labelXs.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          ...factors.map((f) => _FactorRow(factor: f)),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});
  final _AuditFactor factor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = factor.passed ? AppColors.securitySuccess : AppColors.securityError;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(
            factor.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              factor.label,
              style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
            ),
          ),
          Text(
            factor.passed ? 'Pass' : 'Fail',
            style: AppTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
