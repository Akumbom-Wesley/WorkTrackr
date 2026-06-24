import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Colored pill badge for the employee's current status.
/// Spec §2.4: Present (green), On Break (amber), On Errand (blue),
///            Checked Out (grey). Tapping navigates to Status Screen.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.onTap,
  });

  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final config = _configFor(cs, status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: config.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: config.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: config.dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              config.label,
              style: AppTextStyles.labelSm.copyWith(
                color: config.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BadgeConfig _configFor(ColorScheme cs, String? status) {
    switch (status) {
      case 'present':
        return const _BadgeConfig(
          label: 'Present',
          dot: AppColors.securitySuccess,
          foreground: Color(0xFF065F46),
          background: Color(0xFFD1FAE5),
          border: Color(0xFF6EE7B7),
        );
      case 'break':
        return const _BadgeConfig(
          label: 'On Break',
          dot: AppColors.securityWarning,
          foreground: Color(0xFF92400E),
          background: Color(0xFFFEF3C7),
          border: Color(0xFFFCD34D),
        );
      case 'errand':
        return _BadgeConfig(
          label: 'On Errand',
          dot: cs.onTertiaryContainer,
          foreground: const Color(0xFF1E3A8A),
          background: const Color(0xFFDBEAFE),
          border: const Color(0xFF93C5FD),
        );
      case 'assignment':
        return const _BadgeConfig(
          label: 'On Assignment',
          dot: Color(0xFF7C3AED),
          foreground: Color(0xFF4C1D95),
          background: Color(0xFFEDE9FE),
          border: Color(0xFFC4B5FD),
        );
      case 'checked_out':
        return _BadgeConfig(
          label: 'Checked Out',
          dot: cs.outline,
          foreground: cs.onSurfaceVariant,
          background: cs.surfaceContainerLow,
          border: cs.outlineVariant,
        );
      case 'absent':
        return _BadgeConfig(
          label: 'Absent',
          dot: cs.error,
          foreground: cs.onErrorContainer,
          background: cs.errorContainer,
          border: cs.error.withValues(alpha: 0.4),
        );
      default:
        return _BadgeConfig(
          label: 'No Status',
          dot: cs.outline,
          foreground: cs.onSurfaceVariant,
          background: cs.surfaceContainerLow,
          border: cs.outlineVariant,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color dot;
  final Color foreground;
  final Color background;
  final Color border;

  const _BadgeConfig({
    required this.label,
    required this.dot,
    required this.foreground,
    required this.background,
    required this.border,
  });
}
