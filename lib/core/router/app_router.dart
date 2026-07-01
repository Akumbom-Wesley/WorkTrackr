import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/employee/dashboard/employee_dashboard_screen.dart';
import '../../features/employee/checkin/checkin_screen.dart';
import '../../features/employee/history/employee_history_screen.dart';
import '../../features/employee/profile/employee_profile_screen.dart';
import '../../features/employee/queue/employee_queue_screen.dart';
import '../../features/offline/offline_queue_screen.dart';
import '../../features/hr/dashboard/hr_dashboard_screen.dart';
import '../../features/hr/employees/hr_employee_list_screen.dart';
import '../../features/hr/onboarding/hr_onboarding_screen.dart';
import '../../features/hr/employees/hr_employee_detail_screen.dart';
import '../../features/hr/flagged/hr_flagged_screen.dart';
import '../../features/hr/company/hr_company_screen.dart';
import '../../features/hr/company/providers/hr_company_providers.dart';
import '../../core/constants/app_constants.dart';

class AppRoutes {
  static const splash            = '/';
  static const login             = '/login';
  static const setPassword       = '/set-password';
  static const employeeDashboard = '/employee/dashboard';
  static const hrDashboard       = '/hr/dashboard';
  static const hrEmployees       = '/hr/employees';
  static const hrFlagged         = '/hr/flagged';
  static const hrOnboarding      = '/hr/onboarding';
  static const hrCompany         = '/hr/company';
  static const hrEmployeeDetail  = '/hr/employees/detail/:employeeId';
  static const checkin           = '/employee/checkin';
  static const offlineQueue      = '/employee/offline-queue';
  static const history           = '/employee/history';
  static const queue             = '/employee/queue';
  static const profile           = '/employee/profile';
}

GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    // Rebuild routes whenever auth state changes
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isInitial  = authState.status == AuthStatus.initial;
      final onPublic   = state.matchedLocation == AppRoutes.login ||
                         state.matchedLocation == AppRoutes.splash;

      // Still initialising — let splash handle it
      if (isInitial) return null;

      // Not logged in and not already on a public route → go to login
      if (!isLoggedIn && !onPublic) return AppRoutes.login;

      // Logged in and trying to visit login → route by role
      if (isLoggedIn && state.matchedLocation == AppRoutes.login) {
        final role = ref.read(authProvider).user?.role ?? '';
        return role == AppConstants.roleHrAdmin
            ? AppRoutes.hrDashboard
            : AppRoutes.employeeDashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: AppRoutes.employeeDashboard,
        name: 'employee-dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EmployeeDashboardScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: AppRoutes.hrDashboard,
        name: 'hr-dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HrDashboardScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: AppRoutes.offlineQueue,
        name: 'offline-queue',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OfflineQueueScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.setPassword,
        name: 'set-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: Text('Set Password — Coming Soon')),
          ),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EmployeeHistoryScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.queue,
        name: 'queue',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EmployeeQueueScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EmployeeProfileScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.hrEmployees,
        name: 'hr-employees',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HrEmployeeListScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.hrEmployeeDetail,
        name: 'hr-employee-detail',
        pageBuilder: (context, state) {
          final employeeId = int.parse(state.pathParameters['employeeId']!);
          return CustomTransitionPage(
            key: state.pageKey,
            child: HrEmployeeDetailScreen(employeeId: employeeId),
            transitionsBuilder: (context, animation, secondary, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.hrFlagged,
        name: 'hr-flagged',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HrFlaggedScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.hrOnboarding,
        name: 'hr-onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HrOnboardingScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.hrCompany,
        name: 'hr-company',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HrCompanyScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.checkin,
        name: 'checkin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CheckInScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
    ],
  );
}

/// Makes GoRouter react to authProvider state changes only.
/// Deliberately ignores all other providers (settings, etc.) so that
/// theme/locale toggles do not trigger a router refresh and re-run
/// the redirect logic (which would send the user back to splash).
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
}
