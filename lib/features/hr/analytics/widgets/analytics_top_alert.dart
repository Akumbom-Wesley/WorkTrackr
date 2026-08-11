import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Transient top-of-screen alert for Analytics. Deliberately duplicated
/// from lib/features/hr/reports/hr_reports_screen.dart's _TopAlert rather
/// than extracted to a shared widget — confirmed with user to keep
/// Reports/Analytics decoupled, matching the rest of this feature's
/// duplicate-rather-than-cross-import convention (see AnalyticsFileResult,
/// AnalyticsOutputFormat).
///
/// Not private (no leading underscore) since it's used by the Analytics
/// shell screen, not scoped to a single file the way Reports' version is.
class AnalyticsTopAlert extends StatefulWidget {
  const AnalyticsTopAlert({
    super.key,
    required this.message,
    required this.onDismiss,
    this.isSuccess = false,
  });

  final String message;
  final VoidCallback onDismiss;
  final bool isSuccess;

  @override
  State<AnalyticsTopAlert> createState() => _AnalyticsTopAlertState();
}

class _AnalyticsTopAlertState extends State<AnalyticsTopAlert> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    if (!mounted || !_visible) return;
    setState(() => _visible = false);
    Future.delayed(const Duration(milliseconds: 200), widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isSuccess
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  widget.isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: widget.isSuccess
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: widget.isSuccess
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _dismiss,
                  child: Icon(
                    Icons.close_rounded,
                    color: widget.isSuccess
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onErrorContainer,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
