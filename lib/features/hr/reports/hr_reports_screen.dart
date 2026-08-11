import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'model/hr_reports_models.dart';
import 'providers/hr_reports_providers.dart';
import 'widgets/report_date_range_fields.dart';
import 'widgets/report_employee_picker.dart';
import 'widgets/report_output_format_selector.dart';
import 'widgets/report_perspective_toggle.dart';
import 'widgets/report_result_view.dart';

/// Orchestrating screen for Reports. A bottom-nav-shell tab — does NOT own
/// its own Scaffold/AppBar. WorkTrackrNavShell already provides the single
/// outer Scaffold + WorkTrackrAppBar shared across all tabs; this screen is
/// just the tab's body content.
///
/// Request-driven, not cache-then-network: nothing loads until the user
/// fills the form and taps Generate. hrReportGenerateProvider starts as
/// AsyncData(null) and only becomes AsyncLoading/AsyncError/AsyncData(result)
/// once .generate() is explicitly called.
class HrReportsScreen extends ConsumerStatefulWidget {
  const HrReportsScreen({super.key});

  @override
  ConsumerState<HrReportsScreen> createState() => _HrReportsScreenState();
}

class _HrReportsScreenState extends ConsumerState<HrReportsScreen> {
  OverlayEntry? _alertEntry;

  @override
  void dispose() {
    _alertEntry?.remove();
    super.dispose();
  }

  void _showAlert(String message, {bool isSuccess = false}) {
    _alertEntry?.remove();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopAlert(
        message: message,
        isSuccess: isSuccess,
        onDismiss: () {
          entry.remove();
          if (_alertEntry == entry) _alertEntry = null;
        },
      ),
    );
    _alertEntry = entry;
    overlay.insert(entry);
  }

  String _friendlyError(Object err) {
    if (err is StateError) return err.message;
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final perspective = ref.watch(reportPerspectiveProvider);
    final isGenerating = ref.watch(hrReportGenerateProvider).isLoading;

    ref.listen(hrReportGenerateProvider, (previous, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) return;
          final path = switch (result) {
            EmployeeJsonResult(:final savedPath) => savedPath,
            CompanyJsonResult(:final savedPath) => savedPath,
            FileSavedResult(:final savedPath) => savedPath,
          };
          if (path != null) {
            _showAlert('Saved to Downloads: $path', isSuccess: true);
          }
        },
        error: (err, _) => _showAlert(_friendlyError(err)),
      );
    });

    final resultAsync = ref.watch(hrReportGenerateProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const ReportPerspectiveToggle(),
          const SizedBox(height: 16),
          if (perspective == ReportPerspective.employee) ...[
            const ReportEmployeePicker(),
            const SizedBox(height: 16),
          ],
          const ReportDateRangeFields(),
          const SizedBox(height: 16),
          Text(
            'Output Format',
            style: AppTextStyles.labelSm.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const ReportOutputFormatSelector(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isGenerating
                  ? null
                  : () => ref.read(hrReportGenerateProvider.notifier).generate(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: isGenerating
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    )
                  : const Icon(Icons.bar_chart_rounded, size: 20),
              label: Text(
                isGenerating ? 'Generating…' : 'Generate Report',
                style: AppTextStyles.button.copyWith(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          resultAsync.maybeWhen(
            data: (result) =>
                result == null ? const SizedBox.shrink() : ReportResultView(result: result),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Transient top-of-screen alert. Auto-dismisses after 4 seconds, or
/// immediately via the X button. Self-contained.
///
/// [isSuccess] switches the colour/icon to a success (green) variant;
/// default is the error (red) variant used for generate failures.
class _TopAlert extends StatefulWidget {
  const _TopAlert({
    required this.message,
    required this.onDismiss,
    this.isSuccess = false,
  });

  final String message;
  final VoidCallback onDismiss;
  final bool isSuccess;

  @override
  State<_TopAlert> createState() => _TopAlertState();
}

class _TopAlertState extends State<_TopAlert> {
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
