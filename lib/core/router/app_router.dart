import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/employee/dashboard/employee_dashboard_screen.dart';
import '../../features/employee/checkin/checkin_screen.dart';
import '../../features/offline/offline_queue_screen.dart';

class AppRoutes {
  static const splash            = '/';
  static const login             = '/login';
  static const setPassword       = '/set-password';
  static const employeeDashboard = '/employee/dashboard';
  static const hrDashboard       = '/hr/dashboard';
  static const checkin           = '/employee/checkin';
  static const offlineQueue      = '/employee/offline-queue';
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

      // Logged in and trying to visit login → go to dashboard
      if (isLoggedIn && state.matchedLocation == AppRoutes.login) {
        return AppRoutes.employeeDashboard;
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
          child: const Scaffold(
            body: Center(child: Text('HR Dashboard — Coming Soon')),
          ),
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

/// Makes GoRouter react to authProvider state changes.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(WidgetRef ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
