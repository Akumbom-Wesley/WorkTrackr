import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/worktrackr_error_view.dart';
import 'providers/hr_employee_providers.dart';
import 'widgets/employee_attendance_tab.dart';
import 'widgets/employee_audit_tab.dart';
import 'widgets/employee_detail_header.dart';
import 'widgets/employee_overview_tab.dart';

/// HR employee detail screen — thin orchestrator that wires the
/// AsyncNotifier state to the header + 3-tab body (Overview / Attendance
/// / Audit). Each tab and the header are separate widgets under widgets/
/// for modularity and easier debugging.
class HrEmployeeDetailScreen extends ConsumerStatefulWidget {
  const HrEmployeeDetailScreen({super.key, required this.employeeId});

  final int employeeId;

  @override
  ConsumerState<HrEmployeeDetailScreen> createState() =>
      _HrEmployeeDetailScreenState();
}

class _HrEmployeeDetailScreenState extends ConsumerState<HrEmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(hrEmployeeDetailProvider(widget.employeeId));
    final cs = Theme.of(context).colorScheme;

    return detailAsync.when(
      loading: () => const _DetailShimmer(),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: WorkTrackrErrorView(
          title: 'Could not load employee details',
          message: 'Check your connection and try again.',
          onRetry: () => ref.read(hrEmployeeDetailProvider(widget.employeeId).notifier).refresh(),
        ),
      ),
      data: (data) => _DetailScaffold(
        tabs: _tabs,
        data: data,
        cs: cs,
        onChangeRange: (from, to) =>
            ref.read(hrEmployeeDetailProvider(widget.employeeId).notifier).changeRange(from, to),
      ),
    );
  }
}

// ── Main scaffold ──────────────────────────────────────────────────────────

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.tabs,
    required this.data,
    required this.cs,
    required this.onChangeRange,
  });

  final TabController tabs;
  final HrEmployeeDetailData data;
  final ColorScheme cs;
  final void Function(String from, String to) onChangeRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            centerTitle: true,
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(
              data.employee.fullName,
              style: AppTextStyles.headlineMd.copyWith(color: cs.onPrimary),
              overflow: TextOverflow.ellipsis,
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: EmployeeDetailHeader(employee: data.employee),
            ),
            bottom: TabBar(
              controller: tabs,
              labelColor: cs.onPrimary,
              unselectedLabelColor: cs.onPrimary.withValues(alpha: 0.6),
              indicatorColor: cs.onPrimary,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Attendance'),
                Tab(text: 'Audit'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: tabs,
          children: [
            EmployeeOverviewTab(employee: data.employee),
            EmployeeAttendanceTab(
              history: data.history,
              onChangeRange: onChangeRange,
            ),
            EmployeeAuditTab(audit: data.audit),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.15);
    return Scaffold(
      body: Column(
        children: [
          Container(height: 260, color: base),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
