import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/auth_provider.dart';
import '../../../shared/widgets/worktrackr_app_bar.dart';
import '../../../shared/widgets/worktrackr_drawer.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PersistentTabController _navController;

  @override
  void initState() {
    super.initState();
    _navController = PersistentTabController(initialIndex: 0);
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  List<PersistentTabConfig> _tabs() => [
    PersistentTabConfig(
      screen: _DashboardTab(
        scaffoldKey: _scaffoldKey,
      ),
      item: ItemConfig(
        icon: const Icon(Icons.dashboard_rounded),
        title: 'Dashboard',
        activeForegroundColor: AppColors.secondary,
        inactiveForegroundColor: AppColors.onSurfaceVariant,
      ),
    ),
    PersistentTabConfig(
      screen: const Scaffold(
        body: Center(child: Text('History — Coming Soon')),
      ),
      item: ItemConfig(
        icon: const Icon(Icons.history_rounded),
        title: 'History',
        activeForegroundColor: AppColors.secondary,
        inactiveForegroundColor: AppColors.onSurfaceVariant,
      ),
    ),
    PersistentTabConfig(
      screen: const Scaffold(
        body: Center(child: Text('Records — Coming Soon')),
      ),
      item: ItemConfig(
        icon: const Icon(Icons.rule_rounded),
        title: 'Records',
        activeForegroundColor: AppColors.secondary,
        inactiveForegroundColor: AppColors.onSurfaceVariant,
      ),
    ),
    PersistentTabConfig(
      screen: const Scaffold(
        body: Center(child: Text('Profile — Coming Soon')),
      ),
      item: ItemConfig(
        icon: const Icon(Icons.person_rounded),
        title: 'Profile',
        activeForegroundColor: AppColors.secondary,
        inactiveForegroundColor: AppColors.onSurfaceVariant,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardProvider);
    final data = dashAsync.valueOrNull;

    return Scaffold(
      key: _scaffoldKey,
      appBar: WorkTrackrAppBar(scaffoldKey: _scaffoldKey),
      drawer: data != null
          ? WorkTrackrDrawer(
        fullName: data.me.fullName.isNotEmpty
            ? data.me.fullName
            : data.me.username,
        employeeId: data.me.erpnextEmployeeId,
        onOfflineQueueTap: () => context.push(AppRoutes.offlineQueue),
        onLogoutTap: () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go(AppRoutes.login);
        },
      )
          : const WorkTrackrDrawer(),
      body: PersistentTabView(
        controller: _navController,
        tabs: _tabs(),
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: const NavBarDecoration(
            color: AppColors.surfaceBase,
          ),
        ),
      ),
    );
  }
}

// ── Dashboard tab body ────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab({required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);

    return dashAsync.when(
      loading: () => const DashboardShimmer(),
      error: (err, _) => DashboardErrorView(
        message: _friendlyError(err),
        onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
      ),
      data: (data) => RefreshIndicator(
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
                    onClockInTap: () => context.push(AppRoutes.checkin).then((_) {
                      ref.read(dashboardProvider.notifier).refresh();
                    }),
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