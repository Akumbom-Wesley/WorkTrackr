import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/auth_provider.dart';
import '../../../shared/widgets/worktrackr_drawer.dart';
import '../../../shared/widgets/worktrackr_nav_shell.dart';
import '../history/employee_history_screen.dart';
import '../queue/employee_queue_screen.dart';
import '../profile/employee_profile_screen.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/dashboard_error_view.dart';
import 'widgets/dashboard_shimmer.dart';
import 'widgets/geofence_card.dart';
import 'widgets/greeting_card.dart';
import 'widgets/hours_summary_grid.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final data = dashAsync.valueOrNull;

    final drawer = WorkTrackrDrawer(
      fullName: data != null
          ? (data.me.fullName.isNotEmpty ? data.me.fullName : data.me.username)
          : null,
      employeeId: data?.me.erpnextEmployeeId,
      onOfflineQueueTap: () => context.push(AppRoutes.offlineQueue),
      onLogoutTap: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go(AppRoutes.login);
      },
    );

    final tabs = [
      PersistentTabConfig(
        screen: const _DashboardTab(),
        item: ItemConfig(
          icon: const Icon(Icons.dashboard_rounded),
          title: 'Dashboard',
          activeForegroundColor: AppColors.secondary,
          inactiveForegroundColor: AppColors.onSurfaceVariant,
        ),
      ),
      PersistentTabConfig(
        screen: const EmployeeHistoryScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.history_rounded),
          title: 'History',
          activeForegroundColor: AppColors.secondary,
          inactiveForegroundColor: AppColors.onSurfaceVariant,
        ),
      ),
      PersistentTabConfig(
        screen: const EmployeeQueueScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.cloud_sync_outlined),
          title: 'Queue',
          activeForegroundColor: AppColors.secondary,
          inactiveForegroundColor: AppColors.onSurfaceVariant,
        ),
      ),
      PersistentTabConfig(
        screen: const EmployeeProfileScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.person_rounded),
          title: 'Profile',
          activeForegroundColor: AppColors.secondary,
          inactiveForegroundColor: AppColors.onSurfaceVariant,
        ),
      ),
    ];

    return WorkTrackrNavShell(tabs: tabs, drawer: drawer);
  }
}

// ── Dashboard tab body ─────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab({super.key});

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
                    onClockInTap: () => context
                        .push(AppRoutes.checkin)
                        .then((_) =>
                            ref.read(dashboardProvider.notifier).refresh()),
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
    if (err is DioException) {
      switch (err.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'No internet connection. Please check your network.';
        case DioExceptionType.badResponse:
          if (err.response?.statusCode == 401) {
            return 'Your session has expired. Please log in again.';
          }
          return 'Something went wrong. Please try again.';
        default:
          break;
      }
    }
    final msg = err.toString();
    if (msg.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Your session has expired. Please log in again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
