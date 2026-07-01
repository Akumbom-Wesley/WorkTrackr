import 'package:flutter/material.dart';

import '../../../../core/constants/app_text_styles.dart';

/// Reusable labeled key-value card used across employee detail tabs
/// (Overview's profile fields, Audit's error code / timestamps).
class InfoRow {
  final String label;
  final String value;
  final Color? valueColor;
  const InfoRow({required this.label, required this.value, this.valueColor});
}

class EmployeeInfoCard extends StatelessWidget {
  const EmployeeInfoCard({super.key, required this.title, required this.rows});
  final String title;
  final List<InfoRow> rows;

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
              title.toUpperCase(),
              style: AppTextStyles.labelXs.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          ...rows.map((r) => _InfoRowWidget(row: r)),
        ],
      ),
    );
  }
}

class _InfoRowWidget extends StatelessWidget {
  const _InfoRowWidget({required this.row});
  final InfoRow row;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              row.label,
              style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.value,
              style: AppTextStyles.bodyMd.copyWith(
                color: row.valueColor ?? cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
