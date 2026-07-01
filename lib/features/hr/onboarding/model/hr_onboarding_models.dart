import '../../employees/model/hr_employee_models.dart';

/// Top-of-screen stat cards. [totalOnboarded] and [pendingInvitations]
/// are derived from the real employee list. [avgValidationTime] has no
/// backing data source yet — shown as a static placeholder until a real
/// metric/endpoint exists.
class OnboardingStats {
  final int totalOnboarded;
  final int totalEmployees;
  final int pendingInvitations;
  final String avgValidationTimeLabel;

  const OnboardingStats({
    required this.totalOnboarded,
    required this.totalEmployees,
    required this.pendingInvitations,
    this.avgValidationTimeLabel = '—',
  });

  double get onboardedPercent =>
      totalEmployees == 0 ? 0 : (totalOnboarded / totalEmployees) * 100;

  factory OnboardingStats.fromEmployees(List<HrEmployee> employees) {
    final onboarded = employees.where((e) => e.isOnboarded).length;
    final pending = employees.length - onboarded;
    return OnboardingStats(
      totalOnboarded: onboarded,
      totalEmployees: employees.length,
      pendingInvitations: pending,
    );
  }
}

/// All not-yet-onboarded employees currently show this same status —
/// there's no real per-employee email-send tracking yet. Kept as an enum
/// so the row widget's visual branching (color/label/action) is ready
/// for real statuses once the backend supports them.
enum OnboardingEmailStatus { notSent, invitedExpired, deliveryFailed }

class OnboardingEntry {
  final HrEmployee employee;
  final OnboardingEmailStatus emailStatus;
  final DateTime? lastAttempt;

  const OnboardingEntry({
    required this.employee,
    required this.emailStatus,
    this.lastAttempt,
  });
}
