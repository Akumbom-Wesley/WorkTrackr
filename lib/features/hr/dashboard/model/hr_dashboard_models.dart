class HrDashboardStats {
  final int presentToday;
  final int absentToday;
  final int flaggedPending;
  final int notOnboarded;
  final int totalActiveEmployees;
  final bool isFromCache;

  const HrDashboardStats({
    required this.presentToday,
    required this.absentToday,
    required this.flaggedPending,
    required this.notOnboarded,
    required this.totalActiveEmployees,
    this.isFromCache = false,
  });

  factory HrDashboardStats.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) {
    return HrDashboardStats(
      presentToday:          json['present_today']          as int,
      absentToday:           json['absent_today']           as int,
      flaggedPending:        json['flagged_pending']        as int,
      notOnboarded:          json['not_onboarded']          as int,
      totalActiveEmployees:  json['total_active_employees'] as int,
      isFromCache: isFromCache,
    );
  }
}
