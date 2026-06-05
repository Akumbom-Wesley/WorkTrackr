import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/worktrackr_app_bar.dart';
import '../../../shared/widgets/worktrackr_bottom_nav.dart';
import '../../../shared/widgets/worktrackr_drawer.dart';
import 'model/dashboard_models.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/dashboard_error_view.dart';
import 'widgets/dashboard_shimmer.dart';
import 'widgets/geofence_card.dart';
import 'widgets/greeting_card.dart';
import 'widgets/hours_summary_grid.dart';

class EmployeeDashboardScreen extends ConsumerStatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  ConsumerState<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState
    extends ConsumerState<EmployeeDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,

      appBar: WorkTrackrAppBar(scaffoldKey: _scaffoldKey),

      drawer: dashAsync.whenOrNull(
        data: (data) => WorkTrackrDrawer(
          fullName: data.me.fullName.isNotEmpty
              ? data.me.fullName
              : data.me.username,
          employeeId: data.me.erpnextEmployeeId,
          onLogoutTap: () {
            // TODO: call auth provider logout
          },
        ),
      ) ?? const WorkTrackrDrawer(),

      body: dashAsync.when(
        loading: () => const DashboardShimmer(),
        error: (err, _) => DashboardErrorView(
          message: _friendlyError(err),
          onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
        ),
        data: (data) => _DashboardBody(data: data, ref: ref),
      ),

      bottomNavigationBar: WorkTrackrBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  String _friendlyError(Object err) {
    final msg = err.toString();
    if (msg.contains('SocketException') ||
        msg.contains('ConnectionError') ||
        msg.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Your session has expired. Please log in again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

// ── Dashboard body ────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data, required this.ref});

  final DashboardData data;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.secondary,
      backgroundColor: AppColors.surfaceBase,
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                GreetingCard(
                  me: data.me,
                  status: data.employeeStatus,
                  todaySummary: data.todaySummary,
                  onStatusTap: () {},
                  onClockInTap: () {},
                ),
                const SizedBox(height: 16),
                HoursSummaryGrid(
                  summary: data.todaySummary,
                  status: data.employeeStatus,
                  onStatusTap: () {},
                ),
                const SizedBox(height: 16),
                const GeofenceCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
