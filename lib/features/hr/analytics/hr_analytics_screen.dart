import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_text_styles.dart';
import 'providers/hr_analytics_providers.dart';
import 'repository/hr_analytics_repository.dart' show AnalyticsOutputFormat;
import 'widgets/analytics_attendance_tab.dart';
import 'widgets/analytics_efficiency_tab.dart';
import 'widgets/analytics_period_selector.dart';
import 'widgets/analytics_performance_tab.dart';
import 'widgets/analytics_top_alert.dart';

/// HR Analytics screen — a bottom-nav-shell-adjacent screen reached via
/// the drawer (not a WorkTrackrNavShell tab), so unlike hr_reports_screen
/// it DOES own its own Scaffold + AppBar.
///
/// AppBar style now matches hr_employee_list_screen.dart: a flat, standard
/// AppBar (centered title, cs.primaryContainer/cs.onPrimary, TabBar as
/// AppBar.bottom) instead of the previous SliverAppBar + NestedScrollView
/// construction. That construction is still correct and used elsewhere
/// (hr_employee_detail_screen.dart) for passive header content inside
/// flexibleSpace — but AnalyticsPeriodSelector is an interactive form
/// (chips + date fields + date-picker launcher), not passive header
/// content, so it doesn't belong inside app-bar chrome. It now lives as a
/// normal widget in the body, above the TabBarView, always visible,
/// outside any scroll-collapse behavior — confirmed with user.
///
/// 3 tabs: Performance / Attendance / Efficiency, each independently
/// offline-first (cache-then-network). Period/date range is a SINGLE
/// SHARED selector — selecting a range here affects all 3 tabs at once.
///
/// Export UX: previously a single icon button in the AppBar actions.
/// Confirmed with user this was poor UX — replaced with a fixed
/// persistentFooterButton ("Download Analytics"), always reachable
/// regardless of tab content length or scroll position, since export
/// is a page-level action (current tab, not tab-specific UI). Tapping it
/// still opens the same CSV/XLSX PopupMenuButton, now anchored above the
/// footer button instead of top-right.
class HrAnalyticsScreen extends ConsumerStatefulWidget {
  const HrAnalyticsScreen({super.key});

  @override
  ConsumerState<HrAnalyticsScreen> createState() => _HrAnalyticsScreenState();
}

class _HrAnalyticsScreenState extends ConsumerState<HrAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  OverlayEntry? _alertEntry;

  static const _tabForIndex = [
    HrAnalyticsTab.performance,
    HrAnalyticsTab.attendance,
    HrAnalyticsTab.efficiency,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _alertEntry?.remove();
    super.dispose();
  }

  void _showAlert(String message, {bool isSuccess = false}) {
    _alertEntry?.remove();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => AnalyticsTopAlert(
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

  Future<void> _export(AnalyticsOutputFormat format) async {
    final tab = _tabForIndex[_tabs.index];
    await ref.read(hrAnalyticsExportProvider.notifier).export(tab, format);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isExporting = ref.watch(hrAnalyticsExportProvider).isLoading;

    ref.listen(hrAnalyticsExportProvider, (previous, next) {
      next.whenOrNull(
        data: (path) {
          if (path != null) {
            _showAlert('Saved to Downloads: $path', isSuccess: true);
          }
        },
        error: (err, _) => _showAlert(_friendlyError(err)),
      );
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Analytics',
          style: AppTextStyles.headlineMd.copyWith(color: cs.onPrimary),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onPrimary.withValues(alpha: 0.6),
          indicatorColor: cs.onPrimary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Performance'),
            Tab(text: 'Attendance'),
            Tab(text: 'Efficiency'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: const AnalyticsPeriodSelector(),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                AnalyticsPerformanceTab(),
                AnalyticsAttendanceTab(),
                AnalyticsEfficiencyTab(),
              ],
            ),
          ),
        ],
      ),
      persistentFooterButtons: [
        SizedBox(
          width: double.infinity,
          child: PopupMenuButton<AnalyticsOutputFormat>(
            enabled: !isExporting,
            tooltip: 'Export',
            onSelected: _export,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: AnalyticsOutputFormat.csv,
                child: Text('Export as CSV'),
              ),
              PopupMenuItem(
                value: AnalyticsOutputFormat.xlsx,
                child: Text('Export as XLSX'),
              ),
              PopupMenuItem(
                value: AnalyticsOutputFormat.pdf,
                child: Text('Export as PDF'),
              ),
            ],
            child: IgnorePointer(
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.file_download_outlined),
                label: Text(isExporting ? 'Preparing download…' : 'Download Analytics'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
