import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/history_models.dart';

class AttendanceEntryCard extends StatelessWidget {
  const AttendanceEntryCard({super.key, required this.entry});
  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final isComplete   = entry.status == 'COMPLETE';
    final isIncomplete = entry.status == 'INCOMPLETE';

    final statusColor = isComplete
        ? cs.secondary
        : isIncomplete
            ? AppColors.securityWarning
            : AppColors.securityError;

    final statusLabel = isComplete
        ? 'Complete'
        : isIncomplete
            ? 'Incomplete'
            : 'Out Only';

    final hw = entry.hoursWorked;
    final hoursLabel = hw != null
        ? '${hw.inHours}h ${hw.inMinutes.remainder(60).toString().padLeft(2, '0')}m'
        : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + status chip
          Row(
            children: [
              Text(
                _fmtDate(entry.date),
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              _StatusChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          // Clock in / out row
          Row(
            children: [
              _TimeBlock(
                label: 'Clock In',
                time: entry.clockIn != null ? _fmtTime(entry.clockIn!) : '--:--',
                icon: Icons.login_rounded,
                color: cs.secondary,
                context: context,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DurationBar(
                  hoursWorked: entry.hoursWorked,
                  isComplete: isComplete,
                ),
              ),
              const SizedBox(width: 12),
              _TimeBlock(
                label: 'Clock Out',
                time: entry.clockOut != null ? _fmtTime(entry.clockOut!) : '--:--',
                icon: Icons.logout_rounded,
                color: isComplete ? cs.onTertiaryContainer : cs.outline,
                context: context,
                alignRight: true,
              ),
            ],
          ),
          if (isComplete) ...[
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Duration: $hoursLabel',
                  style: AppTextStyles.labelSm.copyWith(
                    color: cs.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.context,
    this.alignRight = false,
  });
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  final BuildContext context;
  final bool alignRight;

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: alignRight
              ? [
                  Text(
                    label,
                    style: AppTextStyles.labelXs.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(icon, size: 12, color: color),
                ]
              : [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTextStyles.labelXs.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _DurationBar extends StatelessWidget {
  const _DurationBar({required this.hoursWorked, required this.isComplete});
  final Duration? hoursWorked;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 8 h = full bar
    const maxHours = 8.0;
    final fraction = isComplete && hoursWorked != null
        ? (hoursWorked!.inMinutes / (maxHours * 60)).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor:
                Theme.of(context).dividerColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              fraction >= 1.0
                  ? cs.secondary
                  : cs.onTertiaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
