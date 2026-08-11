import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/worktrackr_drawer.dart';
import '../../../shared/widgets/worktrackr_nav_shell.dart';
import '../../auth/auth_provider.dart';
import '../../employee/dashboard/widgets/geofence_card.dart';
import '../../employee/history/employee_history_screen.dart';
import '../../../shared/widgets/worktrackr_error_view.dart';
import '../flagged/hr_flagged_screen.dart';
import '../reports/hr_reports_screen.dart';
import 'model/hr_dashboard_models.dart';
import 'providers/hr_dashboard_providers.dart';

class HrDashboardScreen extends ConsumerWidget {
  const HrDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    final drawer = WorkTrackrDrawer(
      fullName: user?.fullName,
      employeeId: user?.erpnextEmployeeId,
      isHrAdmin: true,
      onProfileTap: () => context.push(AppRoutes.profile),
      onOfflineQueueTap: () => context.push(AppRoutes.offlineQueue),
      onAnalyticsTap: () => context.push(AppRoutes.hrAnalytics),
      onEmployeesTap: () => context.push(AppRoutes.hrEmployees),
      onFlaggedTap: () => context.push(AppRoutes.hrFlagged),
      onOnboardingTap: () => context.push(AppRoutes.hrOnboarding),
      onCompanyTap: () => context.push(AppRoutes.hrCompany),
      onLogoutTap: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go(AppRoutes.login);
      },
    );

    final tabs = [
      PersistentTabConfig(
        screen: const _HrDashboardTab(),
        item: ItemConfig(
          icon: const Icon(Icons.dashboard_rounded),
          title: 'Dashboard',
          activeForegroundColor: Theme.of(context).colorScheme.secondary,
          inactiveForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      PersistentTabConfig(
        screen: const EmployeeHistoryScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.history_rounded),
          title: 'History',
          activeForegroundColor: Theme.of(context).colorScheme.secondary,
          inactiveForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      PersistentTabConfig(
        screen: const HrFlaggedTabView(),
        item: ItemConfig(
          icon: const Icon(Icons.flag_rounded),
          title: 'Records',
          activeForegroundColor: Theme.of(context).colorScheme.secondary,
          inactiveForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      PersistentTabConfig(
        screen: const HrReportsScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.bar_chart_rounded),
          title: 'Reports',
          activeForegroundColor: Theme.of(context).colorScheme.secondary,
          inactiveForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ];

    return WorkTrackrNavShell(tabs: tabs, drawer: drawer);
  }
}

// ── HR Dashboard tab ───────────────────────────────────────────────────────

class _HrDashboardTab extends ConsumerWidget {
  const _HrDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(hrDashboardProvider);

    return statsAsync.when(
      loading: () => const _HrDashboardShimmer(),
      error: (err, _) => WorkTrackrErrorView(
        title: 'Could not load dashboard',
        message: _friendlyError(err),
        onRetry: () => ref.read(hrDashboardProvider.notifier).refresh(),
      ),
      data: (stats) => _HrDashboardBody(stats: stats),
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
    return 'Something went wrong. Please try again.';
  }
}

// ── Body ───────────────────────────────────────────────────────────────────

class _HrDashboardBody extends ConsumerWidget {
  const _HrDashboardBody({required this.stats});
  final HrDashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onRefresh: () => ref.read(hrDashboardProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _HrGreetingCard(),
                const SizedBox(height: 20),
                _SectionLabel(label: "TODAY'S OVERVIEW"),
                const SizedBox(height: 12),
                _StatsGrid(stats: stats),
                const SizedBox(height: 20),
                _SectionLabel(label: 'YOUR LOCATION'),
                const SizedBox(height: 12),
                const GeofenceCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HR Greeting Card ───────────────────────────────────────────────────────

class _HrGreetingCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HrGreetingCard> createState() => _HrGreetingCardState();
}

class _HrGreetingCardState extends ConsumerState<_HrGreetingCard> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(authProvider).user;
    final firstName = user?.fullName.split(' ').first ?? 'there';
    final hour = _now.hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
            ? 'Good Afternoon,'
            : 'Good Evening,';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HR ADMIN',
                  style: AppTextStyles.labelXs.copyWith(
                    color: cs.onPrimaryContainer,
                    letterSpacing: 1.2,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(_now),
                      style: AppTextStyles.headlineMd.copyWith(
                        color: cs.onPrimary,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatDate(_now),
                      style: AppTextStyles.labelXs.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$greeting\n$firstName.',
              style: AppTextStyles.headlineLgMobile.copyWith(
                color: cs.onPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HrChip(
                  icon: Icons.verified_user_rounded,
                  label: 'HR Verified',
                  color: AppColors.securitySuccess,
                ),
                _HrChip(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Admin Access',
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.checkin),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.onPrimary,
                  foregroundColor: cs.primaryContainer,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.login_rounded, size: 20),
                label: Text(
                  'CLOCK IN',
                  style: AppTextStyles.button.copyWith(
                    color: cs.primaryContainer,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _HrChip extends StatelessWidget {
  const _HrChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.onPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.onPrimaryContainer.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelXs.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Stats grid ─────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final HrDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatCard(
              label: 'Present',
              value: stats.presentToday,
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.securitySuccess,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Absent',
              value: stats.absentToday,
              icon: Icons.cancel_outlined,
              color: AppColors.securityError,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              label: 'Flagged',
              value: stats.flaggedPending,
              icon: Icons.flag_outlined,
              color: AppColors.securityWarning,
              routePath: AppRoutes.hrFlagged,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Not Onboarded',
              value: stats.notOnboarded,
              icon: Icons.person_add_disabled_outlined,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              routePath: AppRoutes.hrOnboarding,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TotalCard(total: stats.totalActiveEmployees),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.routePath,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String? routePath;

  @override
  Widget build(BuildContext context) {
    final isActionable = routePath != null;
    return Expanded(
      child: GestureDetector(
        onTap: isActionable ? () => context.push(routePath!) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: AppTextStyles.headlineMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: AppTextStyles.labelXs.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isActionable)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: color.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_rounded, size: 20, color: cs.onPrimary),
          const SizedBox(width: 12),
          Text(
            'Total Active Employees',
            style: AppTextStyles.bodyMd.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            total.toString(),
            style: AppTextStyles.headlineMd.copyWith(color: cs.onPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────

class _HrDashboardShimmer extends StatelessWidget {
  const _HrDashboardShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.15);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(height: 220, color: base),
            const SizedBox(height: 24),
            _ShimmerBox(width: 120, height: 14, color: base),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ShimmerBox(height: 80, color: base)),
              const SizedBox(width: 12),
              Expanded(child: _ShimmerBox(height: 80, color: base)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ShimmerBox(height: 80, color: base)),
              const SizedBox(width: 12),
              Expanded(child: _ShimmerBox(height: 80, color: base)),
            ]),
            const SizedBox(height: 12),
            _ShimmerBox(height: 52, color: base),
            const SizedBox(height: 20),
            _ShimmerBox(width: 140, height: 14, color: base),
            const SizedBox(height: 12),
            _ShimmerBox(height: 140, color: base),
            const SizedBox(height: 20),
            _ShimmerBox(width: 120, height: 14, color: base),
            const SizedBox(height: 12),
            _ShimmerBox(height: 240, color: base),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.width, required this.height, required this.color});
  final double? width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
